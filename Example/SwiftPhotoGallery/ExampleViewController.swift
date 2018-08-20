//
//  ExampleViewController.swift
//  SwiftPhotoGallery_Example
//
//  Created by Daniel McConville on 20/8/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import SwiftPhotoGallery

class ExampleViewController: PortraitOnlyViewController {
    
    let imageNames = ["image1.jpeg", "image2.jpeg", "image3.jpeg"]
    fileprivate let cButton = UIButton()
    fileprivate let showMeButton = UIButton()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        localInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        localInit()
    }
    
    func localInit() {
        cButton.frame = CGRect.init(x: 0, y: 0, width: 100, height: 50)
        cButton.backgroundColor = UIColor.red
        cButton.setTitle("Cancel", for: .normal)
        cButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        showMeButton.frame = CGRect.init(x: 0, y: 300, width: 100, height: 50)
        showMeButton.backgroundColor = UIColor.blue
        showMeButton.setTitle("Show Me", for: .normal)
        showMeButton.addTarget(self, action: #selector(didPressShowMeButton), for: .touchUpInside)
    }
    
    @objc func buttonAction(sender: UIButton!) {
        print("Button tapped")
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didPressShowMeButton(_ sender: AnyObject) {
        let gallery = SwiftPhotoGallery(delegate: self, dataSource: self)
        
        gallery.backgroundColor = UIColor.black
        gallery.pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.5)
        gallery.currentPageIndicatorTintColor = UIColor(red: 0.0, green: 0.66, blue: 0.875, alpha: 1.0)
        gallery.hidePageControl = false
        gallery.modalPresentationStyle = .overCurrentContext
        
        present(gallery, animated: true, completion: nil)
        
        /// Or load on a specific page like this:
        /*
         present(gallery, animated: false, completion: { () -> Void in
         gallery.currentPage = 2
         })
         */
    }
    
    override func viewDidLoad() {
        view.addSubview(showMeButton)
    }
}

// MARK: SwiftPhotoGalleryDataSource Methods
extension ExampleViewController: SwiftPhotoGalleryDataSource {
    
    func numberOfImagesInGallery(gallery: SwiftPhotoGallery) -> Int {
        return imageNames.count
    }
    
    func imageInGallery(gallery: SwiftPhotoGallery, forIndex: Int) -> UIImage? {
        return UIImage(named: imageNames[forIndex])
    }
    
    func cancelButton() -> UIButton {
        return cButton
    }
}

// MARK: SwiftPhotoGalleryDelegate Methods
extension ExampleViewController: SwiftPhotoGalleryDelegate {
    
    func galleryDidTapToClose(gallery: SwiftPhotoGallery) {
        dismiss(animated: true, completion: nil)
    }
    
    func galleryDidSwipeToClose(gallery: SwiftPhotoGallery) {
        dismiss(animated: true, completion: nil)
    }
}

