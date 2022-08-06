//
//  CustomNavigationController.swift
//  OraKit_Example
//
//  Created by shaoruibo on 2022/7/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import SHInterfaceOrientationManager

class CustomNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        sh_interfaceOrientationEnable = false
        // Do any additional setup after loading the view.
    }
    
    override var shouldAutorotate: Bool {
        let rotate = topViewController?.shouldAutorotate ?? false
        print("\(Self.self) - \(#function) - [\(rotate)]")
        return rotate
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let ori = topViewController?.supportedInterfaceOrientations ?? .portrait
        print("\(Self.self) - \(#function) - [\(ori)]")
        return ori
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        let ori = topViewController?.preferredInterfaceOrientationForPresentation ?? .portrait
        print("\(Self.self) - \(#function) - [\(ori)]")
        return ori
    }
}
