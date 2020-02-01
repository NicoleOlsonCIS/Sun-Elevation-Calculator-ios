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

var time = ""
var userYear = ""
var userMonth = ""
var userDay = ""

class CityViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    var locationManager = CLLocationManager()
    
    @IBOutlet weak var c_city: UITextField!
    
    @IBOutlet weak var c_state: UITextField!
    
    @IBOutlet weak var c_country: UITextField!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var timeIintVar: UISegmentedControl!
    
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
        super.viewDidLoad()
        locationManager.delegate = self as CLLocationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation: CLLocation = locations[0]
        
        print(userLocation)
        
        userLocation.fetchCityAndCountry { city, country, error in
            guard let city = city, let country = country, error == nil else { return }
            print(city + ", " + country)
            self.c_city.text = city
            self.c_country.text = country
        }
    }
    
    @IBAction func getData_City(_ sender: Any)
    {
        var userCity = c_city.text!
        var userCountry = c_country.text!
        var userState = c_state.text!
        
        if userState == "" {userState = "None"}
        if time == "" {setInterval()}
        
        // if user did not edit date, set to default (current date)
        if userDay == "" { setDate()}
        
        // parse city, state and country, convert to proper format
        userCity = userCity.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)
        userCountry = userCountry.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)
        if userState != "None" { userState = userState.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)}
        
        let fullUrl = root2 + _year + userYear + and + _month + userMonth + and + _day + userDay + and + _city + userCity + and + _country + userCountry + and + _state + userState + and + _interval + time
        
        callBackend(fullUrl: fullUrl)
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
