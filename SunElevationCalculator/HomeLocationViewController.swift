//
//  HomeLocationViewController.swift
//  SunElevationCalculator
//
//  Created by Nicole Olson on 4/13/20.
//  Copyright © 2020 Nicole Olson. All rights reserved.
//

// ASYNC PROBLEMS




import UIKit
import CoreLocation
import CoreData
import MapKit
import UserNotifications
import Foundation

class HomeLocationViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate{

    var locationManager = CLLocationManager()
    var success = false
    var latitude = ""
    var longitude = ""
    var u_city = ""
    var dates = [[Int]]()
    var uptimes = [String]()
    var downtimes = [String]()
    var warningtimes = [String]()
    //var success = false
    
    @IBOutlet weak var city_input: UITextField!
    
    @IBOutlet weak var state_input: UITextField!
    
    @IBOutlet weak var country_input: UITextField!
    
    @IBOutlet weak var error_label: UILabel!
    
    @IBOutlet var label3: UILabel!
    
    @IBOutlet var label2: UILabel!
    
    @IBOutlet var label1: UILabel!
    
    @IBOutlet var title_label: UILabel!
    
    @IBOutlet var save_location: UIButton!
    
    @IBOutlet var sun_image: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getUserLocationFromCoreData()
        setAsPresets()
        error_label.text = ""
        
        // Do any additional setup after loading the view.
    }
    
   func getUserLocationFromCoreData()
   {
       let appDelegate = UIApplication.shared.delegate as! AppDelegate
       let context = appDelegate.persistentContainer.viewContext
       let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Current_Location")
       
       request.returnsObjectsAsFaults = false
       
       do
       {
           let results = try context.fetch(request)
           if results.count > 0
           {
               for result in results as! [NSManagedObject]
               {
                   if let city = result.value(forKey: "city") as? String { stored_city = city }
                   if let state = result.value(forKey: "state") as? String { current_state = state }
                   if let country = result.value(forKey: "country") as? String { current_country = country }
               }
           }
       } catch { print("Could not get results from Core Data in Location call")}
   }
   
   func setAsPresets()
   {
        city_input.text! = stored_city
        state_input.text! = current_state
        country_input.text! = current_country
   }

    // take the input in text boxes and save in Core Data under Location
    @IBAction func save_location(_ sender: Any)
    {

        var city = ""
        var state = ""
        var country = ""
        
        // get the input
        city = city_input.text!
        state = state_input.text!
        country = country_input.text!
        
        if state == "" {state = "None"}
        
        print("Saving location info: city: " + city + " state: " + state + " country: " + country)
        
        u_city = city
        
        if city == "" || country == ""
        {
            error_label.text = "Missing required fields"
            return
        }
        else { validateLocation(city: city, state: state, country: country) }

    }
    
    func processResponse()
    {
        setLocation(latitude: latitude, longitude: longitude, city: u_city)
        while success == false {sleep(1)}
        performSegue(withIdentifier: "goWait", sender: self)
    }
    
    
    func validateLocation(city: String, state: String, country: String)
    {
        print("Validating Location")
        var userState = ""
        let userCity = city.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)
        let userCountry = country.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)
        if state != "None" { userState = state.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)}
        else {userState = "None"}
        let call = "https://sun-elevation-compute.wn.r.appspot.com/location_validation?city=" + userCity + "&state=" + userState + "&country=" + userCountry
        
        if let url = URL(string: call)
        {
            let task = URLSession.shared.dataTask(with: url)
            {
                (data,response,error)in
                
                if error != nil { print("Error: Could not get results from server.") }
                else
                {
                    print("Calling backend!")
                    if let returnData = String(data: data!, encoding: .utf8)
                    {
                        //print("Called for up and downtime")
                        //self.parseData(data: returnData)
                        let result = returnData.components(separatedBy: "*")
                        print(returnData)
                        print("Parsing return")
                        
                        
                        if result.count > 1
                        {
                            // take out the slashes
                            var newresult1 = ""
                            var newresult2 = ""
                            
                            for r in result[0]
                            {
                                if r.isNumber || r == "-" || r == "."
                                {newresult1 = newresult1 + String(r)}
                            }
                            for r in result[1]
                            {
                                if r.isNumber || r == "-" || r == "."
                                {newresult2 = newresult2 + String(r)}
                            }
                            
                            if newresult1 == "400"
                            {
                                print("400 returned!")
                                self.error_label.text = "Location unfound. Please try again."
                            }
                            else
                            {
                                self.success = true
                                self.latitude = newresult1
                                self.longitude = newresult2
                                DispatchQueue.main.sync(execute: {
                                    print("DONE GETTING LOCATION DATA")
                                    //self.hideInputBoxes()
                                    //self.sun_image.setNeedsDisplay()
                                    self.processResponse()
                                })
                            }
                        }
                        else
                        {
                            print("Non-400 error")
                            self.error_label.text = "Server Error. Please try again."
                        }
                    }
                    else
                    {
                        print("ERROR IN LCCATION VALIDATION CALL")
                        DispatchQueue.main.sync(execute: {
                            self.error_label.text = "Server Error. Please try again."
                            print("Could not get coordinates for this location")
                            return
                        })
                    }
                }
            }
            task.resume() // starts the task apparently
        }
        else {print("WOULD NOT LET TASK WITH THE URL")}
    }

    // set the longitude and latitude values in the Location Entity in Core Data
    func setLocation(latitude: String, longitude: String, city: String)
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate //
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        //request.fetchLimit = 1
        
        do
        {
            let result = try context.fetch(request)
            
            let entities = ["latitude", "longitude", "city"]
            
            let values = [latitude, longitude, city]
            
            // if there is nothing saved for notifications then you have to create new entries in the
            // notification database.
            if result.count == 0
            {
                print("No records yet for the Location entity, creating new database entry")

                let newEntity = NSEntityDescription.insertNewObject(forEntityName: "Location", into: context) // Don't create multiple entities?
                
                newEntity.setValue(values[0], forKey: entities[0])
                newEntity.setValue(values[1], forKey: entities[1])
                newEntity.setValue(values[2], forKey: entities[2])
                
                let newPresetEntity = NSEntityDescription.insertNewObject(forEntityName: "Presets", into: context)
                newPresetEntity.setValue(false, forKey: "up_switch")
                newPresetEntity.setValue(false, forKey: "down_switch")
                newPresetEntity.setValue(false, forKey: "thirty_switch")
                
                newEntity.setValue(newPresetEntity, forKey: "switches")
                
                do {
                   try context.save()
                  } catch {
                   print("Failed at initializing Location settings")
                }
            }
            
            // otherwise, there is an entry already for the Location, have to change it
            else
            {
                let objectUpdate = result[0] as! NSManagedObject
                objectUpdate.setValue(values[0], forKey: entities[0])
                objectUpdate.setValue(values[1], forKey: entities[1])
                objectUpdate.setValue(values[2], forKey: entities[2])
                
                do {
                    try context.save()
                }
                catch
                {
                    print(error)
                }
                
            }
        }
        catch {print("Failed to retrieve record for Location entity")}
        
        print("Location default successfully updated!")
        success = true
        
        // hide everything on the page and enable a label that says "Sun data for your location being retreived. One moment ... "
        
    }
    
}

