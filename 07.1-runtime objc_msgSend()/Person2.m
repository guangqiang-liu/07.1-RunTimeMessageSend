//
//  Person2.m
//  07.1-runtime objc_msgSend()
//
//  Created by 刘光强 on 2020/2/7.
//  Copyright © 2020 guangqiang.liu. All rights reserved.
//

#import "Person2.h"
#import <objc/runtime.h>

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
