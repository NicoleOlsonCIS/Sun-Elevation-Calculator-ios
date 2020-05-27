//
//  CityViewController.swift
//  SunElevationCalculator
//
//  Created by Nicole Olson on 1/20/20.
//  Copyright © 2020 Nicole Olson. All rights reserved.
//
import UIKit
import CoreLocation
import MapKit
import CoreData

var time = ""
var userYear = ""
var userMonth = ""
var userDay = ""
var stored_city = ""
var current_state = ""
var current_country = ""
var locationIQAPIKEY = "530c2414a903dc"
var geocodioAPIKEY = "641d65e0eeb7eb0b0eeb9d7795d4b66b7594115"


class CityViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    var locationManager = CLLocationManager()
    
    @IBOutlet weak var c_city: UITextField!
    
    @IBOutlet weak var c_state: UITextField!
    
    @IBOutlet weak var c_country: UITextField!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var timeIintVar: UISegmentedControl!
    
    @IBOutlet var errorLabel: UILabel!
    
    @IBOutlet var scrollView: UIScrollView!
    
    
    @IBAction func datePickerChange(_ sender: Any)
    {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let selectedDate: String = dateFormatter.string(from: (sender as AnyObject).date)
        let components = selectedDate.components(separatedBy: "/")
        print(components)
        userMonth = components[0]
        userDay = components[1]
        userYear = components[2]
    }
    
    @IBAction func timeIntervalChange(_ sender: Any)
    {
        if (sender as AnyObject).selectedSegmentIndex == 0 { time = "5"}
        else if (sender as AnyObject).selectedSegmentIndex == 1 { time = "15"}
        else if (sender as AnyObject).selectedSegmentIndex == 2 { time = "30"}
        else if (sender as AnyObject).selectedSegmentIndex == 3 { time = "60" }
    }
    
    override func viewDidLoad() {

        // set the color of the date picker
        datePicker.setValue(UIColor.white, forKey: "textColor")
        datePicker.setValue(UIColor.black, forKey: "backgroundColor")
        scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.view.frame.height+80)
        scrollView.contentOffset.x = 0
        
        
        
        
        // get user location from core data
        getUserLocationFromCoreData()
        setAsPresets() // will set to nothing if the location retrieval fails
        super.viewDidLoad()
        
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
        c_city.text! = stored_city
        c_state.text! = current_state
        c_country.text! = current_country
    }
    
    
    @IBAction func getData_City(_ sender: Any)
    {
        var userCity = c_city.text!
        var userCountry = c_country.text!
        var userState = c_state.text!
        
        if userState == ""
        {
            print("Missing state")
            missingData(type: "state/prov")
            //self.view.setNeedsDisplay()
        }
        if userCity == ""
        {
            print("Missing city")
            missingData(type: "city")
            //self.view.setNeedsDisplay()
        }
        if userCountry == ""
        {
            print("Missing country")
            missingData(type: "country")
            //self.view.setNeedsDisplay()
        }
        
        if userState != "" && userCity != "" && userCountry != ""
        {
            print("All fields entered")
            if time == "" {setInterval()}
                
            // if user did not edit date, set to default (current date)
            if userDay == "" { setDate()}
                
            // parse city, state and country, convert to proper format
            userCity = userCity.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)
            userCountry = userCountry.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)
            userState = userState.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)
            
            //if userState != "None" { userState = userState.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)}
                
            let fullUrl = root2 + _year + userYear + and + _month + userMonth + and + _day + userDay + and + _city + userCity + and + _country + userCountry + and + _state + userState + and + _interval + time
                
            callBackend(fullUrl: fullUrl)
        }
        
        print("Return from IBAction")
    }
    
    func missingData(type: String)
    {
        errorLabel.text = "Missing fields"
    }
    
    
    func callBackend(fullUrl: String)
    {
        if let url = URL(string: fullUrl)
        {
            let task = URLSession.shared.dataTask(with: url)
            {
                (data,response,error)in
                
                if error != nil { print("Error: Could not get results from server.") }
                else { if let returnData = String(data: data!, encoding: .utf8)
                {
                    if checkResponse(content: returnData) { times_elevations = formatResponse(content: returnData, time_start: time)} }
                    else {print("Server Error")}
                }
            }
            task.resume()
        }
    }
    
}


func setInterval(){ time = "5" }
func setDate()
{
    let date = Date()
    let format = DateFormatter()
    format.dateFormat = "yyyy-MM-dd"
    let formattedDate = format.string(from: date)
    
    let components = formattedDate.components(separatedBy: "-")
    userYear = components[0]
    userMonth = components[1]
    userDay = components[2]
}

