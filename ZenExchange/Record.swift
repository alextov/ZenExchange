//
//  Record.swift
//  ZenExchange
//
//  Created by Alexander Tovstonozhenko on 13.01.15.
//  Copyright (c) 2015 Alexander Tovstonozhenko. All rights reserved.
//

import Foundation
import CoreData

class Record: NSManagedObject {

    @NSManaged var date: NSDate
    @NSManaged var usdUah: NSNumber
    @NSManaged var usdRub: NSNumber
    @NSManaged var eurUah: NSNumber
    @NSManaged var eurRub: NSNumber
    @NSManaged var oil: NSNumber
    
    var dateAsString: String {
        get {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .ShortStyle
            dateFormatter.timeStyle = .ShortStyle
            return dateFormatter.stringFromDate(date)
        }
    }

}
