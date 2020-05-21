//
//  Presets+CoreDataProperties.swift
//  SunElevationCalculator
//
//  Created by Nicole Olson on 4/21/20.
//  Copyright © 2020 Nicole Olson. All rights reserved.
//
//

import Foundation
import CoreData


extension Presets {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Presets> {
        return NSFetchRequest<Presets>(entityName: "Presets")
    }

    @NSManaged public var down_switch: Bool
    @NSManaged public var thirty_switch: Bool
    @NSManaged public var up_switch: Bool

}
