//
//  Sun_Data+CoreDataProperties.swift
//  SunElevationCalculator
//
//  Created by Nicole Olson on 4/20/20.
//  Copyright © 2020 Nicole Olson. All rights reserved.
//
//

import Foundation
import CoreData


extension Sun_Data {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Sun_Data> {
        return NSFetchRequest<Sun_Data>(entityName: "Sun_Data")
    }

    @NSManaged public var down: String?
    @NSManaged public var up: String?
    @NSManaged public var warning: String?
    @NSManaged public var day: Int32
    @NSManaged public var month: Int32
    @NSManaged public var year: Int32
    @NSManaged public var place: Location?

}
