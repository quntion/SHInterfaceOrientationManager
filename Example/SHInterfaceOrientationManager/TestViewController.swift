//
//  ViewController.swift
//  OraKit
//
//  Created by shaoruibo on 03/16/2022.
//  Copyright (c) 2022 shaoruibo. All rights reserved.
//

import UIKit
import SHInterfaceOrientationManager

//var num = 1

/// 直接集成组件方案
class TestViewController: UIViewController {

    let portraitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("竖向屏幕", for: .normal)
        btn.addTarget(self, action: #selector(onPortrait(_:)), for: .touchUpInside)
        return btn
    }()
    
    let landscapeRightButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("横向屏幕", for: .normal)
        btn.addTarget(self, action: #selector(onLandscape(_:)), for: .touchUpInside)
        return btn
    }()
    
    let pushButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("push", for: .normal)
        btn.addTarget(self, action: #selector(onPush(_:)), for: .touchUpInside)
        return btn
    }()
    
    let presentButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("present", for: .normal)
        btn.addTarget(self, action: #selector(onPresent(_:)), for: .touchUpInside)
        return btn
    }()
    
    let dismissButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("dismiss", for: .normal)
        btn.addTarget(self, action: #selector(onDismiss(_:)), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        view.backgroundColor = .white
        
        view.addSubview(portraitButton)
        view.addSubview(landscapeRightButton)
        view.addSubview(pushButton)
        view.addSubview(presentButton)
        view.addSubview(dismissButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let frame = self.view.frame
        
        portraitButton.sizeToFit()
        portraitButton.center = CGPoint(x: frame.width * 0.5, y: 140)
        
        landscapeRightButton.sizeToFit()
        landscapeRightButton.center = CGPoint(x: frame.width * 0.5, y: 180)
        
        pushButton.sizeToFit()
        pushButton.center = CGPoint(x: frame.width * 0.5, y: 220)
        
        presentButton.sizeToFit()
        presentButton.center = CGPoint(x: frame.width * 0.5, y: 260)
        
        dismissButton.sizeToFit()
        dismissButton.center = CGPoint(x: frame.width * 0.5, y: 300)
    }
    
    // MARK: - Actions
    
    @objc func onPortrait(_ sender: UIButton) {
        print("点击切换到 竖屏 ...")
        setSh_preferredInterfaceOrientation(.portrait, autoUpdateOrientation: true)
    }
    
    @objc func onLandscape(_ sender: UIButton) {
        print("点击切换到 横屏 ...")
        setSh_preferredInterfaceOrientation(.landscapeRight, autoUpdateOrientation: true)
    }
    
    @objc func onPush(_ sender: UIButton) {
        print("点击 push ...")
        let nextVc = TestViewController()
        let count = navigationController?.viewControllers.count ?? 1
        nextVc.title = "\(count)"
        nextVc.sh_preferredInterfaceOrientation = count % 2 == 0 ? .portrait : .landscapeRight
        navigationController?.pushViewController(nextVc, animated: true)
    }
    
    @objc func onPresent(_ sender: UIButton) {
        print("点击 present ...")
        
        /*
         present 的控制器类似 window.rootViewController，是不需要单独处理的，会被正常调用到
         modalPresentationStyle 的 呈现样式是有影响 当前旋转方向生效值，必须代码查找到对应的presentedViewController控制器才行
         */
        
        let rootVc = TestViewController()
        let navVc = UINavigationController(rootViewController: rootVc)
//        let navVc = UINavigationController(rootViewController: rootVc)
//        navVc.modalPresentationStyle = .fullScreen
        let count = rootVc.navigationController?.viewControllers.count ?? 1
        rootVc.title = "present \(count)"
        rootVc.sh_preferredInterfaceOrientation = count % 2 == 0 ? .portrait : .landscapeRight
        present(navVc, animated: true) {
            print("点击 present complete ...")
        }
    }
    
    @objc func onDismiss(_ sender: UIButton) {
        print("点击 dismiss ...")
        dismiss(animated: true) {
            print("点击 dismiss complete ...")
        }
    }
}
