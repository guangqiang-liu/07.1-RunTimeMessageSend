//
//  DynamicTest.m
//  07.1-runtime objc_msgSend()
//
//  Created by 刘光强 on 2020/2/8.
//  Copyright © 2020 guangqiang.liu. All rights reserved.
//

#import "DynamicTest.h"
#import <objc/runtime.h>

@implementation DynamicTest

/**
 @synthesize作用：
 为age属性自动生成一个叫_age的成员变量，并且自动生成对应的setter和getter方法的实现来对成员变量的值进行存和取
 */
//@synthesize age = _age;


/**
 @dynamic作用：
 不自动生成_age的成员变量，也不自动生成对应的setter和getter方法的实现来值的存和取，值的存和取需要自己实现。
 实现值的存和取，我们可以使用运行时动态添加方法来解决
 */
@dynamic age;

void setAge(id self, SEL _cmd, int age) {
    NSLog(@"age == %d", age);
}

void age(id self , SEL _cmd) {
    NSLog(@"取出age的值");
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    if (sel == @selector(setAge:)) {
        class_addMethod(self, sel, (IMP)setAge, "v@:i");
        return YES;
    } else if (sel == @selector(age)) {
        class_addMethod(self, sel, (IMP)age, "i@:");
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}

//- (void)setAge:(int)age {
//    NSLog(@"111");
//}
//
//- (int)age {
//    return 200;
//}
@end
