//
//  LandingViewController.swift
//  SunElevationCalculator
//
//  Created by Nicole Olson on 1/20/20.
//  Copyright © 2020 Nicole Olson. All rights reserved.
//
//
//  When the app is launched, any "current location" in core data is deleted
//  When the user clicks any button, the page gets the users current location and
//  creates it in core data.
//  Each page that the buttons go to (except lat/long because these are efficient and uncomplicated by missing state data) are not segued until this data is created
//  When the new pages open, they don't need to do any API or Core Locaiton calls, they just need to consult Core Data
//  If User Location cannot be found for some reason, or the user declines permissions, the pre-populated fields are simply blank.
//
//  All ASYNC for named locaitons occurs on this page with manual segues occuring after completed (or, in the case that permission is denied).
//
//  Using Operation Queue to force sequentialism in the two API calls
//
//


import UIKit
import CoreLocation
import MapKit
import Foundation
import CoreData

//var locationIQAPIKEY = "530c2414a903dc"
//var geocodioAPIKEY = "641d65e0eeb7eb0b0eeb9d7795d4b66b7594115"

class LandingViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    var segueToName = ""
    var locationCompleted = false
    var locationManager = CLLocationManager()
    var latitude = ""
    var longitude = ""
    var city_g = ""
    var state = ""
    var country_g = ""
    var haveCalledAPI = false
    var segueAlreadyDone = false
    var widthMultiplier = 0.0
    var heightMultiplier = 0.0
    
    @IBOutlet var scrollview: UIScrollView!
    // button variables
    
    @IBOutlet var city_button: UIButton!
    @IBOutlet var coordinate_button: UIButton!
    @IBOutlet var alerts_button: UIButton!
    
    @IBAction func byNameSelected(_ sender: Any)
    {
        segueToName = "toCityViewController"
        
        locationManager.delegate = self as CLLocationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    @IBAction func getAlertsSelected(_ sender: Any)
    {
        segueToName = "getAlertsTransition"
        locationManager.delegate = self as CLLocationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    
    @IBAction func byCoordinatesSelected(_ sender: Any)
    {
        segueToName = "toLatLong"
        locationManager.delegate = self as CLLocationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        print("Getting user locations")
        
        let userLocation: CLLocation = locations[0]
        
        latitude = String(userLocation.coordinate.latitude)
        
        longitude = String(userLocation.coordinate.longitude)
        
        //print(userLocation)
        
        if segueToName == "toLatLong" {print("Transitioning now to lat long")}
        
        userLocation.fetchCityAndCountry { city, country, error in
        guard let city_n = city, let country_n = country, error == nil else { return }
        print(city_n)
        print(country_n)
        self.city_g = city_n
        self.country_g = country_n
        print("OPERATION 0 IS OVER")
            self.locationManager.stopUpdatingLocation()
        self.doNext()
        }
    
    }
    
    func doNext()
    {
        let operation1 = BlockOperation
        {
            print("Operation 1 is starting, calling API based on country")
                
            // https://api.geocod.io/v1.4/reverse?q=38.9002898,-76.9990361&api_key=YOUR_API_KEY
                
            let fullUrl = "https://api.geocod.io/v1.4/reverse?q=" + self.latitude + "," + self.longitude + "&api_key=" + geocodioAPIKEY
                
            print("FULL URL TO SEND " + fullUrl)
                
            var state_name = ""
                
            let sem = DispatchSemaphore(value: 0)
                
            if let url = URL(string: fullUrl)
            {
                let task = URLSession.shared.dataTask(with: url)
                {
                    (data,response,error)in defer { sem.signal() }
                        
                    if error != nil { print("Error: Could not get results from Location IQ.") }
                    else
                    {
                        print("Data task is complete, parsing now")
                            
                        if let returnData = String(data: data!, encoding: .utf8)
                        {
                            var returnArr = [String]()
                            for letter in returnData { returnArr.append(String(letter))}
                                
                                //print(returnData)
                                //print(returnArr)
                            let stop = returnArr.count - 6

                            for i in 0...stop
                            {
                                let one = returnArr[i]
                                let two = returnArr[i+1]
                                let three = returnArr[i+2]
                                let four = returnArr[i+3]
                                let five = returnArr[i+4]
                                let word = one + two + three + four + five
                                if word == "state"
                                {
                                    var j = i + 7
                                    while returnArr[j] != ","
                                    {
                                        state_name = state_name + returnArr[j]
                                        j = j + 1
                                    }
                                    break
                                }
                            }
                                       
                            state_name = state_name.replacingOccurrences(of: "\"", with: "")
                            print(state_name)
                            self.state = state_name
                            print("Operation 1 is finishing")
                            if state_name == "" {print("Error from API, no state to be found")}
                            // do Core Data Stuff
                                
                        }
                    }
                }
                task.resume()
                print("Dispatching semaphore")
                sem.wait()
            }
        }
        
        operation1.completionBlock = {
            print("Operation 1 completed")
        }
        
        //if self.locationCompleted == true {return}
        print("Adding operations")
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        queue.addOperation(operation1)
        //queue.addOperation(operation3)
        queue.waitUntilAllOperationsAreFinished()
        if city_g != "" {self.storeCurrentLocationInCoreData()}
        else {print("Did not have a value for city at the time of storing")}
        print("Done!")
        return
    }
    
    func needLocationName()
    {
        
    }
    
    // run when app starts, only 1 entity under current location ever
    func deleteCurrentLocationInCoreData()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Current_Location")
        request.returnsObjectsAsFaults = false
        
        if let result = try? context.fetch(request) {
            for object in result {
                context.delete(object as! NSManagedObject)
            }
        }
        
        do {
            try context.save()
            print("Current Location deleted")
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        } catch {
            print("Could not delete current location from core data")
        }
    }
    
    func storeCurrentLocationInCoreData()
    {
        print("Storing current location in core data")
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate //
        let context = appDelegate.persistentContainer.viewContext
            
        do
        {
            let entities = ["city", "state", "country", "latitude", "longitude"]
                
            let values = [city_g, state, country_g, latitude, longitude]
            
            print("Storing values ")
            print("CITY: " + city_g)
            print("STATE: " + state)
            print("COUNTRY: " + country_g)
            print("LATITUDE " + latitude)
            print("LONGITUDE " + longitude)
                
            let newEntity = NSEntityDescription.insertNewObject(forEntityName: "Current_Location", into: context) // Don't create multiple entities?
                    
            newEntity.setValue(values[0], forKey: entities[0])
            newEntity.setValue(values[1], forKey: entities[1])
            newEntity.setValue(values[2], forKey: entities[2])
            newEntity.setValue(values[3], forKey: entities[3])
            newEntity.setValue(values[4], forKey: entities[4])
                    
            do {
                try context.save()
                } catch {
                print("Failed at initializing Current Location settings")
            }
        }
        
        if segueAlreadyDone == false
        {
            segueAlreadyDone = true
            segueTo()
        }
    }
    
    func segueTo()
    {
        performSegue(withIdentifier: segueToName, sender: self)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        scrollview.contentSize = CGSize(width: self.view.frame.width, height: self.view.frame.height+400)
        scrollview.contentOffset.x = 0
        
        segueToName = ""
        // reset the result arrays BUG IN THIS STILL
        deleteCurrentLocationInCoreData()
        times_elevations.removeAll()
        color.removeAll()
        let c = Array(repeating: false, count: 288)
        color = c
        timeInterval = ""
        time = ""
        
    }
    
    
    
    
    
}
