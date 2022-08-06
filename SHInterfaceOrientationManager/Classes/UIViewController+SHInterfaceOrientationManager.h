//
//  UIViewController+InterfaceOrientation.h
//  OraKit
//
//  Created by shaoruibo on 2022/7/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 内部调整全局控制器转场动画临时占位方向枚举值时会发出该通知，value 为 字典类型
/// 注意：（通知object是字典类型，包含"kInterfaceOrientationNotificationNavigationControllerKey"和"kInterfaceOrientationNotificationSenderViewControllerKey"和"kInterfaceOrientationNotificationSenderViewControllerInterfaceOrientationKey"）
FOUNDATION_EXPORT NSString *kInterfaceOrientationNotificationKey;
/// value 为 UINavigationController 类型
FOUNDATION_EXPORT NSString *kInterfaceOrientationNotificationNavigationControllerKey;
/// value 为 UIViewController 类型
FOUNDATION_EXPORT NSString *kInterfaceOrientationNotificationSenderViewControllerKey;
/// value 为 UIInterfaceOrientation 的oc包装类型 NSNumber(NSInteger)
FOUNDATION_EXPORT NSString *kInterfaceOrientationNotificationSenderViewControllerInterfaceOrientationKey;

typedef BOOL (^SHViewControllerShouldAutorotateInjectBlock)(UIViewController *viewController);
typedef BOOL (^SHViewControllerPreferredInterfaceOrientationInjectBlock)(UIViewController *viewController);
typedef BOOL (^SHViewControllerSupportedInterfaceOrientationsInjectBlock)(UIViewController *viewController);

FOUNDATION_EXPORT NSString* sh_getStringWithOri(UIInterfaceOrientation ori);

/// ⚠️⚠️⚠️ 前置依赖"UIApplicationDelegate 的 `- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window` return时 给定支持所有方向 UIInterfaceOrientationMaskAll " ⚠️⚠️⚠️
@interface UIViewController (SHInterfaceOrientationManager)

// MARK: - Class

/// 设置顶层视图控制的当前屏幕方向（便于在非UIViewController中调用）
/// - Parameters:
///   - ori: 目标屏幕方向
///   - rootVc: 给定的遍历根节点控制器，如果给nil，则默认使用`UIApplication.sharedApplication.delegate.window.rootViewController`
+ (void)sh_forceInterfaceOrientationWith:(UIInterfaceOrientation)ori rootViewController:(nullable UIViewController *)rootVc;

// MARK: -  通知中心

/// 用于处理“内部调整前向导航栈控制器转场动画方向枚举值时会发出该通知”的通知中心对象
/// ⚠️ 注意：参见通知key值`kInterfaceOrientationNotificationKey`
@property (nonatomic, nonnull, strong, readonly, class) NSNotificationCenter *sh_interfaceOrientationNotificationCenter;

// MARK: - 总控制

/// true：开启运行时交互，false：屏蔽所有运行时处理（默认为true）
/// ⚠️ 注意：此处设置为false，所有运行时处理将失效
@property (nonatomic, assign, class) BOOL sh_interfaceOrientationRuntimeEnable;

// MARK: - 交互控制

/// true：表示接管系统默认行为，false：不接管系统处理，使用系统原始处理方式（默认为 true）
/// ⚠️ 注意：此处设置为false，当前控制器将不再通过运行时处理屏幕旋转功能
@property (nonatomic, assign) BOOL sh_interfaceOrientationEnable;

/// true：启用 self.presentedViewController 校验，如果存在，则使用 self.presentedViewController 的对应处理，false：使用系统原始处理方式
/// ⚠️ 注意：此处设置为false，将不再检查 self.presentedViewController 调用
@property (nonatomic, assign) BOOL sh_presentedViewControllerCheckEnable;

/// true：当前控制器被presented时应该被遍历检验，false：不应该检查当前控制器，应该被忽略（默认为 true）
/// ⚠️ 注意：此处设置为false，将不再被检查
@property (nonatomic, assign) BOOL sh_shouldBeCheckedEnable;

/// true：当`ViewDidAppear`调用时，自动执行页面方向旋转，false：不执行（默认为 true）
@property (nonatomic, assign) BOOL sh_shouldAutoSettingInterfaceOrientationWhenViewDidAppear;

/// true：当`preferredInterfaceOrientation`变动时，自动执行页面方向旋转，false：不执行（默认为 true）
//@property (nonatomic, assign) BOOL ora_shouldAutoSettingInterfaceOrientationWhenPreferredInterfaceOrientationUpdate;

// MARK: - shouldAutorotate 控制

/// true：启用 shouldAutorotate 运行时的控制，false：使用系统原始处理方式（默认为 true）
/// ⚠️ 注意：此处设置为false，将不再通过运行时处理自动旋转控制
@property (nonatomic, assign) BOOL sh_shouldAutorotateEnable;

/// true：当前控制器支持自动旋转，false：不支持自动旋转（默认为 true）
/// ⚠️ 注意：当此值给定false不支持自动旋转时，执行屏幕强制旋转将不会生效
@property (nonatomic, assign) BOOL sh_shouldAutorotate;

/// 当此值不为nil时， `sh_shouldAutorotate`  扩展属性将不再生效，而是通过此处注入的block获取当前控制器是否支持自动旋转的值
@property (nonatomic, nullable, copy) SHViewControllerShouldAutorotateInjectBlock sh_shouldAutorotateInjectBlock;

// MARK: - preferredInterfaceOrientationForPresentation 控制

/// true：启用 preferredInterfaceOrientationForPresentation 运行时的控制，false：使用系统原始处理方式（默认为 true）
/// ⚠️ 注意：此处设置为false，将不再通过运行时返回当前控制器的偏好屏幕方向
@property (nonatomic, assign) BOOL sh_preferredInterfaceOrientationForPresentationEnable;

/// 给定的当前控制器偏好屏幕旋转目标方向枚举值（默认为 UIInterfaceOrientationPortrait）
@property (nonatomic, assign) UIInterfaceOrientation sh_preferredInterfaceOrientation;

/// 当此值不为nil时， `sh_preferredInterfaceOrientation`  扩展属性将不再生效，而是通过此处注入的block获取当前控制器偏好屏幕旋转目标方向枚举值
/// ⚠️ 注意：该block内部如果调用 `preferredInterfaceOrientationForPresentation` 方法，可能会出现死循环问题，请检查自己的调用逻辑 ⚠️
@property (nonatomic, nullable, copy) SHViewControllerPreferredInterfaceOrientationInjectBlock sh_preferredInterfaceOrientationInjectBlock;

/// 设置当前控制器关联的屏幕方向，且根据给定参数决定是否需要执行屏幕旋转
/// @param orientation 新的屏幕方向
/// @param isUpdate YES：执行屏幕方向强制旋转操作，NO：不执行强制旋转
- (void)setSh_preferredInterfaceOrientation:(UIInterfaceOrientation)orientation autoUpdateOrientation:(BOOL)isUpdate;

/// 根据当前给定的方向参数执行强制旋转操作
- (void)sh_updateOrientation;

// MARK: - supportedInterfaceOrientations 控制

/// true：启用 supportedInterfaceOrientations 运行时的控制，false：使用系统原始处理方式（默认为 true）
/// ⚠️ 注意：此处设置为false，将不再通过运行时返回当前控制器的偏好屏幕方向
@property (nonatomic, assign) BOOL sh_supportedInterfaceOrientationsEnable;

/// 当此值不为nil时， `ora_supportedInterfaceOrientations`  扩展属性将不再生效，而是通过此处注入的block获取当前控制器偏好屏幕旋转目标方向枚举值
/// ⚠️ 注意：该block内部如果调用 `supportedInterfaceOrientations` 方法，可能会出现死循环问题，请检查自己的调用逻辑 ⚠️
@property (nonatomic, nullable, copy) SHViewControllerSupportedInterfaceOrientationsInjectBlock sh_supportedInterfaceOrientationsInjectBlock;

@end

@interface UINavigationController (InterfaceOrientation)
@end
//@interface UITabBarController (InterfaceOrientation)
//@end

NS_ASSUME_NONNULL_END
