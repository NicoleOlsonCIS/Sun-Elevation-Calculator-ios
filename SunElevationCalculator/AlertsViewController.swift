//
//  AlertsViewController.swift
//  SunElevationCalculator
//
//  Created by Nicole Olson on 4/6/20.
//  Copyright © 2020 Nicole Olson. All rights reserved.
//


// CURRENT BUGS
//
// Toggle switches are wrong when you change locations
// Should tie switch positins to location objects
//

import UIKit
import CoreLocation
import CoreData
import MapKit
import UserNotifications
import Foundation

var current_city = ""
var latitude = ""
var longitude = ""
var warning_state = Bool()
var up_state = Bool()
var down_state = Bool()
var alerts = [Alert]()

class Alert
{
    var day: Int
    var month: Int
    var year: Int
    var uptime: String
    var downtime: String
    var warningtime: String
    
    init(day: Int, month: Int, year: Int, uptime: String, downtime: String, warningtime: String)
    {
        self.day = day
        self.month = month
        self.year = year
        self.uptime = uptime
        self.downtime = downtime
        self.warningtime = warningtime
    }
}

class AlertsViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate{

    var dates = [[Int]]()
    var uptimes = [String]()
    var downtimes = [String]()
    var warningtimes = [String]()
    
    var locationManager = CLLocationManager()
    
    @IBOutlet weak var lat: UILabel!
    
    @IBOutlet weak var long: UILabel!
    
    @IBOutlet weak var alert_up: UISwitch!
    
    @IBOutlet weak var alert_down: UISwitch!
    
    @IBOutlet weak var alert_30min: UISwitch!
    
    @IBOutlet weak var textlview1: UITextView!
    
    @IBOutlet weak var textlview2: UITextView!
    
    @IBOutlet weak var textlview3: UITextView!
    
    @IBOutlet weak var location_label: UILabel!
    
    override func viewDidLoad() {

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let context = appDelegate.persistentContainer.viewContext
        
        super.viewDidLoad()
        
        getNotificationLocation()
        location_label.text = "Location: " + current_city
        let data_request = NSFetchRequest<NSFetchRequestResult>(entityName: "Sun_Data")
        
        data_request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(data_request)
            if results.count > 0 {
                for result in results as! [NSManagedObject]
                {
                    if let location = result.value(forKey: "place") as? NSManagedObject
                    {
                        if let lat = location.value(forKey: "latitude") as? String
                        {
                            if let lon = location.value(forKey: "longitude") as? String
                            {
                                if lat == latitude && lon == longitude
                                {
                                    print("Got sun times for " + current_city + " from core data!")
                                    if let uptime = result.value(forKey: "up") as? String
                                    {
                                        if let downtime = result.value(forKey: "down") as? String
                                        {
                                            if let warningtime = result.value(forKey: "warning") as? String
                                            {
                                                if let day = result.value(forKey: "day") as? Int
                                                {
                                                    if let month = result.value(forKey: "month") as? Int
                                                    {
                                                        if let year = result.value(forKey: "year") as? Int
                                                        {
                                                            let a = Alert(day: day, month: month, year: year, uptime: uptime, downtime: downtime, warningtime: warningtime)
                                                            alerts.append(a)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else { print("NO STORED SUN DATA ENTITIES FOR CURRENT LOCATION")}
        } catch { print("Could not get sun data from core data")}
    }
    
    // store the state of the switches when the submit button is clicked, so that in each case of
    // submitting we know if something has changed
    func saveState()
    {
        if alert_up.isOn {up_state = true}
        else {up_state = false}
        if alert_down.isOn {down_state = true}
        else {down_state = false}
        if alert_30min.isOn {warning_state = true}
        else {warning_state = false}
        
        // save them to the Location object
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    if let presets = result.value(forKey: "switches") as? NSManagedObject
                    {
                        if let up = presets.value(forKey: "up_switch") as? Bool
                        {
                            if up_state != up
                            {
                                presets.setValue(up_state, forKey: "up_switch")
                            }
                            
                            if let down = presets.value(forKey: "down_switch") as? Bool
                            {
                                if down_state != down
                                {
                                    presets.setValue(down_state, forKey: "down_switch")
                                }
                                if let thirty = presets.value(forKey: "thirty_switch") as? Bool
                                {
                                    if warning_state != thirty
                                    {
                                        presets.setValue(warning_state, forKey: "thirty_switch")
                                    }
                                }
                                do {
                                    try result.managedObjectContext?.save()
                                } catch {
                                    let saveError = error as NSError
                                    print(saveError)
                                }
                                break // only look at one location object
                            }
                        }
                    }
                    else
                    {
                        print("No preset relation for this location.")
                        break
                    }
                }
            }
            else { print("A")}
        } catch { print("B")}
    }
    
    func getNotificationLocation()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    if let city = result.value(forKey: "city") as? String { current_city = city }
                    if let lat = result.value(forKey: "latitude") as? String { latitude = lat }
                    if let long = result.value(forKey: "longitude") as? String { longitude = long }
                    if let presets = result.value(forKey: "switches") as? NSManagedObject
                    {
                        if let up = presets.value(forKey: "up_switch") as? Bool
                        {
                            if up == true
                            {
                                alert_up.setOn(true, animated: false)
                                up_state = true
                            }
                            else
                            {
                                up_state = false
                                // SET TO OFF?
                            }
                            
                            if let down = presets.value(forKey: "down_switch") as? Bool
                            {
                                if down == true
                                {
                                    alert_down.setOn(true, animated: false)
                                    down_state = true
                                }
                                    
                                else{down_state = false}
                                
                                if let thirty = presets.value(forKey: "thirty_switch") as? Bool
                                {
                                    if thirty == true
                                    {
                                        alert_30min.setOn(true, animated: false)
                                        warning_state = true
                                    }
                                    else{warning_state = false}
                                }
                                break
                            }
                        }
                    } else
                    {
                        print("No preset relation yet for this location.")
                        // set all to false
                        warning_state = false
                        up_state = false
                        down_state = false
                        alert_up.isOn = false
                        alert_down.isOn = false
                        alert_30min.isOn = false
                    }
                }
            } else
            {
                // THIS SHOULD NEVER HAPPEN YOU NEED A LOCATION TO GET TO THIS PAGE
                print("No Location city in Core Data")
            }
        } catch { print("Could not get results from Core Data in Location call")}
    }
    
    @IBAction func submitNotificationSettings(_ sender: Any)
    {
        var toDo = [String]()
        
        if alert_up.isOn { if up_state == false { toDo.append("A") } }
        else { if up_state == true { toDo.append("B") } }
        if alert_down.isOn { if down_state == false { toDo.append("C") } }
        else { if down_state == true { toDo.append("D") } }
        if alert_30min.isOn { if warning_state == false { toDo.append("E") } }
        else { if warning_state == true { toDo.append("F") } }
        toDo.append("G")
        if toDo.count > 0 {doNext(toDo: toDo)}
        
    }
   
    func doNext(toDo: [String])
    {
        var toDo = toDo
        
        if toDo.count > 0
        {
            switch toDo[0] {
            case "A":
                toDo.removeFirst()
                print("On to task A")
                A(toDo: toDo)
            case "B":
                toDo.removeFirst()
                print("On to task B")
                B(toDo: toDo)
            case "C":
                toDo.removeFirst()
                print("On to task C")
                C(toDo: toDo)
            case "D":
                toDo.removeFirst()
                print("On to task D")
                D(toDo: toDo)
            case "E":
                toDo.removeFirst()
                print("On to task E")
                E(toDo: toDo)
            case "F":
                toDo.removeFirst()
                print("On to task F")
                F(toDo: toDo)
            case "G":
                toDo.removeFirst()
                print("On to task G")
                G(toDo: toDo)
            default:
                print("No cases match in switch statement")
            }
        }
    }
    
    
    func A(toDo: [String])
    {
        pullOrSeekNotificationData(type: "Up_Notification", toDo: toDo)
        establishOrUpdateCoreDataPresets(entity: "Presets", key: "up_switch", newvalue: true, toDo: toDo)
    }
    
    func B(toDo: [String])
    {
        clearNotiications(type: "Up_Notification", toDo: toDo)
        establishOrUpdateCoreDataPresets(entity: "Presets", key: "up_switch", newvalue: false, toDo: toDo)
    }
    
    func C(toDo: [String])
    {
        pullOrSeekNotificationData(type: "Down_Notification", toDo: toDo)
        establishOrUpdateCoreDataPresets(entity: "Presets", key: "down_switch", newvalue: true, toDo: toDo)
    }
    
    func D(toDo: [String])
    {
        clearNotiications(type: "Down_Notification", toDo: toDo)
        establishOrUpdateCoreDataPresets(entity: "Presets", key: "down_switch", newvalue: false, toDo: toDo)
    }
    
    func E(toDo: [String])
    {
        pullOrSeekNotificationData(type: "Warning_Notification", toDo: toDo)
        establishOrUpdateCoreDataPresets(entity: "Presets", key: "thirty_switch", newvalue: true, toDo: toDo)
    }
    
    func F(toDo: [String])
    {
        clearNotiications(type: "Warning_Notification", toDo: toDo)
        establishOrUpdateCoreDataPresets(entity: "Presets", key: "thirty_switch", newvalue: false, toDo: toDo)
    }
    
    func G(toDo: [String])
    {
        saveState()
    }
    
    
    func getElevationData(type: String, toDo: [String])
    {
        while latitude == "" || longitude == ""
        {
            sleep(0)
            print("No latitude or longitude data")
        } // TEMPORARY EXPERIMENT
        let call = "https://sun-elevation-compute.wn.r.appspot.com/bulk?year=2020&lat=" + String(latitude) + "&long=" + String(longitude)
        print("CALLING BACKEND!")
        return callBackend(fullUrl: call, type: type, toDo: toDo)
    }
    
    func callBackend(fullUrl: String, type: String, toDo: [String])
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
                            self.parseData(data:returnData, type: type, toDo: toDo)
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
        }
    }
    
    func parseData(data: String, type: String, toDo: [String])
    {
        print("Parsing Data!")
        //print(data)
        let parts = data.components(separatedBy: ", ")
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
        storeSunData(toDo: toDo)
        createNotifications(type: type, toDo: toDo)
    }
    
    func storeSunData(toDo: [String])
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
                            }
                        }
                    }
                }
            } else { print("No location matching lat and long in core data")}
        } catch { print("Could not get location results from Core Data")}
    }

    func pullOrSeekNotificationData(type: String, toDo: [String])
    {
        if alerts.count != 0
        {
            print("DO NOT HAVE TO CALL BACKEND, POPULATED ALERT DATA FROM CORE DATA!")
            createNotifications(type: type, toDo: toDo)
        }
        else if alerts.count == 0
        {
            print("NO CORE DATA FOR THIS PLACE, CALLING BACKEND TO GET DATA!")
            getElevationData(type: type, toDo: toDo)
        }
    }
    
    
    func createNotifications(type: String, toDo: [String])
    {
        var requests = [String]() // uuid string for Core Data storage
        
        if alerts.count > 0
        {
            var i = 0
            
            if type == "Up_Notification"
            {
                while i < alerts.count
                {
                    let alert = alerts[i]
                    let date = [alert.day, alert.month, alert.year]
                    
                    let id = createNotification(date: date, time: alert.uptime, alert_message_title: "UVB Alert", alert_message_body: "Sun is now 50 degrees above horizon!", toDo: toDo)
                    if id != "0" {requests.append(id)}
                    i += 1
                }
                if requests.count > 0 {saveNotifications(notifications: requests, type: "Up_Notification", toDo: toDo)}
            }
            else if type == "Down_Notification"
            {
                while i < alerts.count
                {
                    let alert = alerts[i]
                    let date = [alert.day, alert.month, alert.year]
                    let id = createNotification(date: date, time: alert.downtime, alert_message_title: "UVB Alert:", alert_message_body: "Sun is no longer 50 degrees above horizon!", toDo: toDo)
                    if id != "0" {requests.append(id)}
                    i += 1
                }
                if requests.count > 0 {saveNotifications(notifications: requests, type: "Down_Notification", toDo: toDo)}
            }
            else if type == "Warning_Notification"
            {
                while i < alerts.count
                {
                    let alert = alerts[i]
                    let date = [alert.day, alert.month, alert.year]
                    let id = createNotification(date: date, time: alert.warningtime, alert_message_title: "UVB Alert:", alert_message_body: "In 30 min sun will be 50 degrees above horizon!", toDo: toDo)
                    if id != "0" {requests.append(id)}
                    i += 1
                }
                if requests.count > 0 {saveNotifications(notifications: requests, type: "Warning_Notification", toDo: toDo)}
            }
        }
        else {print("Timeout in server call, no notifications created.")}
        
        if toDo.count > 0 { doNext(toDo: toDo) }
        
    }
    
    func createNotification(date: [Int], time: String, alert_message_title: String, alert_message_body: String, toDo: [String]) -> String
    {
        var h = ""
        var m = ""
        let center = UNUserNotificationCenter.current()
                  
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in}
                  
        let content = UNMutableNotificationContent()
        content.title = alert_message_title
        content.body = alert_message_body
           
        let times = time.components(separatedBy: ":")
        if times.count > 1 // if it's not a "0" in the time position
        {
            h = times[0]
            m = times[1]
        }
        else { return "0"}
           
        let hour = Int(h)
        let min = Int(m)
    
        var dateComponents = DateComponents()

        dateComponents.year = date[2]
        dateComponents.month = date[1]
        dateComponents.day = date[0]
        dateComponents.hour = hour
        dateComponents.minute = min
                  
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                  
        let uuidString = UUID().uuidString
                  
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
                  
        center.add(request) { (error) in
            if error != nil {print("Error in creating notification")}
        }
           
        return uuidString
    }
    
    // gets the string IDs for a particular type of notication in core data which refer to alerts and clears them
    func clearNotiications(type: String, toDo: [String])
    {
        var notfications = [String]()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: type)
        
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    if let notification_string = result.value(forKey: "id") as? String {
            
                        notfications.append(notification_string)
                    }
                }
            } else { print("No " + type + " in core data")}
        } catch { print("Could not get results from Core Data")}
        
        // remove one by one using string identifier
        if notfications.count > 0 { for n in notfications {removeNotification(request: n)}}
        removeNotificationIDS(type: type)
        
        if toDo.count > 0 {doNext(toDo: toDo)}
    }
    
    // From: https://gist.github.com/quocnb/c09e76abcad8419d0fc46af4abc9146e
    func removeNotification(request: String)
    {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request])
        print("Notification with identifier " + request + " has been removed!")
    }
    
    func removeNotificationIDS(type: String)
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: type)
        request.returnsObjectsAsFaults = false
        
        if let result = try? context.fetch(request) {
            for object in result {
                context.delete(object as! NSManagedObject)
            }
        }
        
        do {
            try context.save()
            print("TABLEVIEW-EDIT: saved!")
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        } catch {
            print("catch in removing Notrifications id strings")
        }
    }
    
    // save notifications to Core Data so they can be cancelled if the user toggles to off
    // saves as either "uptime notifications" or "downtime notifications" or "thirtymin_notifications" as the key.
    // saves an array of type "UNNotificationRequest"
    func saveNotifications(notifications: [String], type: String, toDo: [String])
    {
        for notification in notifications
        {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: type, in: context)
            let newEntry = NSManagedObject(entity: entity!, insertInto: context)
            newEntry.setValue(notification, forKey: "id")
            do {
               try context.save()
              } catch {
               print("Failed saving " + type + " notificiation")
            }
        }
        
        print("Notifications Saved!")
    }
    
    // get the presets under "Presets" in core data. When the user flips a switch, the notifications are either created or cancelled, but
    // also the switch state is saved in core data so that the setting reflects the state of notifications on subsequent views of the alerts page.
    func establishOrUpdateCoreDataPresets(entity: String, key: String, newvalue: Bool, toDo: [String])
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate //
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        request.fetchLimit = 1
        //request.predicate = NSPredicate(format: key + " = %@", "true")
        
        do{
            let result = try context.fetch(request)
            
            // if there is nothing saved for notifications then you have to create new entries in the
            // notification database.
            if result.count == 0
            {
                print("No records yet for the Presets entity, creating new database entry")
                
                let entities = ["up_switch", "down_switch", "thirty_switch"]
                
                var values = [Bool]()
                
                if key == "up_switch" {values = [true, false, false]}

                else if key == "down_switch" {values = [false, true, false]}

                else if key == "thirty_switch" {values = [false, false, true]}

                let newEntity = NSEntityDescription.insertNewObject(forEntityName: "Presets", into: context) // Don't create multiple entities?
                
                var i = 0
                while i < 3
                {
                    newEntity.setValue(values[i], forKey: entities[i])
                    i += 1
                    do {
                       try context.save()
                      } catch {
                       print("Failed at initializing switch settings")
                    }
                    
                }
            }
            
            // otherwise, there is an entry already for the switches (in the "Presets" database of Core Data)
            // so it is safe to get that exact one and update it
            else
            {
                print("The results to update are: ")
                var i = 0
                for r in result
                {
                    print(String(i))
                    print(r)
                    print("\n\n")
                    i = i + 1
                }
                let objectUpdate = result[0] as! NSManagedObject
                objectUpdate.setValue(newvalue, forKey: key)
                do {
                    try context.save()
                }
                catch
                {
                    print(error)
                }
            }
        }
        catch {print("Failed to retrieve record for " + key)}
        
        print("Switch default successfully updated!")
    }
    
    
    /*
    // TESTING FUNCTIONS
    func test()
    {
        let center = UNUserNotificationCenter.current()
               
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in}
               
        let content = UNMutableNotificationContent()
        content.title = "Alert title"
        content.body = "Alert Body"
        
        let date = Date().addingTimeInterval(10)
                      
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
               
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
               
        let uuidString = UUID().uuidString
               
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
               
        center.add(request) { (error) in if error != nil {print("ERROR IN TEST FUNCTION 1")}}
        
        //testCancelSingle(id: uuidString)
    }
    
    func testCancelSingle(id: String)
    {
        removeNotification(request: id)
    }
    
    func testNotificationRemoval()
    {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests(completionHandler: { requests in
            for request in requests {
                print(request)
            }
            
            if requests.count == 0 {print("THERE ARE NO REQUESTS")}
        })
    }
}

// called when user hits "back" button to leave the alert page
 // stored in CoreData so that next time the application is open these values can be set to the default
 /*
 func saveAlertPreferences(up: Bool, down: Bool, interval: String)
 {
     
     let appDelegate = UIApplication.shared.delegate as! AppDelegate // UIApplication.shared().delegate as! AppDelegate is now UIApplication.shared.delegate as! AppDelegate
     
     let context = appDelegate.persistentContainer.viewContext
     
     var newEntity = NSEntityDescription.insertNewObject(forEntityName: "Presets", into: context)
     
     newEntity.setValue(up, forKey: "up_switch")
     
     do {
        try context.save()
       } catch {
        print("Failed saving up switch setting.")
     }
     
     newEntity = NSEntityDescription.insertNewObject(forEntityName: "Presets", into: context)
     
     newEntity.setValue(down, forKey: "down_switch")
     
     do {
        try context.save()
       } catch {
        print("Failed saving down switch setting.")
     }
     
     newEntity = NSEntityDescription.insertNewObject(forEntityName: "Presets", into: context)
     
     newEntity.setValue(interval, forKey: "interval")
     
     do {
        try context.save()
       } catch {
        print("Failed saving interval_up setting.")
     }
 }*/
 
 /*
 func saveUpPreference(up: Bool)
 {
     let appDelegate = UIApplication.shared.delegate as! AppDelegate // UIApplication.shared().delegate as! AppDelegate is now UIApplication.shared.delegate as! AppDelegate
     
     let context = appDelegate.persistentContainer.viewContext
     // fetch the value
     let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Presets")
     //request.predicate = NSPredicate(format: "age = %@", "12")
     request.returnsObjectsAsFaults = false
     do {
         let result = try context.fetch(request)
         for data in result as! [NSManagedObject]
         {
             if case let data.value(forKey: "up_switch") as! Bool
             {
                 print("Saved value for up_switch!")
             }
         }
         
     } catch {
         
         print("Failed to fetch up_switch value")
     }
 }
 */
 /*
 func saveDownPreference(down: Bool)
 {
     let appDelegate = UIApplication.shared.delegate as! AppDelegate // UIApplication.shared().delegate as! AppDelegate is now UIApplication.shared.delegate as! AppDelegate
     
     let context = appDelegate.persistentContainer.viewContext
     
     let newEntity = NSEntityDescription.insertNewObject(forEntityName: "Presets", into: context)
     
     newEntity.setValue(down, forKey: "down_switch")
     
     do {
        try context.save()
       } catch {
        print("Failed saving down switch setting.")
     }
 
 
 func saveIntervalPreference(interval: String)
 {
     let appDelegate = UIApplication.shared.delegate as! AppDelegate // UIApplication.shared().delegate as! AppDelegate is now UIApplication.shared.delegate as! AppDelegate
     
     let context = appDelegate.persistentContainer.viewContext
     
     let newEntity = NSEntityDescription.insertNewObject(forEntityName: "Presets", into: context)
         
     newEntity.setValue(interval, forKey: "interval")
         
     do {
         try context.save()
         } catch {
         print("Failed saving interval_up setting.")
     }
 }
 
 @IBAction func setAlertUp(_ sender: Any)
    {
        if alert_up.isOn
        {
            alert_up.setOn(true, animated: false)
            createNotifications(type: "up")
            //storeLocationOfNotification(key: "up_city", city: current_city)
            establishOrUpdateCoreDataPresets(entity: "Presets", key: "up_switch", newvalue: true)
        }
        else
        {
            alert_up.setOn(false, animated: false)
            clearNotiications(type: "up")
            establishOrUpdateCoreDataPresets(entity: "Presets", key: "up_switch", newvalue: false)
        }
    }
    
    @IBAction func setAlertDown(_ sender: Any)
    {
        if alert_down.isOn
        {
            alert_down.setOn(true, animated: false)
            createNotifications(type: "down")
            //storeLocationOfNotification(key: "down_city", city: current_city)
            establishOrUpdateCoreDataPresets(entity: "Presets", key: "down_switch", newvalue: true)
        }
        else
        {
            alert_down.setOn(false, animated: false)
            clearNotiications(type: "down")
            establishOrUpdateCoreDataPresets(entity: "Presets", key: "down_switch", newvalue: false)
        }
    }

    @IBAction func set30MinAlert(_ sender: Any)
    {
        if alert_30min.isOn
        {
            alert_30min.setOn(true, animated: false)
            createNotifications(type: "thirtymin")
            //storeLocationOfNotification(key: "warning_city", city: current_city)
            establishOrUpdateCoreDataPresets(entity: "Presets", key: "thirty_switch", newvalue: true)
        }
        else
        {
            alert_30min.setOn(false, animated: false)
            clearNotiications(type: "thirtymin")
            establishOrUpdateCoreDataPresets(entity: "Presets", key: "thirty_switch", newvalue: false)
        }
    }
    
 
 // returns locations in the order up_city, down_city, warning_city
 /*
 func getNotificationLocations() -> [String]
 {
     let keys = ["up_city", "down_city", "warning_city"]
     
     var places = [String]()
     
     let appDelegate = UIApplication.shared.delegate as! AppDelegate
     let context = appDelegate.persistentContainer.viewContext
     let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Locations")
     
     request.returnsObjectsAsFaults = false
     
     do {
         let results = try context.fetch(request)
         var i = 0
         if results.count > 0 {
             for result in results as! [NSManagedObject] {
                 if let place_string = result.value(forKey: keys[i]) as? String {
         
                     places.append(place_string)
                     i = i + 1
                 }
             }
         }
         else { return places }
         
     } catch { print("Could not get results from Core Data")}
     
     return places
 }*/

 // store the location the user is getting notifications about
 // up_city, down_city, warning_city
 /*
 func storeLocationOfNotification(key: String, city: String)
 {
     let appDelegate = UIApplication.shared.delegate as! AppDelegate //
     let context = appDelegate.persistentContainer.viewContext
     let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Locations")
     request.fetchLimit = 1
            //request.predicate = NSPredicate(format: key + " = %@", "true")
            
     do{
         let result = try context.fetch(request)
                
         // if there is nothing saved for Location then you have to create new entries in the
         // notification database.
         // we label the same city for all so they can just be updated in the future
         if result.count == 0
         {
             print("No records yet for the Location entity, creating new database entry")
                  
             let keys = ["up_city", "down_city", "warning_city"]
             
             var i = 0
             
             let newEntity = NSEntityDescription.insertNewObject(forEntityName: "Locations", into: context)
             while i < 3
             {
                 //let newEntity = NSEntityDescription.insertNewObject(forEntityName: "Locations", into: context)
                 newEntity.setValue(city, forKey: keys[i])
                 i += 1
                 do {
                     try context.save()
                     } catch {
                         print("Failed at initializing Location settings")
                     }
             }
                                    
         }
         // otherwise, there is an entry already for the Locations entity of Core Data)
         // so it is safe to get that exact one and update it
         else
         {
             print("The results to update are: ")
             var i = 0
             for r in result
             {
                 print(String(i))
                 print(r)
                 print("\n\n")
                 i = i + 1
             }
             let objectUpdate = result[0] as! NSManagedObject
             objectUpdate.setValue(city, forKey: key)
             do {
                  try context.save()
                }
                 catch
                 {
                     print(error)
                 }
             }
         }
         catch {print("Failed to retrieve record for " + key)}
 }
 */
 
 // No more serializing because decoding was causing issues
 /*
 // https://stackoverflow.com/questions/28325268/convert-array-to-json-string-in-swift
 func json(from object:Any) -> String?
 {
     guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
         return nil
     }
     return String(data: data, encoding: String.Encoding.utf8)
 }
 */
 
 let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
 
 /*let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Presets")
 
 request.returnsObjectsAsFaults = false
 
 do {
     let results = try context.fetch(request)
     if results.count > 0 {
         for result in results as! [NSManagedObject] {
             if let up_bool = result.value(forKey: "up_switch") as? Bool {
                 
                 if up_bool == true
                 {
                     alert_up.setOn(true, animated: false)
                     up_state = true
                 } // switch to on
                 else{up_state = false}
             }
         }
     } else { print("No up_switch data in core data, notifications have not been set")}
 } catch { print("Could not get up_switch results from Core Data")}
 
 do {
     let results = try context.fetch(request)
     if results.count > 0 {
         for result in results as! [NSManagedObject] {
             if let down_bool = result.value(forKey: "down_switch") as? Bool {
     
                 if down_bool == true
                 {
                     alert_down.setOn(true, animated: false)
                     down_state = true
                 } // switch to on
                 else{down_state = false}
             }
         }
     } else { print("No down_switch data in core data, notifications have not been set")}
 } catch { print("Could not get down_switch results from Core Data")}
 
 do {
     let results = try context.fetch(request)
     if results.count > 0 {
         for result in results as! [NSManagedObject] {
             if let thirty_bool = result.value(forKey: "thirty_switch") as? Bool {
     
                 if thirty_bool == true
                 {
                     alert_30min.setOn(true, animated: false)
                     warning_state = true
                 }
                 else{warning_state = false}
             }
         }
     } else { print("No 30 min data in core data")}
 } catch { print("Could not get 30 min results from Core Data")} */
 
 // if they are all off then segue back
 /*if alert_up.isOn == false && alert_down.isOn  == false && alert_30min.isOn == false
 {

     
     print("No notification settings, removing location from Core Data")
     // delete location from Core Data
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
                 // delete the lcoaiton entity
             }
             
         } else { print("No Location city in Core Data")}
     } catch { print("Could not get results from Core Data in Location call")}
 }*/
 
 
 
 
 }*/
 */
}
