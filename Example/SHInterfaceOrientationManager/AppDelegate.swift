//
//  AppDelegate.swift
//  SHInterfaceOrientationManager
//
//  Created by 邵瑞波 on 08/06/2022.
//  Copyright (c) 2022 邵瑞波. All rights reserved.
//

import UIKit
import SHInterfaceOrientationManager

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        
        // 😭【系统原生实现方案参照】
        //window?.rootViewController = CustomNavigationController(rootViewController: ViewController())
        
        // 😊【SHInterfaceOrientationManager 示例】
        window?.rootViewController = {
            let tabbarVc = UITabBarController()
            tabbarVc.addChildViewController({
                let navVc = UINavigationController(rootViewController: {
                    let vc = TestViewController()
                    vc.title = "vc1 - portrait"
                    vc.sh_preferredInterfaceOrientation = .portrait
                    return vc
                }())
                return navVc
            }())
            tabbarVc.addChildViewController({
                let navVc = UINavigationController(rootViewController: {
                    let vc = TestViewController()
                    vc.title = "vc2 - portraitUpsideDown"
                    vc.sh_preferredInterfaceOrientation = .portraitUpsideDown
                    return vc
                }())
                return navVc
            }())
            tabbarVc.addChildViewController({
                let navVc = UINavigationController(rootViewController: {
                    let vc = TestViewController()
                    vc.title = "vc3 - landscapeLeft"
                    vc.sh_preferredInterfaceOrientation = .landscapeLeft
                    return vc
                }())
                return navVc
            }())
            tabbarVc.addChildViewController({
                let navVc = UINavigationController(rootViewController: {
                    let vc = TestViewController()
                    vc.title = "vc4 - landscapeRight"
                    vc.sh_preferredInterfaceOrientation = .landscapeRight
                    return vc
                }())
                return navVc
            }())
            return tabbarVc
        }()
        
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
//        let ori: UIInterfaceOrientationMask = window?.rootViewController?.supportedInterfaceOrientations ?? .all
        let ori: UIInterfaceOrientationMask = .all
        print("\(Self.self) - \(#function) - [\(ori)]")
        return ori
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

