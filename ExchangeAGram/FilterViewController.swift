//
//  FilterViewController.swift
//  ExchangeAGram
//
//  Created by David Pirih on 30.10.14.
//  Copyright (c) 2014 Piri-Piri. All rights reserved.
//

import UIKit

class FilterViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var feedItem: FeedItem!
    
    var collectionView: UICollectionView!
    
    let kIntensity = 0.7
    
    var context: CIContext = CIContext(options: nil)
    
    var filters: [CIFilter] = []
    
    let placeHolderImage = UIImage(named: "Placeholder")
    
    let tmp = NSTemporaryDirectory()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 150.0, height: 150.0)
        collectionView =  UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.registerClass(FilterCell.self, forCellWithReuseIdentifier: "Cell")
    
        self.view.addSubview(collectionView)
        
        filters = photoFilters()
    }
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: FilterCell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! FilterCell
        
        cell.imageView.image = placeHolderImage
        
        let filterQueue: dispatch_queue_t = dispatch_queue_create("filter queue", nil)
        
        dispatch_async(filterQueue, { () -> Void in
            
            let filterImage = self.getCachedImage(indexPath.row)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                cell.imageView.image = filterImage
            })
        })

        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        createAlertController(indexPath)
    }
    
    
    // MARK: - Helper Functions
    
    func photoFilters() -> [CIFilter] {
        let blur = CIFilter(name: "CIGaussianBlur")

        let instant = CIFilter(name: "CIPhotoEffectInstant")
        
        let noir = CIFilter(name: "CIPhotoEffectNoir")
        
        let transfer = CIFilter(name: "CIPhotoEffectTransfer")
        
        let unsharpen = CIFilter(name: "CIUnsharpMask")
        
        let monochrom = CIFilter(name: "CIColorMonochrome")
        
        let colorControls = CIFilter(name: "CIColorControls")
        colorControls!.setValue(0.5, forKey: kCIInputSaturationKey)
        
        let sepia = CIFilter(name: "CISepiaTone")
        sepia!.setValue(kIntensity, forKey: kCIInputIntensityKey)
        
        let colorClamp = CIFilter(name: "CIColorClamp")
        colorClamp!.setValue(CIVector(x: 0.9, y: 0.9, z: 0.9, w: 0.9), forKey: "inputMaxComponents")
        colorClamp!.setValue(CIVector(x: 0.2, y: 0.2, z: 0.2, w: 0.2), forKey: "inputMinComponents")
        
        let composite = CIFilter(name: "CIHardLightBlendMode")
        composite!.setValue(sepia!.outputImage, forKey: kCIInputImageKey)
        
        let vignette = CIFilter(name: "CIVignette")
        vignette!.setValue(composite!.outputImage, forKey: kCIInputImageKey)
        vignette!.setValue(kIntensity * 2, forKey: kCIInputIntensityKey)
        vignette!.setValue(kIntensity * 230, forKey: kCIInputRadiusKey)
        
        return [blur!, instant!, noir!, transfer!, unsharpen!, monochrom!, colorControls!, sepia!, colorClamp!, composite!, vignette!]
    }
    
    func filterImageFromImage(imageData: NSData, filter: CIFilter) -> UIImage {
        let unfilteredImage = CIImage(data: imageData)
        filter.setValue(unfilteredImage, forKey: kCIInputImageKey)
        let filteredImage:CIImage = filter.outputImage
        
        // optimize image to have avoid ui blocking (perfomance)
        let extent = filteredImage.extent
        let cgImage: CGImageRef = context.createCGImage(filteredImage, fromRect: extent)
        
        let finalImage = UIImage(CGImage: cgImage, scale: 1.0, orientation: UIImageOrientation.Up)
        
        return finalImage
    }
    
    // MARK: - AlerController Functions
    
    func createAlertController(indexPath: NSIndexPath) {
        let alert = UIAlertController(title: "Photo Options", message: "Please choose an option", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler { (textfield) -> Void in
            textfield.placeholder = "Add Caption here"
        }
        
        let textField = alert.textFields![0] as UITextField
        
        let photoAction = UIAlertAction(title: "Post Photo tp Facebook with Caption", style: UIAlertActionStyle.Destructive) { (UIAlertAction) -> Void in
            self.shareToFacebook(indexPath)
            self.saveFilterToCoreData(indexPath, caption: textField.text!)
        }
        alert.addAction(photoAction)
        
        let saveFilterAction = UIAlertAction(title: "Save Filter without posting on Facebook", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            self.saveFilterToCoreData(indexPath, caption: textField.text!)
        }
        alert.addAction(saveFilterAction)
        
        let cancelAction = UIAlertAction(title: "Select another Filter", style: UIAlertActionStyle.Cancel) { (UIAlertAction) -> Void in

        }
        alert.addAction(cancelAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func saveFilterToCoreData(indexPath: NSIndexPath, caption: String) {
        let filterImage = self.filterImageFromImage(feedItem.image, filter: filters[indexPath.row])
        
        let imageData = UIImageJPEGRepresentation(filterImage, 1.0)
        feedItem.image = imageData!
        
        let thumbNailData = UIImageJPEGRepresentation(filterImage, 0.1)
        feedItem.thumbNail = thumbNailData!
        
        feedItem.caption = caption
        
        feedItem.filtered = true
        
        (UIApplication.sharedApplication().delegate as! AppDelegate).saveContext()
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func shareToFacebook(indexPath: NSIndexPath) {
        let filterImage = self.filterImageFromImage(feedItem.image, filter: filters[indexPath.row])
        
        let photos: NSArray = [filterImage]
        let params = FBPhotoParams()
        params.photos = photos as [AnyObject]
        
        FBDialogs.presentShareDialogWithPhotoParams(params, clientState: nil) { (call, result, error) -> Void in
            if result != nil {
                print(result)
            }
            else {
                print(error)
            }
        }
    }
    
    // MARK: - Caching Functions
    
    func cacheImage(imageNumber: Int) {
        let fileName = "\(feedItem.uniqueID)\(imageNumber)"
        let uniquePath = tmp.stringByAppendingPathComponent(fileName)
        
        if !NSFileManager.defaultManager().fileExistsAtPath(fileName) {
            let data = self.feedItem.thumbNail
            let filter = self.filters[imageNumber]
            let image = filterImageFromImage(data, filter: filter)
            UIImageJPEGRepresentation(image, 1.0)!.writeToFile(uniquePath, atomically: true)
        }
    }
    
    func getCachedImage(imageNumber: Int) -> UIImage {
        let fileName = "\(feedItem.uniqueID)\(imageNumber)"
        let uniquePath = tmp.stringByAppendingPathComponent(fileName)
        
        var image: UIImage
        
        if NSFileManager.defaultManager().fileExistsAtPath(uniquePath) {
            let returnedImage = UIImage(contentsOfFile: uniquePath)!
            /*
            // fix orientation for running app on an actual device
            image = UIImage(CGImage: returnedImage.CGImage, scale: 1.0, orientation: UIImageOrientation.Right)!
            */
            image = returnedImage
            
        }
        else {
            self.cacheImage(imageNumber)
            let returnedImage = UIImage(contentsOfFile: uniquePath)!
            /*
            // fix orientation for running app on an actual device
            image = UIImage(CGImage: returnedImage.CGImage, scale: 1.0, orientation: UIImageOrientation.Right)!
            */
            image = returnedImage
            
        }
        return image
    }
    
    
    
    
    
    
}
