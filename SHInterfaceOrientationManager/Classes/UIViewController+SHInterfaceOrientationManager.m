//
//  UIViewController+InterfaceOrientation.m
//  OraKit
//
//  Created by shaoruibo on 2022/7/27.
//

#import "UIViewController+SHInterfaceOrientationManager.h"
#import <objc/runtime.h>
#import "UIDevice+SHInterfaceOrientationManager.h"

// 自锁方向通知 - 修正转场占位方向值
NSString *kInterfaceOrientationNotificationKey = @"kInterfaceOrientationNotificationKey";
NSString *kInterfaceOrientationNotificationNavigationControllerKey = @"kInterfaceOrientationNotificationNavigationControllerKey";
NSString *kInterfaceOrientationNotificationSenderViewControllerKey = @"kInterfaceOrientationNotificationSenderViewControllerKey";
NSString *kInterfaceOrientationNotificationSenderViewControllerInterfaceOrientationKey = @"kInterfaceOrientationNotificationSenderViewControllerInterfaceOrientationKey";

// 自锁方向通知 - 撤销 UIInterfaceOrientationUnknown 转场占位方向（在dismiss时需要发送该通知，再执行方向旋转操作，否则没有经过 _ora_viewDidAppear: 方法会导致该占位转场方向值影响最终要设置到的真实方向值⚠️）
NSString *kInterfaceOrientationNotificationResolveInterfaceOrientationUnknownKey = @"kInterfaceOrientationNotificationResolveInterfaceOrientationUnknownKey";

static inline void sh_swizzleSelector(Class theClass, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(theClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(theClass, swizzledSelector);
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

/// 校验 UIViewController是否正常显示
/// @param vc 传入控制器对象
//static BOOL IsNormalDisplay(UIViewController *vc) {
//    if (vc.isViewLoaded && !vc.view.hidden && vc.view.alpha > 0.01) {
//        return YES;
//    } else {
//        return NO;
//    }
//}

static UIInterfaceOrientationMask sh_getOriMaskWithOri(UIInterfaceOrientation ori) {
    switch (ori) {
        case UIInterfaceOrientationUnknown:
            return UIInterfaceOrientationMaskAll;
        case UIInterfaceOrientationPortrait:
            return UIInterfaceOrientationMaskPortrait;
        case UIInterfaceOrientationPortraitUpsideDown:
            return UIInterfaceOrientationMaskPortraitUpsideDown;
        case UIInterfaceOrientationLandscapeLeft:
            return UIInterfaceOrientationMaskLandscapeLeft;
        case UIInterfaceOrientationLandscapeRight:
            return UIInterfaceOrientationMaskLandscapeRight;
        default:
            return UIInterfaceOrientationMaskAll;
    }
}

NSString* sh_getStringWithOri(UIInterfaceOrientation ori) {
    switch (ori) {
        case UIInterfaceOrientationUnknown:
            return @"方向：Unknown";
        case UIInterfaceOrientationPortrait:
            return @"方向：Portrait";
        case UIInterfaceOrientationPortraitUpsideDown:
            return @"方向：PortraitUpsideDown";
        case UIInterfaceOrientationLandscapeLeft:
            return @"方向：LandscapeLeft";
        case UIInterfaceOrientationLandscapeRight:
            return @"方向：LandscapeRight";
        default:
            return @"方向：Unknown";
    }
}

static NSString* sh_getStringWithOriMask(UIInterfaceOrientationMask oriMask) {
    switch (oriMask) {
        case UIInterfaceOrientationMaskAll:
            return @"方向 Mask：All";
        case UIInterfaceOrientationMaskAllButUpsideDown:
            return @"方向 Mask：AllButUpsideDown";
        case UIInterfaceOrientationMaskPortrait:
            return @"方向 Mask：Portrait";
        case UIInterfaceOrientationMaskPortraitUpsideDown:
            return @"方向 Mask：PortraitUpsideDown";
        case UIInterfaceOrientationMaskLandscapeLeft:
            return @"方向 Mask：LandscapeLeft";
        case UIInterfaceOrientationMaskLandscapeRight:
            return @"方向 Mask：LandscapeRight";
        case UIInterfaceOrientationMaskLandscape:
            return @"方向 Mask：Landscape";
        default:
            return @"方向 Mask：Unknown";
    }
}

@interface _SHDeallocModel : NSObject
@property (nonatomic, assign) UIViewController *vc;
@end
@implementation _SHDeallocModel
- (void)dealloc {
    if (_vc) {
        [UIViewController.sh_interfaceOrientationNotificationCenter removeObserver:_vc];
    }
}
@end

@interface UIViewController (SHInterfaceOrientationManager)

@property (nonatomic, strong, nullable) _SHDeallocModel *sh_deallocModel;

/// YES： 视图处于出现转场过程中，NO：视图未处于出现转场过程中
@property (nonatomic, assign) BOOL internal_viewWillAppearing;

/// 控制器被push动画转场时给定的临时方向值（默认为 UIInterfaceOrientationUnknown）
/// ⚠️在被导航控制器push时会被自动指定，外部无需关心
@property (nonatomic, assign) UIInterfaceOrientation internal_preferredInterfaceOrientation;

@end

@implementation UIViewController (SHInterfaceOrientationManager)

// MARK: - Class Method

+ (void)load {
    sh_swizzleSelector(self, @selector(init), @selector(_sh_init));
    
    sh_swizzleSelector(self, @selector(viewWillAppear:), @selector(_sh_viewWillAppear:));
    sh_swizzleSelector(self, @selector(viewDidAppear:), @selector(_sh_viewDidAppear:));
    
    sh_swizzleSelector(self, @selector(dismissViewControllerAnimated:completion:), @selector(_sh_dismissViewControllerAnimated:completion:));
    
    sh_swizzleSelector(self, @selector(shouldAutorotate), @selector(_sh_shouldAutorotate));
    sh_swizzleSelector(self, @selector(supportedInterfaceOrientations), @selector(_sh_supportedInterfaceOrientations));
    sh_swizzleSelector(self, @selector(preferredInterfaceOrientationForPresentation), @selector(_sh_preferredInterfaceOrientationForPresentation));
}

+ (NSNotificationCenter *)sh_interfaceOrientationNotificationCenter {
    static NSNotificationCenter *_interfaceOrientationNotificationCenter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _interfaceOrientationNotificationCenter = [[NSNotificationCenter alloc] init];
    });
    return _interfaceOrientationNotificationCenter;
}

static NSString *interfaceOrientationRuntimeKey = @"interfaceOrientationRuntimeKey";
+ (BOOL)sh_interfaceOrientationRuntimeEnable {
    NSNumber *number = objc_getAssociatedObject(interfaceOrientationRuntimeKey, _cmd);
    if (number) {
        return number.boolValue;
    }
    UIViewController.sh_interfaceOrientationRuntimeEnable = YES;
    return YES;
}

+ (void)setSh_interfaceOrientationRuntimeEnable:(BOOL)enabled {
    SEL key = @selector(sh_interfaceOrientationRuntimeEnable);
    objc_setAssociatedObject(interfaceOrientationRuntimeKey, key, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (UIViewController *)currentViewControllerWithRootVc:(UIViewController *)vc {
    if ([vc isBeingDismissed] || [vc isMovingFromParentViewController]) {
        vc = vc.parentViewController;
        return [UIViewController currentViewControllerWithRootVc:vc];
    }
    if (vc.presentedViewController) {
        vc = vc.parentViewController;
        if (![vc isBeingDismissed] && ![vc isMovingFromParentViewController]) {
            return [UIViewController currentViewControllerWithRootVc:vc.presentedViewController];
        }
    } else if ([vc isKindOfClass:[UINavigationController class]]) {
        vc = [(UINavigationController *)vc visibleViewController];
        if (![vc isBeingDismissed] && ![vc isMovingFromParentViewController]) {
            return [UIViewController currentViewControllerWithRootVc:vc];
        }
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        vc = [(UITabBarController *)vc selectedViewController];
        if (![vc isBeingDismissed] && ![vc isMovingFromParentViewController]) {
            return [UIViewController currentViewControllerWithRootVc:vc];
        }
    }
    return vc;
}

// MARK: - 总控制

- (BOOL)sh_interfaceOrientationEnable {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        return number.boolValue;
    }
    self.sh_interfaceOrientationEnable = YES;
    return YES;
}

- (void)setSh_interfaceOrientationEnable:(BOOL)enabled {
    SEL key = @selector(sh_interfaceOrientationEnable);
    objc_setAssociatedObject(self, key, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)sh_presentedViewControllerCheckEnable {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        return number.boolValue;
    }
    self.sh_presentedViewControllerCheckEnable = YES;
    return YES;
}

- (void)setSh_presentedViewControllerCheckEnable:(BOOL)enabled {
    SEL key = @selector(sh_presentedViewControllerCheckEnable);
    objc_setAssociatedObject(self, key, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)sh_shouldBeCheckedEnable {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        return number.boolValue;
    }
    self.sh_shouldBeCheckedEnable = YES;
    return YES;
}

- (void)setSh_shouldBeCheckedEnable:(BOOL)enabled {
    SEL key = @selector(sh_shouldBeCheckedEnable);
    objc_setAssociatedObject(self, key, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)sh_shouldAutoSettingInterfaceOrientationWhenViewDidAppear {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        return number.boolValue;
    }
    self.sh_shouldAutoSettingInterfaceOrientationWhenViewDidAppear = YES;
    return YES;
}

- (void)setSh_shouldAutoSettingInterfaceOrientationWhenViewDidAppear:(BOOL)enabled {
    SEL key = @selector(sh_shouldAutoSettingInterfaceOrientationWhenViewDidAppear);
    objc_setAssociatedObject(self, key, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//- (BOOL)ora_shouldAutoSettingInterfaceOrientationWhenPreferredInterfaceOrientationUpdate {
//    NSNumber *number = objc_getAssociatedObject(self, _cmd);
//    if (number) {
//        return number.boolValue;
//    }
//    self.ora_shouldAutoSettingInterfaceOrientationWhenPreferredInterfaceOrientationUpdate = YES;
//    return YES;
//}
//
//- (void)setOra_shouldAutoSettingInterfaceOrientationWhenPreferredInterfaceOrientationUpdate:(BOOL)enabled {
//    SEL key = @selector(ora_shouldAutoSettingInterfaceOrientationWhenPreferredInterfaceOrientationUpdate);
//    objc_setAssociatedObject(self, key, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//}

// MARK: - Var

- (_SHDeallocModel *)sh_deallocModel {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setSh_deallocModel:(_SHDeallocModel *)model {
    SEL key = @selector(sh_deallocModel);
    objc_setAssociatedObject(self, key, model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// MARK: - Life cycle

- (instancetype)_sh_init {
    UIViewController *vc = [self _sh_init];
    [UIViewController.sh_interfaceOrientationNotificationCenter addObserver:vc selector:@selector(_sh_interfaceOrientationNotification:) name:kInterfaceOrientationNotificationKey object:nil];
    [UIViewController.sh_interfaceOrientationNotificationCenter addObserver:vc selector:@selector(_sh_resolveInterfaceOrientationUnknownNotification:) name:kInterfaceOrientationNotificationResolveInterfaceOrientationUnknownKey object:nil];
    _SHDeallocModel *m = [[_SHDeallocModel alloc] init];
    m.vc = vc;
    vc.sh_deallocModel = m;
    return vc;
}

- (void)_sh_viewWillAppear:(BOOL)animated {
    // 当`总开关设置`或`使能控制`不生效时，执行原始方法调用
    if (!UIViewController.sh_interfaceOrientationRuntimeEnable
        || !self.sh_interfaceOrientationEnable
        || !self.sh_shouldBeCheckedEnable)
    {
        [self _sh_viewWillAppear:animated];
        return;
    }
    
    self.internal_viewWillAppearing = YES;
    [self _sh_viewWillAppear:animated];
}

- (void)_sh_viewDidAppear:(BOOL)animated {
    // 当`总开关设置`或`使能控制`不生效时，执行原始方法调用
    if (!UIViewController.sh_interfaceOrientationRuntimeEnable
        || !self.sh_interfaceOrientationEnable
        || !self.sh_shouldBeCheckedEnable)
    {
        [self _sh_viewDidAppear:animated];
        return;
    }
    
    self.internal_viewWillAppearing = NO;
    [self _sh_viewDidAppear:animated];
    
    if ([self isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navVc = (UINavigationController *)self;
        if (navVc.viewControllers.count > 0) {
            return;
        }
    }
    
    if ([self isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabbarVc = ((UITabBarController *)self);
        if (tabbarVc.viewControllers.count > 0) {
            return;
        }
    }
    
    if (self.sh_shouldAutoSettingInterfaceOrientationWhenViewDidAppear) {
        UIInterfaceOrientation ori = [self preferredInterfaceOrientationForPresentation];
#ifndef Release
        NSLog(@"vvvvvvvvvvv 【1】 %@(%p) - %s ori=[%@]", NSStringFromClass(self.class), self, __FUNCTION__, sh_getStringWithOri(ori));
#endif
        // [1] 重置转场控制短路属性`internal_preferredInterfaceOrientation`为无效状态
        self.internal_preferredInterfaceOrientation = UIInterfaceOrientationUnknown;
        // [2] 按真实业务设置的方向执行旋转
        [self sh_updateOrientation];
    }
}

- (void)_sh_dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    // 当`总开关设置`或`使能控制`不生效时，执行原始方法调用
    if (!UIViewController.sh_interfaceOrientationRuntimeEnable
        || !self.sh_interfaceOrientationEnable
        || !self.sh_shouldBeCheckedEnable)
    {
        [self _sh_dismissViewControllerAnimated:flag completion:completion];
        return;
    }
    
    __weak UIViewController *weakSelf = self.presentingViewController;
    if (!weakSelf) {
        weakSelf = self;
    }
    [self _sh_dismissViewControllerAnimated:flag completion:^{
        if (completion) {
            completion();
        }
        __strong UIViewController *strongSelf = weakSelf;
        if (strongSelf) {
            // FIXME: 此处重置internal_preferredInterfaceOrientation为默认值，不执行在dismiss时获取的方向将不正确。
            strongSelf.internal_preferredInterfaceOrientation = UIInterfaceOrientationUnknown;
            // FIXME: 重置所有控制器的 internal_preferredInterfaceOrientation 为 无效状态，避免 dismiss 时，调用 ora_updateOrientation 无法转换到正确的屏幕方向⚠️
            [UIViewController.sh_interfaceOrientationNotificationCenter postNotificationName:kInterfaceOrientationNotificationResolveInterfaceOrientationUnknownKey object:nil];
            [strongSelf sh_updateOrientation];
//            UIViewController *currentVc = [UIViewController currentViewControllerWithRootVc:self];
//            if (currentVc) {
//                currentVc.internal_preferredInterfaceOrientation = UIInterfaceOrientationUnknown;
//                [currentVc sh_updateOrientation];
//            }
        }
    }];
}

// MARK: - shouldAutorotate 控制

- (BOOL)sh_shouldAutorotateEnable {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        return number.boolValue;
    }
    self.sh_shouldAutorotateEnable = YES;
    return YES;
}

- (void)setSh_shouldAutorotateEnable:(BOOL)enabled {
    SEL key = @selector(sh_shouldAutorotateEnable);
    objc_setAssociatedObject(self, key, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)sh_shouldAutorotate {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        return number.boolValue;
    }
    self.sh_shouldAutorotate = YES;
    return YES;
}

- (void)setSh_shouldAutorotate:(BOOL)enabled {
    SEL key = @selector(sh_shouldAutorotate);
    objc_setAssociatedObject(self, key, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SHViewControllerShouldAutorotateInjectBlock)sh_shouldAutorotateInjectBlock {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setSh_shouldAutorotateInjectBlock:(SHViewControllerShouldAutorotateInjectBlock)block {
    objc_setAssociatedObject(self, @selector(sh_shouldAutorotateInjectBlock), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

/// 运行时方法 `shouldAutorotate`
- (BOOL)_sh_shouldAutorotate {
    // 当`总开关设置`或`使能控制`不生效时，执行原始方法调用
    if (!UIViewController.sh_interfaceOrientationRuntimeEnable
        || !self.sh_interfaceOrientationEnable
        || !self.sh_shouldAutorotateEnable)
    {
        return [self _sh_shouldAutorotate];
    }
    
    // 当前对象存在 presentedViewController 时（有self.presentViewController(vc, animate)）
    if (self.presentedViewController) {
        BOOL shouldBeChecked = self.presentedViewController.sh_shouldBeCheckedEnable;
        if (self.sh_presentedViewControllerCheckEnable && shouldBeChecked) {
            return [self.presentedViewController shouldAutorotate];
        }
    }
    // 当前对象为 UINavigationController（包括子类时）类型时
    else if ([self isKindOfClass:[UINavigationController class]]) {
        UIViewController *topVc = ((UINavigationController *)self).topViewController;
        if (topVc) {
            return [topVc shouldAutorotate];
        }
    }
    // 当前对象为 UITabBarController（包括子类时）类型时
    else if ([self isKindOfClass:[UITabBarController class]]) {
        UIViewController *selectedVc = ((UITabBarController *)self).selectedViewController;
        if (selectedVc) {
            return [selectedVc shouldAutorotate];
        }
    }
    
    // 当注入block生效时，return block结果
    if (self.sh_shouldAutorotateInjectBlock) {
        BOOL autorotate = self.sh_shouldAutorotateInjectBlock(self);
#ifndef Release
        NSLog(@"vvvvvvvvvvv 【2】 sh_shouldAutorotateInjectBlock autorotate=[%d]", autorotate);
#endif
        return autorotate;
    }
    
    // 执行默认存储值
    BOOL autorotate = self.sh_shouldAutorotate;
#ifndef Release
    NSLog(@"vvvvvvvvvvv 【3】 %@(%p) - %s autorotate=[%d]", NSStringFromClass(self.class), self, __FUNCTION__, autorotate);
#endif
    return autorotate;
}

// MARK: - preferredInterfaceOrientationForPresentation 控制

- (BOOL)sh_preferredInterfaceOrientationForPresentationEnable {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        return number.boolValue;
    }
    self.sh_preferredInterfaceOrientationForPresentationEnable = YES;
    return YES;
}

- (void)setSh_preferredInterfaceOrientationForPresentationEnable:(BOOL)enabled {
    SEL key = @selector(sh_preferredInterfaceOrientationForPresentationEnable);
    objc_setAssociatedObject(self, key, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIInterfaceOrientation)sh_preferredInterfaceOrientation {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        return number.integerValue;
    }
    self.sh_preferredInterfaceOrientation = UIInterfaceOrientationPortrait;
    return UIInterfaceOrientationPortrait;
}

- (void)setSh_preferredInterfaceOrientation:(UIInterfaceOrientation)orientation {
    SEL key = @selector(sh_preferredInterfaceOrientation);
    objc_setAssociatedObject(self, key, [[NSNumber alloc] initWithInteger:(NSInteger)orientation], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)internal_viewWillAppearing {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        return number.boolValue;
    }
    self.internal_viewWillAppearing = NO;
    return YES;
}

- (void)setInternal_viewWillAppearing:(BOOL)enabled {
    SEL key = @selector(internal_viewWillAppearing);
    objc_setAssociatedObject(self, key, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIInterfaceOrientation)internal_preferredInterfaceOrientation {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        return number.integerValue;
    }
    self.internal_preferredInterfaceOrientation = UIInterfaceOrientationPortrait;
    return UIInterfaceOrientationPortrait;
}

- (void)setInternal_preferredInterfaceOrientation:(UIInterfaceOrientation)orientation {
    SEL key = @selector(internal_preferredInterfaceOrientation);
    objc_setAssociatedObject(self, key, [[NSNumber alloc] initWithInteger:(NSInteger)orientation], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SHViewControllerPreferredInterfaceOrientationInjectBlock)sh_preferredInterfaceOrientationInjectBlock {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setSh_preferredInterfaceOrientationInjectBlock:(SHViewControllerPreferredInterfaceOrientationInjectBlock)block {
    objc_setAssociatedObject(self, @selector(sh_preferredInterfaceOrientationInjectBlock), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setSh_preferredInterfaceOrientation:(UIInterfaceOrientation)orientation autoUpdateOrientation:(BOOL)isUpdate {
    self.sh_preferredInterfaceOrientation = orientation;
    [self sh_updateOrientation];
}

- (void)sh_updateOrientation {
    if (self.sh_interfaceOrientationEnable) {
        UIInterfaceOrientation ori = [self preferredInterfaceOrientationForPresentation];
#ifndef Release
        NSLog(@"vvvvvvvvvvv 【9】 %@(%p) - %s ori=[%@]", NSStringFromClass(self.class), self, __FUNCTION__, sh_getStringWithOri(ori));
#endif
        [UIDevice ora_forceOrientation:ori];
        [self _sh_sendInterfaceOrientationNotification];
    }
}

- (UIInterfaceOrientation)_sh_preferredInterfaceOrientationForPresentation {
    // 当`总开关设置`或`使能控制`不生效时，执行原始方法调用
    if (!UIViewController.sh_interfaceOrientationRuntimeEnable
        || !self.sh_interfaceOrientationEnable
        || !self.sh_preferredInterfaceOrientationForPresentationEnable)
    {
        return [self _sh_preferredInterfaceOrientationForPresentation];
    }
    
    // 当前对象存在 presentedViewController 时（有self.presentViewController(vc, animate)）
    if (self.presentedViewController) {
        BOOL shouldBeChecked = self.presentedViewController.sh_shouldBeCheckedEnable;
        if (self.sh_presentedViewControllerCheckEnable && shouldBeChecked) {
            return [self.presentedViewController preferredInterfaceOrientationForPresentation];
        }
    }
    // 当前对象为 UINavigationController（包括子类时）类型时
    else if ([self isKindOfClass:[UINavigationController class]]) {
        UIViewController *topVc = ((UINavigationController *)self).topViewController;
        if (topVc) {
            return [topVc preferredInterfaceOrientationForPresentation];
        }
    }
    // 当前对象为 UITabBarController（包括子类时）类型时
    else if ([self isKindOfClass:[UITabBarController class]]) {
        UIViewController *selectedVc = ((UITabBarController *)self).selectedViewController;
        if (selectedVc) {
            return [selectedVc preferredInterfaceOrientationForPresentation];
        }
    }
    
    // push 时临时给定动画过渡方向值
    UIInterfaceOrientation internal_Orientation = self.internal_preferredInterfaceOrientation;
    if (internal_Orientation != UIInterfaceOrientationUnknown) {
        return internal_Orientation;
    }
    
    // 当注入block生效时，return block结果
    if (self.sh_preferredInterfaceOrientationInjectBlock) {
        UIInterfaceOrientation ori = self.sh_preferredInterfaceOrientationInjectBlock(self);
#ifndef Release
        NSLog(@"vvvvvvvvvvv 【4】 sh_preferredInterfaceOrientationInjectBlock ori=[%@]", sh_getStringWithOri(ori));
#endif
        return ori;
    }
    
    // 执行默认存储值
    UIInterfaceOrientation ori = self.sh_preferredInterfaceOrientation;
#ifndef Release
    NSLog(@"vvvvvvvvvvv 【5】 %@(%p) - %s ori=[%@]", NSStringFromClass(self.class), self, __FUNCTION__, sh_getStringWithOri(ori));
#endif
    return ori;
}

// MARK: - supportedInterfaceOrientations 控制

- (BOOL)sh_supportedInterfaceOrientationsEnable {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        return number.boolValue;
    }
    self.sh_supportedInterfaceOrientationsEnable = YES;
    return YES;
}

- (void)setSh_supportedInterfaceOrientationsEnable:(BOOL)enabled {
    SEL key = @selector(sh_supportedInterfaceOrientationsEnable);
    objc_setAssociatedObject(self, key, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SHViewControllerSupportedInterfaceOrientationsInjectBlock)sh_supportedInterfaceOrientationsInjectBlock {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setSh_supportedInterfaceOrientationsInjectBlock:(SHViewControllerSupportedInterfaceOrientationsInjectBlock)block {
    objc_setAssociatedObject(self, @selector(sh_supportedInterfaceOrientationsInjectBlock), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (UIInterfaceOrientationMask)_sh_supportedInterfaceOrientations {
    // 当`总开关设置`或`使能控制`不生效时，执行原始方法调用
    if (!UIViewController.sh_interfaceOrientationRuntimeEnable
        || !self.sh_interfaceOrientationEnable
        || !self.sh_supportedInterfaceOrientationsEnable)
    {
        return [self _sh_supportedInterfaceOrientations];
    }
    
    // 当前对象存在 presentedViewController 时（有self.presentViewController(vc, animate)）
    if (self.presentedViewController) {
        BOOL shouldBeChecked = self.presentedViewController.sh_shouldBeCheckedEnable;
        if (self.sh_presentedViewControllerCheckEnable && shouldBeChecked) {
            return [self.presentedViewController supportedInterfaceOrientations];
        }
    }
    // 当前对象为 UINavigationController（包括子类时）类型时
    else if ([self isKindOfClass:[UINavigationController class]]) {
        UIViewController *topVc = ((UINavigationController *)self).topViewController;
        if (topVc) {
            return [topVc supportedInterfaceOrientations];
        }
    }
    // 当前对象为 UITabBarController（包括子类时）类型时
    else if ([self isKindOfClass:[UITabBarController class]]) {
        UIViewController *selectedVc = ((UITabBarController *)self).selectedViewController;
        if (selectedVc) {
            return [selectedVc supportedInterfaceOrientations];
        }
    }
    
    // push 时临时给定动画过渡方向值
    UIInterfaceOrientation internal_Orientation = self.internal_preferredInterfaceOrientation;
    if (internal_Orientation != UIInterfaceOrientationUnknown) {
        return sh_getOriMaskWithOri(internal_Orientation);
    }
    
    if (self.internal_viewWillAppearing) {
        return UIInterfaceOrientationMaskAll;
    }
    
    // 当注入block生效时，return block结果
    if (self.sh_supportedInterfaceOrientationsInjectBlock) {
        UIInterfaceOrientationMask ori = self.sh_supportedInterfaceOrientationsInjectBlock(self);
#ifndef Release
        NSLog(@"vvvvvvvvvvv 【6】 sh_supportedInterfaceOrientationsInjectBlock oriMask=[%@]", sh_getStringWithOriMask(ori));
#endif
        return ori;
    }
    
    // 解决手势交互返回时前一个vc和当前vc屏幕方向不一致时不能通过手势返回的问题⚠️
    UINavigationController *navVc = self.navigationController;
    if (navVc && navVc.topViewController != self) {
#ifndef Release
        NSLog(@"vvvvvvvvvvv 【7】 %@(%p) - %s oriMask=[%@], [navVc && navVc.topViewController != self]", NSStringFromClass(self.class), self, __FUNCTION__, sh_getStringWithOriMask(UIInterfaceOrientationMaskAll));
#endif
        return UIInterfaceOrientationMaskAll;
    }
    
    UIInterfaceOrientationMask mask = UIInterfaceOrientationMaskPortrait;
    switch (self.preferredInterfaceOrientationForPresentation) {
        case UIInterfaceOrientationUnknown:
            mask = UIInterfaceOrientationMaskAll;
            break;
        case UIInterfaceOrientationPortrait:
            mask = UIInterfaceOrientationMaskPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            mask = UIInterfaceOrientationMaskPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            mask = UIInterfaceOrientationMaskLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            mask = UIInterfaceOrientationMaskLandscapeRight;
            break;
        default:
            mask = UIInterfaceOrientationMaskPortrait;
            break;
    }
#ifndef Release
    NSLog(@"vvvvvvvvvvv 【8】 %@(%p) - %s oriMask=[%@]", NSStringFromClass(self.class), self, __FUNCTION__, sh_getStringWithOriMask(mask));
#endif
    return mask;
}

// MARK: - Action

/// 自锁通知处理
/// @param noti 通知字典
- (void)_sh_interfaceOrientationNotification:(NSNotification *)noti {
    NSDictionary *dict = noti.object;
    if (dict && [dict isKindOfClass:NSDictionary.class]) {
        //UINavigationController *navVc     = dict[kInterfaceOrientationNotificationNavigationControllerKey];
        UIViewController       *senderVc  = dict[kInterfaceOrientationNotificationSenderViewControllerKey];
        NSNumber               *oriNumber = dict[kInterfaceOrientationNotificationSenderViewControllerInterfaceOrientationKey];
        if (/*navVc && [navVc isKindOfClass:UINavigationController.class]
            &&*/ senderVc && [senderVc isKindOfClass:UIViewController.class]
            && oriNumber && [oriNumber isKindOfClass:NSNumber.class])
        {
            UIInterfaceOrientation ori = (UIInterfaceOrientation)oriNumber.integerValue;
            // 通知发出者不需要修改 internal_preferredInterfaceOrientation
            if (senderVc == self) { return; }
            //if (self.navigationController.topViewController == self) { return; }
            //if (navVc == self.navigationController) {
                self.internal_preferredInterfaceOrientation = ori;
            //}
        }
    }
}

- (void)_sh_resolveInterfaceOrientationUnknownNotification:(NSNotification *)noti {
    self.internal_preferredInterfaceOrientation = UIInterfaceOrientationUnknown;
}

// MARK: - Private

/// 发送当前视图控制器的偏好屏幕方向通知
- (void)_sh_sendInterfaceOrientationNotification {
    if (self.isViewLoaded && (self.parentViewController || self.presentingViewController)) {
        UIInterfaceOrientation ori = [self preferredInterfaceOrientationForPresentation];
        NSDictionary *obj = @{
            kInterfaceOrientationNotificationNavigationControllerKey: self.navigationController ?: NSNull.new,
            kInterfaceOrientationNotificationSenderViewControllerKey: self,
            kInterfaceOrientationNotificationSenderViewControllerInterfaceOrientationKey: [NSNumber numberWithInteger:ori]
        };
        if (NSThread.isMainThread) {
            [UIViewController.sh_interfaceOrientationNotificationCenter postNotificationName:kInterfaceOrientationNotificationKey object:obj];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [UIViewController.sh_interfaceOrientationNotificationCenter postNotificationName:kInterfaceOrientationNotificationKey object:obj];
            });
        }
    }
}

@end

@implementation UINavigationController (SHInterfaceOrientationManager)

// MARK: - Class Method

+ (void)load {
    sh_swizzleSelector(self, @selector(pushViewController:animated:), @selector(_sh_pushViewController:animated:));
}

// MARK: - Life cycle

- (void)_sh_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // 当`总开关设置`或`使能控制`不生效时，执行原始方法调用
    if (!UIViewController.sh_interfaceOrientationRuntimeEnable
        || !self.sh_interfaceOrientationEnable)
    {
        [self _sh_pushViewController:viewController animated:animated];
        return;
    }
    if (animated) {
        UIViewController *topViewController = self.topViewController;
        viewController.internal_preferredInterfaceOrientation = [topViewController preferredInterfaceOrientationForPresentation];
        /*
         用于pop手势交互转场返回支持，和`internal_preferredInterfaceOrientation`共同一起起控制作用，
         如果去除`internal_viewWillAppearing`属性可能也不影响整体流程
         */
        topViewController.internal_viewWillAppearing = YES;
    }
    [self _sh_pushViewController:viewController animated:animated];
}

@end

//@implementation UITabBarController (InterfaceOrientation)
//@end
