//
//  SecondViewController.swift
//  SunElevationCalculator
//
//  Created by Nicole Olson on 1/17/20.
//  Copyright © 2020 Nicole Olson. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()
        viewDidAppear(true)
        while times_elevations.count == 0 {sleep(UInt32(1))}
    }

    @IBOutlet weak var table: UITableView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.table.reloadData()
    }
    
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return times_elevations.count }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "Cell")
        cell.textLabel?.text = times_elevations[indexPath.row]
        
        if (color[indexPath.row] == true) {
            cell.backgroundColor = UIColor(red: 244/255, green: 247/255, blue: 4/255, alpha: 0.9)
        } else {
            cell.backgroundColor = UIColor.white
        }
        let font = UIFont(name: "Courier", size: 12)!
        cell.textLabel?.font = font
        
        return cell
    }
}
