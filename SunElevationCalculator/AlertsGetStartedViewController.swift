//
//  AlertsGetStartedViewController.swift
//  SunElevationCalculator
//
//  Created by Nicole Olson on 4/13/20.
//  Copyright © 2020 Nicole Olson. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import MapKit
import UserNotifications
import Foundation

class AlertsGetStartedViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate
{
    //available segues
    //toNotificationEditor
    //toLocationSetter
    
    
    @IBOutlet var instruction_label: UILabel!
    
    @IBOutlet var top_button: UIButton!
    
    @IBOutlet var bottom_button: UIButton!
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Check if a location is set
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        
        request.returnsObjectsAsFaults = false
        
        do
        {
            let results = try context.fetch(request)
            if results.count > 0
            {
                // there is a locaiton entity
                top_button.setTitle("Add/Edit Notifications", for: [])
                top_button.setTitleColor(UIColor.white, for: [])
                top_button.backgroundColor = UIColor.red
                instruction_label.text = ""
                
                // enable the second button
                bottom_button.isEnabled = true
                bottom_button.setTitle("Reset Location", for: [])
                bottom_button.setTitleColor(UIColor.white, for: [])
                bottom_button.backgroundColor = UIColor.green
                
                for result in results as! [NSManagedObject]
                {
                    if let location = result.value(forKey: "city") as? String { instruction_label.text = "Location: " + location }
                    else { instruction_label.text = "Error" }
                    break
                }
            }
            else
            {
                // no location entity, leave the label as is
                bottom_button.isEnabled = false
                bottom_button.setTitleColor(UIColor.gray, for: [])
                instruction_label.text = "Start by setting a location"
                
            }
        } catch { print("Catch on fetching Location entity")}
    }

    @IBAction func top_button_selected(_ sender: Any)
    {
        if top_button.currentTitle == "Add/Edit Notifications"
        {
            // segue to notification editor
            performSegue(withIdentifier: "toNotificationEditor", sender: self)
        }
        else
        {
            // segue to location setter
            performSegue(withIdentifier: "toLocationSetter", sender: self)
        }
    }
    @IBAction func bottom_button_selected(_ sender: Any)
    {
        clearLocation()
        clearAllNotifications()
        clearPresets()
        clearSun_Data()
        print("CLEARING EVERYTHING!")
        
        top_button.setTitle("Set Location", for: [])
        top_button.setTitleColor(UIColor.white, for: [])
        top_button.backgroundColor = UIColor.blue
        
        // set buttons back to starting configuration
        bottom_button.isEnabled = false
        bottom_button.setTitleColor(UIColor.white, for: [])
        bottom_button.backgroundColor = UIColor.gray
        instruction_label.text = "Start by setting a location"
        
    }

    func clearLocation()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        request.returnsObjectsAsFaults = false
        
        if let result = try? context.fetch(request) {
            for object in result {
                context.delete(object as! NSManagedObject)
            }
        }
        
        do {
            try context.save()
            print("Locaitons Deleted")
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        } catch {
            print("Could not delete locations")
        }
    }
    
    func clearAllNotifications()
    {
        var notfications = [String]()
        
        let type = ["Up_Notification", "Down_Notification", "Warning_Notification"]
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        var i = 0
        while i < type.count
        {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: type[i])
               
            request.returnsObjectsAsFaults = false
               
            do {
                let results = try context.fetch(request)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let notification_string = result.value(forKey: "id") as? String {
                   
                            notfications.append(notification_string)
                        }
                    }
                } else { print("No " + type[i] + " in core data")}
            } catch { print("Could not get results from Core Data")}
        
            // remove one by one using string identifier
            if notfications.count > 0 { for n in notfications {removeNotification(request: n)}}
            removeNotificationIDS(type: type[i])
            i += 1
        }
    }
    
    func clearPresets()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Presets")
        request.returnsObjectsAsFaults = false
        
        if let result = try? context.fetch(request) {
            for object in result {
                context.delete(object as! NSManagedObject)
            }
        }
        
        do {
            try context.save()
            print("Presets deleted")
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        } catch {
            print("Could not delete presets")
        }
    }
    
    func clearSun_Data()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Sun_Data")
        request.returnsObjectsAsFaults = false
        
        if let result = try? context.fetch(request) {
            for object in result {
                context.delete(object as! NSManagedObject)
            }
        }
        
        do {
            try context.save()
            print("Sun Data Cleared")
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        } catch {
            print("Could not delete presets")
        }
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
            print("removed notification IDS")
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        } catch {
            print("catch in removing Notrifications id strings")
        }
    }
    
    
    //@IBAction func top_button(_ sender: Any)
    //{
        // check the label on the button and segue accordingly
        //toNotificationEditor
           //toLocationSetter
    //}
    
    
 
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
