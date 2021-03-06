//
//  SwiftPhotoGallery.swift
//  Pods
//
//  Created by Justin Vallely on 8/25/15.
//
//

import Foundation
import UIKit

@objc public protocol SwiftPhotoGalleryDataSource {
    func numberOfImagesInGallery(gallery:SwiftPhotoGallery) -> Int
    
    /// Delegate method to return the image to be displayed. Return nil and implement 
    /// imagesInGallery(...) delegate method if you want to have multiple layered images displayed
    ///
    /// - Parameters:
    ///   - gallery: SwiftPhotoGallery displaying the image
    ///   - forIndex: index of the image to be displayed
    /// - Returns: Image to be displayed
    func imageInGallery(gallery:SwiftPhotoGallery, forIndex:Int) -> UIImage?
    
    /// Delegate method to return an array of images to display in a layerd fashion. This will only
    /// be called if imageInGallery(...) returns nil
    ///
    /// - Parameters:
    ///   - gallery: SwiftPhotoGallery displaying the images
    ///   - forIndex: index of the images to be displayed
    /// - Returns: Array of images to be displayed
    @objc optional func imagesInGallery(gallery: SwiftPhotoGallery, forIndex: Int) -> [UIImage]?
    
    
    /// Optional delegate method to set an image to act as a cancel button. If this is not
    /// implemented by the delegate, no cancel button will be overlaid. If an image is returned,
    /// it will be used as a cancel button, overlaid in the top right hand corner
    ///
    /// - Returns: UIButton to be used as a cancel button
    @objc optional func cancelButton() -> UIButton  //DGM
}

@objc public protocol SwiftPhotoGalleryDelegate {
    func galleryDidTapToClose(gallery:SwiftPhotoGallery)
    func galleryDidSwipeToClose(gallery: SwiftPhotoGallery) // DGM
}


// MARK: ------ SwiftPhotoGallery ------

public class SwiftPhotoGallery: UIViewController {

    fileprivate var animateImageTransition = false
    fileprivate var isViewFirstAppearing = true
    fileprivate var deviceInRotation = false

    public weak var dataSource: SwiftPhotoGalleryDataSource?
    public weak var delegate: SwiftPhotoGalleryDelegate?
    
    public lazy var imageCollectionView: UICollectionView = self.setupCollectionView()
    
    public var numberOfImages: Int {
        return collectionView(imageCollectionView, numberOfItemsInSection: 0)
    }
    
    public var backgroundColor: UIColor {
        get {
            return view.backgroundColor!
        }
        set(newBackgroundColor) {
            view.backgroundColor = newBackgroundColor
        }
    }
    
    public var currentPageIndicatorTintColor: UIColor {
        get {
            return pageControl.currentPageIndicatorTintColor!
        }
        set(newCurrentPageIndicatorTintColor) {
            pageControl.currentPageIndicatorTintColor = newCurrentPageIndicatorTintColor
        }
    }
    
    public var pageIndicatorTintColor: UIColor {
        get {
            return pageControl.pageIndicatorTintColor!
        }
        set(newPageIndicatorTintColor) {
            pageControl.pageIndicatorTintColor = newPageIndicatorTintColor
        }
    }
    
    public var currentPage: Int {
        set(page) {
            if page < numberOfImages {
                scrollToImage(withIndex: page, animated: false)
            } else {
                scrollToImage(withIndex: numberOfImages - 1, animated: false)
            }
            updatePageControl()
        }
        get {
            if isRevolvingCarouselEnabled {
                pageBeforeRotation = Int(imageCollectionView.contentOffset.x / imageCollectionView.frame.size.width) - 1
                return Int(imageCollectionView.contentOffset.x / imageCollectionView.frame.size.width) - 1
            } else {
                pageBeforeRotation = Int(imageCollectionView.contentOffset.x / imageCollectionView.frame.size.width)
                return Int(imageCollectionView.contentOffset.x / imageCollectionView.frame.size.width)
            }
        }
    }
    
    public var hidePageControl: Bool = false {
        didSet {
            pageControl.isHidden = hidePageControl
        }
    }
    
    #if os(iOS)
    public var hideStatusBar: Bool = true {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    #endif
    
    public var isSwipeToDismissEnabled: Bool = true
    public var isRevolvingCarouselEnabled: Bool = true

    private var pageBeforeRotation: Int = 0
    private var currentIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    private var flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    fileprivate var pageControl: UIPageControl = UIPageControl()
    private var pageControlBottomConstraint: NSLayoutConstraint?
    private var pageControlCenterXConstraint: NSLayoutConstraint?
    private var needsLayout = true
    
    // MARK: Public Interface
    public init(delegate: SwiftPhotoGalleryDelegate, dataSource: SwiftPhotoGalleryDataSource) {
        super.init(nibName: nil, bundle: nil)
        
        self.dataSource = dataSource
        self.delegate = delegate
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func reload(imageIndexes:Int...) {
        
        if imageIndexes.isEmpty {
            imageCollectionView.reloadData()
            
        } else {
            let indexPaths: [IndexPath] = imageIndexes.map({IndexPath(item: $0, section: 0)})
            imageCollectionView.reloadItems(at: indexPaths)
        }
    }
    
    
    // MARK: Lifecycle methods
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        flowLayout.itemSize = view.bounds.size
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if needsLayout {
            let desiredIndexPath = IndexPath(item: pageBeforeRotation, section: 0)

            if pageBeforeRotation >= 0 {
                scrollToImage(withIndex: pageBeforeRotation, animated: false)
            }
            
            imageCollectionView.reloadItems(at: [desiredIndexPath])
            
            for cell in imageCollectionView.visibleCells {
                if let cell = cell as? SwiftPhotoGalleryCell {
                    if cell.images != nil && (cell.images?.count)! > 0 {
                        cell.configureForNewImages()
                    } else {
                        cell.configureForNewImage()
                    }
                }
            }
            
            needsLayout = false
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        
        pageControl.currentPageIndicatorTintColor = UIColor.white
        pageControl.pageIndicatorTintColor = UIColor(white: 0.75, alpha: 0.35) //Dim Gray

        isRevolvingCarouselEnabled = numberOfImages > 1
        setupPageControl()
        setupGestureRecognizers()
        setupCancelButton()
    }

    public override func viewDidAppear(_ animated: Bool) {
        if currentPage < 0 {
            currentPage = 0
        }
        isViewFirstAppearing = false
    }
    #if os(iOS)
    public override var prefersStatusBarHidden: Bool {
        get {
            return hideStatusBar
        }
    }
    #endif
    
    
    // MARK: Rotation Handling
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        deviceInRotation = true
        needsLayout = true
    }
    
    #if os(iOS)
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .allButUpsideDown
        }
    }
    #endif
    
    #if os(iOS)
    public override var shouldAutorotate: Bool {
        get {
            return true
        }
    }
    #endif
    
    
    // MARK: - Internal Methods
    
    func updatePageControl() {
        pageControl.currentPage = currentPage
    }
    
    
    // MARK: Gesture Handlers
    
    private func setupGestureRecognizers() {
        
        #if os(iOS)
            let panGesture = PanDirectionGestureRecognizer(direction: PanDirection.vertical, target: self, action: #selector(wasDragged(_:)))
            imageCollectionView.addGestureRecognizer(panGesture)
            imageCollectionView.isUserInteractionEnabled = true
        #endif
        
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapAction(recognizer:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.delegate = self
        imageCollectionView.addGestureRecognizer(singleTap)
    }
    
    #if os(iOS)
    @objc private func wasDragged(_ gesture: PanDirectionGestureRecognizer) {
        
        guard let image = gesture.view, isSwipeToDismissEnabled else { return }
        
        let translation = gesture.translation(in: self.view)
        image.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY + translation.y)
        
        let yFromCenter = image.center.y - self.view.bounds.midY
        
        let alpha = 1 - abs(yFromCenter / self.view.bounds.midY)
        self.view.backgroundColor = backgroundColor.withAlphaComponent(alpha)
        
        if gesture.state == UIGestureRecognizerState.ended {
            
            var swipeDistance: CGFloat = 0
            let swipeBuffer: CGFloat = 50
            var animateImageAway = false
            
            if yFromCenter > -swipeBuffer && yFromCenter < swipeBuffer {
                // reset everything
                UIView.animate(withDuration: 0.25, animations: {
                    self.view.backgroundColor = self.backgroundColor.withAlphaComponent(1.0)
                    image.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
                })
            } else if yFromCenter < -swipeBuffer {
                swipeDistance = 0
                animateImageAway = true
            } else {
                swipeDistance = self.view.bounds.height
                animateImageAway = true
            }
            
            if animateImageAway {
                if self.modalPresentationStyle == .custom {
                    self.delegate?.galleryDidTapToClose(gallery: self)
                    return
                }

                UIView.animate(withDuration: 0.35, animations: {
                    self.view.alpha = 0
                    image.center = CGPoint(x: self.view.bounds.midX, y: swipeDistance)
                }, completion: { (complete) in
                    self.singleSwipeAction(recognizer: UISwipeGestureRecognizer()) // DGM
                })
            }

        }
    }
    #endif

    @objc public func singleTapAction(recognizer: UITapGestureRecognizer) {
        delegate?.galleryDidTapToClose(gallery: self)
    }

    public func singleSwipeAction(recognizer: UISwipeGestureRecognizer) {
        delegate?.galleryDidSwipeToClose(gallery: self)
    }
    
    // MARK: Private Methods
    
    private func setupCollectionView() -> UICollectionView {
        // Set up flow layout
        flowLayout.scrollDirection = UICollectionViewScrollDirection.horizontal
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        
        // Set up collection view
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(SwiftPhotoGalleryCell.self, forCellWithReuseIdentifier: "SwiftPhotoGalleryCell")
        collectionView.register(SwiftPhotoGalleryCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "SwiftPhotoGalleryCell")
        collectionView.register(SwiftPhotoGalleryCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "SwiftPhotoGalleryCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        #if os(iOS)
            collectionView.isPagingEnabled = true
        #endif
        
        // Set up collection view constraints
        var imageCollectionViewConstraints: [NSLayoutConstraint] = []
        imageCollectionViewConstraints.append(NSLayoutConstraint(item: collectionView,
                                                                 attribute: .leading,
                                                                 relatedBy: .equal,
                                                                 toItem: view,
                                                                 attribute: .leading,
                                                                 multiplier: 1,
                                                                 constant: 0))
        
        imageCollectionViewConstraints.append(NSLayoutConstraint(item: collectionView,
                                                                 attribute: .top,
                                                                 relatedBy: .equal,
                                                                 toItem: view,
                                                                 attribute: .top,
                                                                 multiplier: 1,
                                                                 constant: 0))
        
        imageCollectionViewConstraints.append(NSLayoutConstraint(item: collectionView,
                                                                 attribute: .trailing,
                                                                 relatedBy: .equal,
                                                                 toItem: view,
                                                                 attribute: .trailing,
                                                                 multiplier: 1,
                                                                 constant: 0))
        
        imageCollectionViewConstraints.append(NSLayoutConstraint(item: collectionView,
                                                                 attribute: .bottom,
                                                                 relatedBy: .equal,
                                                                 toItem: view,
                                                                 attribute: .bottom,
                                                                 multiplier: 1,
                                                                 constant: 0))
        
        view.addSubview(collectionView)
        view.addConstraints(imageCollectionViewConstraints)
        
        collectionView.contentSize = CGSize(width: 1000.0, height: 1.0)
        
        return collectionView
    }

//DGM
    private func setupCancelButton() {
        if let button = getCancelButton() {
            view.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            if #available(iOS 9.0, *) {
                let margin: CGFloat = 20.0
                button.widthAnchor.constraint(equalToConstant: button.frame.size.width).isActive = true
                button.heightAnchor.constraint(equalToConstant: button.frame.size.height).isActive = true
                button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin).isActive = true
                button.topAnchor.constraint(equalTo: view.topAnchor, constant: margin).isActive = true
            } else {
                // Fallback on earlier versions
            }
        }
    }
//DGM
    private func setupPageControl() {
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        
        pageControl.numberOfPages = numberOfImages
        pageControl.currentPage = 0
        
        pageControl.currentPageIndicatorTintColor = currentPageIndicatorTintColor
        pageControl.pageIndicatorTintColor = pageIndicatorTintColor
        
        pageControl.alpha = 1
        pageControl.isHidden = hidePageControl
        
        view.addSubview(pageControl)
        
        pageControlCenterXConstraint = NSLayoutConstraint(item: pageControl,
                                                          attribute: NSLayoutAttribute.centerX,
                                                          relatedBy: NSLayoutRelation.equal,
                                                          toItem: view,
                                                          attribute: NSLayoutAttribute.centerX,
                                                          multiplier: 1.0,
                                                          constant: 0)
        
        pageControlBottomConstraint = NSLayoutConstraint(item: view,
                                                         attribute: NSLayoutAttribute.bottom,
                                                         relatedBy: NSLayoutRelation.equal,
                                                         toItem: pageControl,
                                                         attribute: NSLayoutAttribute.bottom,
                                                         multiplier: 1.0,
                                                         constant: 15)
        
        view.addConstraints([pageControlCenterXConstraint!, pageControlBottomConstraint!])
    }
    
    private func scrollToImage(withIndex: Int, animated: Bool = false) {
        imageCollectionView.scrollToItem(at: IndexPath(item: withIndex, section: 0), at: .centeredHorizontally, animated: animated)
    }

    //DGM
    fileprivate func getImage(currentPage: Int) -> UIImage? {
        return dataSource?.imageInGallery(gallery: self, forIndex: currentPage)
    }
    
    fileprivate func getImages(currentPage: Int) -> [UIImage] {
        //DGM
        if let images = dataSource?.imagesInGallery?(gallery: self, forIndex: currentPage) {
            return images
        } else {
            return [UIImage]()
        }
    }
    
    fileprivate func getCancelButton() -> UIButton? {
        return dataSource?.cancelButton?()
        //DGM
    }
    
}


// MARK: UICollectionViewDataSource Methods
extension SwiftPhotoGallery: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ imageCollectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?.numberOfImagesInGallery(gallery: self) ?? 0
    }
    
    public func collectionView(_ imageCollectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = imageCollectionView.dequeueReusableCell(withReuseIdentifier: "SwiftPhotoGalleryCell", for: indexPath) as! SwiftPhotoGalleryCell
        //DGM
        let image = getImage(currentPage: indexPath.row)
        if image != nil {
            cell.image = image
        } else {
            cell.images = getImages(currentPage: indexPath.row)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var cell = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "SwiftPhotoGalleryCell", for: indexPath) as! SwiftPhotoGalleryCell

        switch kind {
        case UICollectionElementKindSectionFooter:
            cell.image = getImage(currentPage: 0)
        case UICollectionElementKindSectionHeader:
            cell = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "SwiftPhotoGalleryCell", for: indexPath) as! SwiftPhotoGalleryCell
            if isViewFirstAppearing {
                cell.image = getImage(currentPage: 0)
            } else {
                cell.image = getImage(currentPage: numberOfImages - 1)
            }
        default:
            assertionFailure("Unexpected element kind")
        }

        return cell
    }

    @objc public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard isRevolvingCarouselEnabled else { return CGSize.zero }
        return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }

    @objc public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard isRevolvingCarouselEnabled else { return CGSize.zero }
        return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
}


// MARK: UICollectionViewDelegate Methods
extension SwiftPhotoGallery: UICollectionViewDelegate {
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        animateImageTransition = true
        self.pageControl.alpha = 1.0
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        animateImageTransition = false

        // If the scroll animation ended, update the page control to reflect the current page we are on
        updatePageControl()
        
        UIView.animate(withDuration: 1.0, delay: 2.0, options: UIViewAnimationOptions.curveEaseInOut, animations: { () -> Void in
            self.pageControl.alpha = 0.0
        }, completion: nil)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? SwiftPhotoGalleryCell {
            //DGM
            if cell.images != nil && (cell.images?.count)! > 0 {
                cell.configureForNewImages()
            } else {
                cell.configureForNewImage(animated: animateImageTransition)
            }
        }
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if let cell = view as? SwiftPhotoGalleryCell {
            collectionView.layoutIfNeeded()
            cell.configureForNewImage(animated: animateImageTransition)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if !collectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionFooter).isEmpty && !deviceInRotation || (currentPage == numberOfImages && !deviceInRotation) {
            currentPage = 0
        }
        if !collectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionHeader).isEmpty && !deviceInRotation || (currentPage == -1 && !deviceInRotation) {
            currentPage = numberOfImages - 1
        }
        deviceInRotation = false
    }
}


// MARK: UIGestureRecognizerDelegate Methods
extension SwiftPhotoGallery: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return otherGestureRecognizer is UITapGestureRecognizer &&
            gestureRecognizer is UITapGestureRecognizer &&
            otherGestureRecognizer.view is SwiftPhotoGalleryCell &&
            gestureRecognizer.view == imageCollectionView
    }
}
