//
//  MapViewController.swift
//  ExchangeAGram
//
//  Created by David Pirih on 05.11.14.
//  Copyright (c) 2014 Piri-Piri. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let request = NSFetchRequest(entityName: "FeedItem")
        let appDelegate: AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
        let context:NSManagedObjectContext = appDelegate.managedObjectContext
        
        let itemArray: [AnyObject]?
        do {
            itemArray = try context.executeFetchRequest(request)
        } catch let error as NSError {
            print(error)
            itemArray = nil
        }
        
        if itemArray!.count > 0 {
            for item in itemArray! {
                let location = CLLocationCoordinate2D(latitude: Double(item.latitude), longitude: Double(item.longitude))
                let span = MKCoordinateSpanMake(0.05, 0.05)
                let region = MKCoordinateRegionMake(location, span)
                mapView.setRegion(region, animated: true)
            
                let annotation = MKPointAnnotation()
                annotation.coordinate = location
                annotation.title = item.caption
                mapView.addAnnotation(annotation)
            }
        }
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
