# 07.1-Runtime消息机制

> 我们都知道OC中的方法调用，最终底层都是调用runtime的`objc_msgSend()`API来发送消息，也就是OC的`消息机制`。`消息机制`的执行流程又分下面的三个阶段，当执行第一个阶段时方法不能调用成功变会进入第二个阶段，如果第二个阶段还无法处理消息，则进入第三个阶段消息转发，如果第三个阶段还不能处理消息，则程序就会抛出异常。

* 第一阶段：消息发送
* 第二阶段：动态方法解析
* 第三阶段：消息转发

### 消息发送阶段

我们创建一个新工程，新建一个`Person`类，代码如下：

`Person`类

```
@interface Person : NSObject

- (void)test;
@end


@implementation Person

- (void)test {
    NSLog(@"%s", __func__);
}
@end
```

`main`函数

```
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        
        Person *person = [[Person alloc] init];
        [person test];
    }
    return 0;
}
```

然后我们执行命令`xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc -fobjc-arc -fobjc-runtime=ios-8.0.0 main.m`将`main.m`文件转换为c++代码如下：

```
int main(int argc, const char * argv[]) {
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 

        Person *person = ((Person *(*)(id, SEL))(void *)objc_msgSend)((id)((Person *(*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("Person"), sel_registerName("alloc")), sel_registerName("init"));
        ((void (*)(id, SEL))(void *)objc_msgSend)((id)person, sel_registerName("test"));

    }
    return 0;
}
```

我们通过转换的c++代码可以看到，当我们进行方法调用时，底层代码就转化为runtime的`objc_msgSend`函数，`objc_msgSend()`函数接受两个参数，具体解释如下：

```
	Person *person = [[Person alloc] init];
	
	// 当执行OC代码`[person test]`转换为底层c++代码就是`objc_msgSend(person, sel_registerName("test"))`
	[person test];
	    
	/**
	 person：消息接收者(receiver)，也就是objc_msgSend()函数给消息接收者(receiver)发送一条消息(消息名称为sel_registerName("test"))
	 sel_registerName("test")：消息名称(方法名)
	 */
	objc_msgSend(person, sel_registerName("test"));
	
	需要注意：OC的`@selector(test)`转换为底层代码就是`sel_registerName("test")`
```

消息发送阶段查找方法流程如图：

![](https://imgs-1257778377.cos.ap-shanghai.myqcloud.com/QQ20200208-100832@2x.png)

### 动态方法解析阶段(也就是通过runtime动态添加一个方法)

我们创建一个`Person2`类来演示第二阶段，具体代码如下：

`Person2`类

```
@interface Person2 : NSObject

- (void)instanceTest;

+ (void)classTest;
@end


@implementation Person2

void Ctest(id self, SEL _cmd) {
    NSLog(@"C语言函数");
}

- (void)test2 {
    NSLog(@"%s", __func__);
}

+ (void)test3 {
    NSLog(@"%s", __func__);
}

// 解析类方法
+ (BOOL)resolveClassMethod:(SEL)sel {
    if (sel == @selector(classTest)) {
        // 这个test3方法要在元类对象中查找，所以使用object_getClass(self)
        Method method = class_getInstanceMethod(object_getClass(self), @selector(test3));
        
        // 动态添加一个类方法，因为类方法需要在元类对象中查找，所以使用object_getClass(self)
        class_addMethod(object_getClass(self), sel, method_getImplementation(method), method_getTypeEncoding(method));
        
//        class_addMethod(object_getClass(self), sel, (IMP)Ctest, "v16@0:8");
        
        // 如果实现了方法解析，则返回YES
        return YES;
    }
    return [super resolveClassMethod:sel];
}

// 解析实例方法
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    // 这里做下判断，只处理方法instanceTest
    if (sel == @selector(instanceTest)) {
        // 创建一个Method对象，Method对象的底层结构就是method_t
        Method method = class_getInstanceMethod(self, @selector(test2));

        // 动态添加一个实例方法
        class_addMethod(self, sel, method_getImplementation(method), method_getTypeEncoding(method));
        
        // 我们也可以动态添加C言语函数
//        class_addMethod(self, sel, (IMP)Ctest, "v16@0:8");
        
        // 如果实现了方法解析，则返回YES
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}
@end
```

`main`函数

```
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Person2 *person = [[Person2 alloc] init];
        [person instanceTest];
        
        [Person2 classTest];
    }
    return 0;
}
```

第二阶段动态方法解析阶段的核心函数

* resolveInstanceMethod，用来处理实例方法
* resolveClassMethod，用来处理类方法

动态解析方法阶段流程如图：

![](https://imgs-1257778377.cos.ap-shanghai.myqcloud.com/QQ20200208-100855@2x.png)

### 消息转发阶段

我们创建一个`Person3`类来演示第三阶段，具体代码如下：

`Person3`类

```
@interface Person3 : NSObject

- (void)instanceTest;

+ (void)classTest;
@end


@implementation Person3

#pragma mark - 处理类方法消息转发

// 处理类方法消息转发
//+ (id)forwardingTargetForSelector:(SEL)aSelector {
//    if (aSelector == @selector(classTest)) {
//        // 返回一个对象，将消息转发给这个对象来处理，最终底层执行了objc_msgSend([[Student alloc] init], aSelector)
//        return [Student class];
//    }
//
//    return [super forwardingTargetForSelector:aSelector];
//}

// 方法签名
//+ (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
//    if (aSelector == @selector(classTest)) {
//        return [NSMethodSignature signatureWithObjCTypes:"v16@0:8"];
//    }
//    return [super methodSignatureForSelector:aSelector];
//}

// 最后一次机会处理消息，这里可以灵活处理消息
//+ (void)forwardInvocation:(NSInvocation *)anInvocation {
//    NSLog(@"灵活处理消息转发-begin");
//
//    [anInvocation invokeWithTarget:[Student class]];
//
//    NSLog(@"灵活处理消息转发-end");
//}


#pragma mark - 处理实例方法消息转发

//- (id)forwardingTargetForSelector:(SEL)aSelector {
//    if (aSelector == @selector(instanceTest)) {
//        // 返回一个对象，将消息转发给这个对象来处理，最终底层执行了objc_msgSend([[Student alloc] init], aSelector)
//        return [[Student alloc] init];
//    }
//
//    return [super forwardingTargetForSelector:aSelector];
//}

// 方法签名
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if (aSelector == @selector(instanceTest)) {
        return [NSMethodSignature signatureWithObjCTypes:"v16@0:8"];
    }
    return [super methodSignatureForSelector:aSelector];
}

// 最后一次机会处理消息，这里可以灵活处理消息，比在forwardingTargetForSelector:函数中处理消息转发更加的灵活多变
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"灵活处理消息转发-begin");

    [anInvocation invokeWithTarget:[[Student alloc] init]];

    NSLog(@"灵活处理消息转发-end");
}
@end
```

`main`函数

```
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Person3 *person = [[Person3 alloc] init];
        [person instanceTest];
        
//        [Person3 classTest];
    }
    return 0;
}
```

消息转发阶段有三个核心函数，注意：**这三个函数都有与之对应的类方法实现**

* forwardingTargetForSelector:
* methodSignatureForSelector:
* forwardInvocation:

这里需要注意：**当`forwardingTargetForSelector:`函数没有返回处理消息的对象时，程序就会执行`methodSignatureForSelector:`函数，当`methodSignatureForSelector:`返回了正确方法签名后才会执行最后的处理函数`forwardInvocation:`**

消息转发阶段流程如图：

![](https://imgs-1257778377.cos.ap-shanghai.myqcloud.com/QQ20200208-101035@2x.png)

消息机制底层源码查找路径：`objc4源码 -> objc-runtime-new.mm -> lookUpImpOrForward()`

`lookUpImpOrForward`核心源码函数入口，在此函数源码中详细包含了消息机制的三大阶段

```
IMP lookUpImpOrForward(Class cls, SEL sel, id inst, 
                       bool initialize, bool cache, bool resolver)
{
    IMP imp = nil;
    bool triedResolver = NO;

    
    /*----------runtime消息机制的第一阶段：消息发送阶段-----------*/
    
    
    runtimeLock.assertUnlocked();
    
    /************************* 查找方法流程 **************************/

    // Optimistic cache lookup
    if (cache) {
        // 如果缓存中有方法，则从方法缓存中查找
        imp = cache_getImp(cls, sel);
        if (imp) return imp;
    }

    // runtimeLock is held during isRealized and isInitialized checking
    // to prevent races against concurrent realization.

    // runtimeLock is held during method search to make
    // method-lookup + cache-fill atomic with respect to method addition.
    // Otherwise, a category could be added but ignored indefinitely because
    // the cache was re-filled with the old value after the cache flush on
    // behalf of the category.

    runtimeLock.read();

    if (!cls->isRealized()) {
        // Drop the read-lock and acquire the write-lock.
        // realizeClass() checks isRealized() again to prevent
        // a race while the lock is down.
        runtimeLock.unlockRead();
        runtimeLock.write();

        realizeClass(cls);

        runtimeLock.unlockWrite();
        runtimeLock.read();
    }

    // 在objc_msgSend发送消息前，先判断下这个类有没有被初始化
    if (initialize  &&  !cls->isInitialized()) {
        runtimeLock.unlockRead();
        
        // 没有初始化，就来初始化这个类
        _class_initialize (_class_getNonMetaClass(cls, inst));
        runtimeLock.read();
        // If sel == initialize, _class_initialize will send +initialize and 
        // then the messenger will send +initialize again after this 
        // procedure finishes. Of course, if this is not being called 
        // from the messenger then it won't happen. 2778172
    }

    
 retry:    
    runtimeLock.assertReading();

    // Try this class's cache.
    
    // 如果缓存中找到方法的实现，则返回到汇编
    imp = cache_getImp(cls, sel);
    if (imp) goto done;

    // 如果方法缓存列表中没有找到方法，则在当前类对象的方法列表中进行查找
    // Try this class's method lists.
    {
        Method meth = getMethodNoSuper_nolock(cls, sel);
        
        // 找到了方法
        if (meth) {
            
            // 将找到的方法添加到方法缓存列表中
            log_and_fill_cache(cls, meth->imp, sel, inst, cls);
            imp = meth->imp;
            goto done;
        }
    }

    
    // 如果当前类对象的方法列表中也没有找到，则去父类中查找
    // Try superclass caches and method lists.
    {
        unsigned attempts = unreasonableClassCount();
        
        // 通过cls->superclass找到父类对象，循环遍历查找是否还有上级父类
        for (Class curClass = cls->superclass;
             curClass != nil;
             curClass = curClass->superclass)
        {
            // Halt if there is a cycle in the superclass chain.
            if (--attempts == 0) {
                _objc_fatal("Memory corruption in class list.");
            }
            
            // 查找父类的方法列表前，也是先查找缓存列表
            // Superclass cache.
            imp = cache_getImp(curClass, sel);
            if (imp) {
                if (imp != (IMP)_objc_msgForward_impcache) {
                    
                    // 在父类缓存中找到了，将其缓存到当前类对象中
                    // Found the method in a superclass. Cache it in this class.
                    log_and_fill_cache(cls, imp, sel, inst, curClass);
                    goto done;
                }
                else {
                    // Found a forward:: entry in a superclass.
                    // Stop searching, but don't cache yet; call method 
                    // resolver for this class first.
                    break;
                }
            }
            
            // 缓存列表中没有找到，则在父类的方法列表中查找
            // Superclass method list.
            Method meth = getMethodNoSuper_nolock(curClass, sel);
            if (meth) {
                
                // 找到则将方法添加到缓存列表
                log_and_fill_cache(cls, meth->imp, sel, inst, curClass);
                imp = meth->imp;
                goto done;
            }
        }
    }

    
    /*----------这里需要注意，当消息发送阶段没有找到对应方法，则进入第二阶段：消息解析-----------*/
    
    
    // No implementation found. Try method resolver once.

    // 之前没有尝试解析过，就进入解析阶段
    if (resolver  &&  !triedResolver) {
        runtimeLock.unlockRead();
        
        // 处理消息解析
        _class_resolveMethod(cls, sel, inst);
        runtimeLock.read();
        // Don't cache the result; we don't hold the lock so it may have 
        // changed already. Re-do the search from scratch instead.
        triedResolver = YES;
        goto retry;
    }

    /*----------当消息解析阶段仍不能处理方法，则进入第三阶段：消息转发---------------*/
    
    // No implementation found, and method resolver didn't help. 
    // Use forwarding.

	 // 消息转发
    imp = (IMP)_objc_msgForward_impcache;
    
    // 消息转发完成后，将方法添加到缓存列表
    cache_fill(cls, sel, imp, inst);

 done:
    runtimeLock.unlockRead();

    return imp;
}
```


讲解示例Demo地址：[https://github.com/guangqiang-liu/07.1-RunTimeMessageSend]()


## 更多文章
* ReactNative开源项目OneM(1200+star)：**[https://github.com/guangqiang-liu/OneM](https://github.com/guangqiang-liu/OneM)**：欢迎小伙伴们 **star**
* iOS组件化开发实战项目(500+star)：**[https://github.com/guangqiang-liu/iOS-Component-Pro]()**：欢迎小伙伴们 **star**
* 简书主页：包含多篇iOS和RN开发相关的技术文章[http://www.jianshu.com/u/023338566ca5](http://www.jianshu.com/u/023338566ca5) 欢迎小伙伴们：**多多关注，点赞**
* ReactNative QQ技术交流群(2000人)：**620792950** 欢迎小伙伴进群交流学习
* iOS QQ技术交流群：**678441305** 欢迎小伙伴进群交流学习