//
//  main.m
//  07.1-runtime objc_msgSend()
//
//  Created by 刘光强 on 2020/2/7.
//  Copyright © 2020 guangqiang.liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Person.h"
#import <objc/runtime.h>
#import "Person2.h"
#import "Person3.h"
#import "DynamicTest.h"

void test1() {
    // insert code here...
    Person *person = [[Person alloc] init];
    [person test];
    
    /**
     person：消息接收者(receiver)，也就是objc_msgSend()函数给消息接收者(receiver)发送一条消息(消息名称为sel_registerName("test"))
     sel_registerName("test")：方法名称
     sel_registerName("test")等价于@selector(test)
     */
//    objc_msgSend(person, sel_registerName("test"));
    
    NSLog(@"%p -- %p", sel_registerName("test"), @selector(test));
}

void test2() {
    Person2 *person = [[Person2 alloc] init];
    [person instanceTest];
    
    [Person2 classTest];
}

void test3() {
    Person3 *person = [[Person3 alloc] init];
            [person instanceTest];
            
    //        [Person3 classTest];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        DynamicTest *test = [[DynamicTest alloc] init];
        test.age = 100;
        NSLog(@"===%d", test.age);
    }
    return 0;
}
