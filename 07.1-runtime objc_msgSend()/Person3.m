//
//  Person3.m
//  07.1-runtime objc_msgSend()
//
//  Created by 刘光强 on 2020/2/7.
//  Copyright © 2020 guangqiang.liu. All rights reserved.
//

#import "Person3.h"
#import "Student.h"

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

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (aSelector == @selector(instanceTest)) {
        // 返回一个对象，将消息转发给这个对象来处理，最终底层执行了objc_msgSend([[Student alloc] init], aSelector)
        return [[Student alloc] init];
    }

    return [super forwardingTargetForSelector:aSelector];
}

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
