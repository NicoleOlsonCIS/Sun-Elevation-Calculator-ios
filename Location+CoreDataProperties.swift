//
//  Location+CoreDataProperties.swift
//  SunElevationCalculator
//
//  Created by Nicole Olson on 4/20/20.
//  Copyright © 2020 Nicole Olson. All rights reserved.
//
//

import Foundation
import CoreData

extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var city: String?
    @NSManaged public var country: String?
    @NSManaged public var latitude: String?
    @NSManaged public var longitude: String?
    @NSManaged public var state: String?

}
