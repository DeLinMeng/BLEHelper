//
//  Tools.h
//  3Pomelos
//
//  Created by 孟德林 on 2016/11/4.
//  Copyright © 2016年 ichezheng.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Tools : NSObject

enum {
    // iPhone 1,3,3GS 标准分辨率(320x480px)
    UIDevice_iPhone3G      = 1,
    // iPhone 4,4S 高清分辨率(640x960px)
    UIDevice_iPhone4s            = 2,
    // iPhone 5 高清分辨率(640x1136px)
    UIDevice_iPhone5      = 3,
    // iPad 1,2 标准分辨率(1024x768px)
    UIDevice_iPad2        = 4,
    // iPad 3 High Resolution(2048x1536px)
    UIDevice_iPad3              = 5
};
typedef NSUInteger UIDeviceResolution;


+ (UIDeviceResolution) currentResolution;
+ (UIColor *) colorWithHexString: (NSString *)color;
+(NSString *)stringToHex:(NSString *)string;
+(NSString *)asccistringFromString:(NSString *)string;
+(NSString *)stringFromHexString:(NSString *)hexString;
+(NSString *)stringAppendSpace:(NSString *)tmpStr;
+(NSString *)stringAppendZero:(NSString *)string;
+(NSString *)stringRemoveLast:(NSString *)string;
@end
