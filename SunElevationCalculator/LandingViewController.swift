//
//  LandingViewController.swift
//  SunElevationCalculator
//
//  Created by Nicole Olson on 1/20/20.
//  Copyright © 2020 Nicole Olson. All rights reserved.
//

import UIKit

class LandingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // reset the result arrays
        times_elevations.removeAll()
        color.removeAll()
        let c = Array(repeating: false, count: 288)
        color = c
        timeInterval = ""
        time = ""
    }
}
