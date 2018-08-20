//
//  PortraitOnlyViewController.swift
//  SwiftPhotoGallery_Example
//
//  Created by Daniel McConville on 20/8/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

class PortraitOnlyViewController: UIViewController {
    // MARK: Rotation Handling
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
}
