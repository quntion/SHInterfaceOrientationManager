//
//  ViewController.swift
//  OraKit
//
//  Created by shaoruibo on 03/16/2022.
//  Copyright (c) 2022 shaoruibo. All rights reserved.
//

import UIKit
import SHInterfaceOrientationManager

var num = 1

// 原生处理方案参照
class ViewController: UIViewController {

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
    
    public var currentOrientation: UIInterfaceOrientation = .portrait
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        sh_interfaceOrientationEnable = false
        
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        UIViewController.attemptRotationToDeviceOrientation()
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIDevice.ora_force(currentOrientation)
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        UIViewController.attemptRotationToDeviceOrientation()
//    }
    
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        UIViewController.attemptRotationToDeviceOrientation()
//    }
    
    // 手势返回时，如果前一个vc和当前vc的屏幕方向不一致，则手势会被打断，无法通过手势交互返回上一个页面⚠️
    
    // MARK: - 屏幕方向
    
    // 这里如果返回false，则无法执行强制旋转操作，为true时才能执行强制旋转操作⚠️
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        print("\(Self.self) - \(#function) - [\(currentOrientation)]")
        return currentOrientation
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
        // 解决手势交互返回时前一个vc和当前vc屏幕方向不一致时不能通过手势返回的问题⚠️
        if navigationController?.topViewController != self {
            return .all
        }
        var ori: UIInterfaceOrientationMask = .portrait
        switch currentOrientation {
        case .unknown:
            ori = .all
        case .portrait:
            ori = .portrait
        case .portraitUpsideDown:
            ori = .portraitUpsideDown
        case .landscapeLeft:
            ori = .landscapeLeft
        case .landscapeRight:
            ori = .landscapeRight
        }
        print("\(Self.self) - \(#function) - [\(ori)]")
        return ori
    }
    
    // MARK: - Actions
    
    @objc func onPortrait(_ sender: UIButton) {
        print("点击切换到 竖屏 ...")
        currentOrientation = .portrait
        UIDevice.ora_force(currentOrientation)
    }
    
    @objc func onLandscape(_ sender: UIButton) {
        print("点击切换到 横屏 ...")
        currentOrientation = .landscapeRight
        UIDevice.ora_force(currentOrientation)
    }
    
    @objc func onPush(_ sender: UIButton) {
        print("点击 push ...")
        let nextVc = ViewController()
        nextVc.sh_interfaceOrientationEnable = false
        let count = navigationController?.viewControllers.count ?? 1
        nextVc.title = "\(count)"
        nextVc.currentOrientation = count % 2 == 0 ? .portrait : .landscapeRight
        navigationController?.pushViewController(nextVc, animated: true)
    }
    
    @objc func onPresent(_ sender: UIButton) {
        print("点击 present ...")
        
        /*
         present 的控制器类似 window.rootViewController，是不需要单独处理的，会被正常调用到
         modalPresentationStyle 的 呈现样式是有影响 当前旋转方向生效值，必须代码查找到对应的presentedViewController控制器才行
         */
        
        let rootVc = ViewController()
        rootVc.sh_interfaceOrientationEnable = false
        let navVc = CustomNavigationController(rootViewController: rootVc)
        navVc.sh_interfaceOrientationEnable = false
//        let navVc = UINavigationController(rootViewController: rootVc)
//        navVc.modalPresentationStyle = .fullScreen
        let count = rootVc.navigationController?.viewControllers.count ?? 1
        rootVc.title = "present \(count)"
        rootVc.currentOrientation = count % 2 == 0 ? .portrait : .landscapeRight
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

