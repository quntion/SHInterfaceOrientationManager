//
//  UIDevice+InterfaceOrientation.m
//  OraKit
//
//  Created by shaoruibo on 2022/7/29.
//

#import "UIDevice+SHInterfaceOrientationManager.h"
#import "UIViewController+SHInterfaceOrientationManager.h"

@implementation UIDevice (SHInterfaceOrientationManager)

/// 强制App界面旋转
/// @param orientation 目标方向（如果给定 UIInterfaceOrientationUnknown，则会按照 UIInterfaceOrientationPortrait 替换）
+ (void)ora_forceOrientation:(UIInterfaceOrientation)orientation {
    UIInterfaceOrientationMask ios16Oraientation = UIInterfaceOrientationMaskPortrait;
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            orientation = UIInterfaceOrientationPortrait;
            ios16Oraientation = UIInterfaceOrientationMaskPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            orientation = UIInterfaceOrientationPortraitUpsideDown;
            ios16Oraientation = UIInterfaceOrientationMaskPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            orientation = UIInterfaceOrientationLandscapeLeft;
            ios16Oraientation = UIInterfaceOrientationMaskLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            orientation = UIInterfaceOrientationLandscapeRight;
            ios16Oraientation = UIInterfaceOrientationMaskLandscapeRight;
            break;
        default:
            orientation = UIInterfaceOrientationPortrait;
            ios16Oraientation = UIInterfaceOrientationMaskPortrait;
            break;
    }
    
#ifndef Release
    NSLog(@"UIDevice 强制旋转到的方向 ori=[%@]", sh_getStringWithOri(orientation));
#endif
    
    // FIXME: 适配 iOS16 屏幕旋转 Api
//    if (@available(iOS 16.0, *)) {
//        UIWindow *currenWindow = UIApplication.sharedApplication.delegate.window;
//        UIWindowScene *currentWindowScene = currenWindow.windowScene;
//        if (currenWindow && currentWindowScene) {
//            [currenWindow.rootViewController setNeedsUpdateOfSupportedInterfaceOrientations];
//            UIWindowSceneGeometryPreferencesIOS *geometryPreferences = [[UIWindowSceneGeometryPreferencesIOS alloc] init];
//            geometryPreferences.interfaceOrientations = ios16Oraientation;
//            [currentWindowScene requestGeometryUpdateWithPreferences:geometryPreferences errorHandler:^(NSError * _Nonnull error) {
//#ifndef Release
//                NSLog(@"iOS16.0+ 请求屏幕旋转，error=[%@]", error);
//#endif
//            }];
//        }
//        return;
//    }
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        NSInteger val = (NSInteger)orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
    [UIViewController attemptRotationToDeviceOrientation];
}

@end
