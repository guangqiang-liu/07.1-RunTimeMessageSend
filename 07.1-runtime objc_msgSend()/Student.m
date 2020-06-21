//
//  Student.m
//  07.1-runtime objc_msgSend()
//
//  Created by 刘光强 on 2020/2/7.
//  Copyright © 2020 guangqiang.liu. All rights reserved.
//

#import "Student.h"

@implementation Student

- (void)instanceTest {
    NSLog(@"%s", __func__);
}

+ (void)classTest {
    NSLog(@"%s", __func__);
}
@end
