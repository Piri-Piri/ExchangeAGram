//
//  FeedItem.swift
//  ExchangeAGram
//
//  Created by David Pirih on 31.10.14.
//  Copyright (c) 2014 Piri-Piri. All rights reserved.
//

import Foundation
import CoreData

@objc(FeedItem)
class FeedItem: NSManagedObject {

    @NSManaged var caption: String
    @NSManaged var image: NSData
    @NSManaged var thumbNail: NSData

}
