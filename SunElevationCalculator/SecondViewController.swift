//
//  SecondViewController.swift
//  SunElevationCalculator
//
//  Created by Nicole Olson on 1/17/20.
//  Copyright © 2020 Nicole Olson. All rights reserved.
//
import UIKit


class SecondViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var count = 0
    
    override func viewDidLoad() {
        count = 0
        super.viewDidLoad()
        viewDidAppear(true)
        while times_elevations.count == 0 {sleep(UInt32(1))}
    }

    @IBOutlet weak var table: UITableView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        print("Reloading table data now")
        self.table.reloadData()
    }
    
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return times_elevations.count }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "Cell")

        cell.textLabel?.text = times_elevations[safe: indexPath.row] // put "safe" there to call the extension

        count += 1
        print(count)
        
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


extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
