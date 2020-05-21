//
//  TransitionViewController.swift
//  SunElevationCalculator
//
//  Created by Nicole Olson on 4/24/20.
//  Copyright © 2020 Nicole Olson. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import MapKit
import UserNotifications
import Foundation

class TransitionViewController: UIViewController {

    var locationManager = CLLocationManager()
    var success = false
    var latitude = ""
    var longitude = ""
    var current_city = ""
    var dates = [[Int]]()
    var uptimes = [String]()
    var downtimes = [String]()
    var warningtimes = [String]()
    @IBOutlet var information_text: UITextView!
    
    @IBOutlet var information_image: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        getLatLongFromCoreData()
        getElevationData()

        // Do any additional setup after loading the view.
    }
    
    func getElevationData()
    {
        while latitude == "" || longitude == ""
        {
            sleep(0)
            print("No latitude or longitude data")
        } // TEMPORARY EXPERIMENT
        let call = "https://sun-elevation-compute.wn.r.appspot.com/bulk?year=2020&lat=" + String(latitude) + "&long=" + String(longitude) + "&city=" + String(current_city)
        print("CALLING BACKEND!")
        return callBackend(fullUrl: call)
    }
    
    func getLatLongFromCoreData()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            if results.count > 0
            {
                for result in results as! [NSManagedObject]
                {
                    if let city = result.value(forKey: "city") as? String { current_city = city }
                    if let lat = result.value(forKey: "latitude") as? String { latitude = lat }
                    if let long = result.value(forKey: "longitude") as? String { longitude = long }
                }
            }
        } catch { print("Could not get results from Core Data in Location call")}
    }
    
    func callBackend(fullUrl: String)
    {
        var start = Double(0)
        if let url = URL(string: fullUrl)
        {
            let task = URLSession.shared.dataTask(with: url)
            {
                (data,response,error)in
                
                if error != nil { print("Error: Could not get results from server.") }
                else
                {
                    let diff = CFAbsoluteTimeGetCurrent() - start
                    print("Took \(diff) seconds")
                    if let returnData = String(data: data!, encoding: .utf8)
                    {
                        //print("Called for up and downtime")
                        //self.parseData(data: returnData)
                        DispatchQueue.main.sync(execute: {
                            let success = self.parseData(data:returnData)
                            if success == false
                            {
                                let secondsToDelay = 5.0
                                DispatchQueue.main.asyncAfter(deadline: .now() + secondsToDelay) {
                                   print("This message is delayed")
                                   // Put any code you want to be delayed here
                                    // USER "errorback" segue to return to previous page
                                    self.performSegue(withIdentifier: "errorback", sender: self)
                                }
                            }
                        })
                    }
                    else
                    {
                        print("ERROR IN CALL")
                        DispatchQueue.main.sync(execute: {
                            return
                        })
                    }
                }
            }
            task.resume()
            start = CFAbsoluteTimeGetCurrent()
            //rotateSunDuringWait()
        }
    }
    
    
    func parseData(data: String) -> Bool
    {
        print("Parsing Data!")
        //print(data)
        let parts = data.components(separatedBy: ", ")
        if parts.count == 0 || parts.count == 1
        {
            // ERROR IN GETTING SUN DATA FOR LOCATION, REASON IS THAT LOCATION IS SMALL
            // PRINT ERROR MESSAGE AND REDIRECT BACK
            information_text.text = "ERROR: No data. Choose a larger location. Redirecting . . ."
            information_image.image = UIImage(named: "storm")
            //viewWillAppear(true)
            
            self.view.setNeedsDisplay()
            
            return false
        }
        var separated_parts = [[String]]()
        for p in parts
        {
            var units = p.components(separatedBy: "-")
            // clean up data, convert to in
            if units.count > 0
            {
                let first = units[0]
                let last = units[units.count - 1]
                var new_first = ""
                var new_last = ""
                
                for f in first { if f.isNumber {new_first = new_first + String(f)}}
                for l in last {if l.isNumber || l == ":" {new_last = new_last + String(l)}}
                
                units[0] = new_first
                units[units.count - 1] = new_last
                
                separated_parts.append(units)
            }
        }
        
        if separated_parts.count > 0
        {
            for sp in separated_parts
            {
                if sp.count >= 5
                {
                    let day = Int(sp[0])
                    let month = Int(sp[1])
                    let year = Int(sp[2])
                    let date = [day, month, year]
                    dates.append(date as! [Int])
                    let uptime = sp[3]
                    let downtime = sp[4]
                    uptimes.append(uptime)
                    downtimes.append(downtime)
                }
            }
            
            // create the warning times by subtracting 30 min from the uptimes
            if uptimes.count > 0
            {
                for uptime in uptimes
                {
                    var t = uptime.components(separatedBy: ":")
                    var newtime = "0"
                    
                    // subtract 30 min
                    if t.count > 1
                    {
                        if Int(t[1])! >= 30
                        {
                            // hour stays the same
                            let newmin = Int(t[1])! - 30
                            t[1] = String(newmin)
                        }
                        else
                        {
                            let minus = Int(t[1])! - 30
                            let min = 30 + abs(minus)
                            t[1] = String(min)
                            
                            let hour = Int(t[0])! - 1
                            t[0] = String(hour)
                        }
                        
                        newtime = t[0] + ":" + t[1]
                    }
                    
                    warningtimes.append(newtime)
                }
            }
        }
        
        // turn this into objects
        var j = 0
        while j < warningtimes.count
        {
            let date = dates[j]
            let d = date[0]
            let m = date[1]
            let y = date[2]
            let ut = uptimes[j]
            let dt = downtimes[j]
            let wt = warningtimes[j]
            
            // create object
            let a = Alert(day:d, month:m, year:y, uptime:ut, downtime:dt, warningtime:wt)
            alerts.append(a)
            j += 1
        }
        
        // store data
        storeSunData()
        return true
    }
    
    func storeSunData()
    {
        // get the address object for the current place
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    if let lat = result.value(forKey: "latitude") as? String
                    {
                        if let long = result.value(forKey: "longitude") as? String
                        {
                            if lat == latitude && long == longitude
                            {
                                // we've found the right location object
                                var i = 0
                                while i < alerts.count
                                {
                                    let alert = alerts[i]
                                    let entity = NSEntityDescription.entity(forEntityName: "Sun_Data", in: context)
                                    let newEntry = NSManagedObject(entity: entity!, insertInto: context)
                                    newEntry.setValue(alert.uptime, forKey: "up")
                                    newEntry.setValue(alert.downtime, forKey: "down")
                                    newEntry.setValue(alert.warningtime, forKey: "warning")
                                    newEntry.setValue(alert.day, forKey: "day")
                                    newEntry.setValue(alert.month, forKey: "month")
                                    newEntry.setValue(alert.year, forKey: "year")
                                    
                                    
                                    newEntry.setValue(result, forKey: "place")
                                    
                                    // keep this as a set?
                                    //newEntry.setValue(NSSet(object: result), forKey: "place")
                                        
                                    do {
                                        try newEntry.managedObjectContext?.save()
                                    } catch {
                                        let saveError = error as NSError
                                        print(saveError)
                                    }
                                    i += 1
                                }
                                
                                performSegue(withIdentifier: "goToAlertsViewController", sender: self)
                            }
                        }
                    }
                }
            } else { print("No location matching lat and long in core data")}
        } catch { print("Could not get location results from Core Data")}
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true) // No need for semicolon
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
