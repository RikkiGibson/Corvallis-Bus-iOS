//
//  UIAlertViewWorkaround.m
//  CorvallisBus
//
//  Created by Rikki Gibson on 12/3/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIAlertControllerWorkaround : NSObject 

+ (BOOL)deviceDoesSupportUIAlertController;

@end

@implementation UIAlertControllerWorkaround

+ (BOOL)deviceDoesSupportUIAlertController {
    return NSClassFromString(@"UIAlertController") != nil;
}

@end