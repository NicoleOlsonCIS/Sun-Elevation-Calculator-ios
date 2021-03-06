//
//  ViewController.swift
//  SunElevationCalculator
//
//  Created by Nicole Olson on 11/26/19.
//  Copyright © 2019 Nicole Olson. All rights reserved.
//

// HOW TO DO AUTOLAYOUT AND SCROLLVIEWS AND OTHER TIPS ON LAYOUT

// put stuff inside another view (UIVIEW) that you want to move together. Align the things inside to the view. Then you can put that ivew in different places for different layouts.
// Click "vary by traits" in bottom right
// iPhone 8, iPhone 11 horizontal, and iPad (either) all need to be set, as those will catch the three variations
// To do scroll view: https://stackoverflow.com/questions/36028493/add-a-scrollview-to-existing-view Note that you can set the size of scroll view per Width-Height configuration (vary by traits)
// Make sure to add heights and widths to things first before alignment where relevant, as the alignment settings will change dimensions of some things (like buttons, labels, etc)
// Control drag to do the "leading space to container" type thing
// Side note: setting something called "Equal Widths" with the above control drag is what allows things to be readjusted in terms of width or hiegth when the screen size changes. I didn't utilize this this time.
// Note: If an thing keeps trying to align itself with something far away, it's possible that you need to move where it is in the left panel (the list of all things on the page)
// Another note (this time about transitions): you need to "present modally" "full screen" or else you get an overlay thing with transitions/manual segues
// I couoldn't figure out how to change font size for screen size. I could try to do this for the next version.

// REMAINING BUGS
// Handle New Foundland bug (30 min offset timezone issue)


import UIKit
import CoreLocation
import MapKit
import CoreData

// global variables
var times_elevations = [String]()
var color = Array(repeating: false, count: 288)
var complete = false

var timeInterval = ""
var day = ""
var month = ""
var year = ""
let root = "https://sun-elevation-compute.wn.r.appspot.com/sun?"
let root2 = "https://sun-elevation-compute.wn.r.appspot.com/sun_address?"
let _year = "year="
let _month = "month="
let _day = "day="
let _second = "second="
let _lat = "lat="
let _long = "long="
let _address = "address="
let _city = "city="
let _state = "state="
let _country = "country="
let and = "&"
let _interval = "interval="
var r_latitude = ""
var r_longitude = ""

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var locationManager = CLLocationManager() // get the user's location
    
    @IBOutlet weak var lat: UITextField!
    
    @IBOutlet weak var long: UITextField!

    @IBOutlet weak var date: UIDatePicker!
    
    @IBOutlet weak var interval: UISegmentedControl!
    
    @IBOutlet var scrollView: UIScrollView!
    
    @IBAction func getDate(_ sender: Any)
    {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let selectedDate: String = dateFormatter.string(from: (sender as AnyObject).date)
        let components = selectedDate.components(separatedBy: "/") 
        print(components)
        month = components[0]
        day = components[1]
        year = components[2]
    }
    
    @IBAction func getInterval(_ sender: Any)
    {
        if (sender as AnyObject).selectedSegmentIndex == 0 { timeInterval = "5" }
        else if (sender as AnyObject).selectedSegmentIndex == 1 { timeInterval = "15" }
        else if (sender as AnyObject).selectedSegmentIndex == 2 { timeInterval = "30" }
        else if (sender as AnyObject).selectedSegmentIndex == 3 { timeInterval = "60"}
    }
    
    @IBAction func getData_Coordinates(_ sender: Any)
    {
        let userLat = lat.text!
        let userLong = long.text!
        
        /* This just froze the program, could be a threading issue. Maybe try to add this feature back later
        if let floatlat = Float(userLat)
        {
            if let floatlong = Float(userLong)
            {
                if floatlat > 90 || floatlat < -90
                {
                    print("LAT OUT OF RANGE")
                    //lat.textColor = UIColor.red
                    return
                }
                if floatlong > 90 || floatlong < -90
                {
                    print("LONG OUT OF RANGE")
                    //long.textColor =  UIColor.red
                    return
                }

            }
            else { print("Could not convert longitude to float.") }
        }
        else { print("Could not convert latitude to float.")}
        */
        
        if day == "" {setDateLatLong()}
        if timeInterval == "" {setIntervalLatLong()}
        print(timeInterval)
        
        let userYear = year
        let userMonth = month
        let userDay = day
        
        // call the API
        let fullUrl = root + _year + userYear + and + _month + userMonth + and + _day + userDay + and + _lat + userLat + and + _long + userLong + and + _interval + timeInterval
        
        callBackend(fullUrl: fullUrl)
    }

    func callBackend(fullUrl: String)
    {
        if let url = URL(string: fullUrl)
        {
            let task = URLSession.shared.dataTask(with: url)
            {
                (data,response,error) in
                
                if error != nil { print("Error: Could not get results from server.") }
                else
                {
                    if let returnData = String(data: data!, encoding: .utf8)
                    {
                        if checkResponse(content: returnData) { times_elevations = formatResponse(content: returnData, time_start: timeInterval) }
                    }
                    else { print("Server Error") }
                }
            }
            task.resume()
        }
    }
    
    override func viewDidLoad()
    {
        
        scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.view.frame.height+80)
        scrollView.contentOffset.x = 0
        // set the color of the date picker
        date.setValue(UIColor.white, forKey: "textColor")
        date.setValue(UIColor.black, forKey: "backgroundColor")
        
        super.viewDidLoad()
        getUserLocationFromCoreData()
        setAsPresets()
    }
    
    func getUserLocationFromCoreData()
    {
        print("Getting location data from core data")
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
                    if let l_latitude = result.value(forKey: "latitude") as? String { r_latitude = l_latitude }
                    if let l_longitude = result.value(forKey: "longitude") as? String { r_longitude = l_longitude }
                }
            }
        } catch { print("Could not get results from Core Data in Location call")}
    }

    func setAsPresets()
    {
        lat.text! = r_latitude
        long.text! = r_longitude
    }
    
}


// check if the list we expect is there
func checkResponse(content: String) -> Bool
{
    let responsedata = content.components(separatedBy: ",")
    if responsedata.count == 1
    {
        print("Error returned from server.")
        for _ in 1...10 {times_elevations.append("")}
        times_elevations.append("ERROR: Request could not be completed.")
        for _ in 1...2 {times_elevations.append("")}
        if content.contains("400"){times_elevations.append("Invalid user input. Try again.")}
        
        
        
        return false
    }
    return true
}

func formatResponse(content: String, time_start: String) -> Array<String>
{
    print("TIME_START VARIABLE: " + time_start)
    var ts = time_start
    var times = [String]()
    var elevations = [String]()
    let responsedata = content.components(separatedBy: ",")
    var hours = [Int]()
    var mins = [Int]()
    
    for i in responsedata
    {
        let div = i.components(separatedBy: ":")
        //print(div)
        if div.count == 3
        {
            var t1 = ""
            for s in div[0] { if s != "{" && s != "\\" && s != "\"" && s != " " && s != ":" {t1 = t1 + String(s)}}
            if t1.count == 1 {t1 = "0" + t1}
            var t2 = ""
            for s in div[1] { if s != "{" && s != "\\" && s != "\"" && s != " " && s != ":" {t2 = t2 + String(s)}}
            if t2.count == 1 {t2 = t2 + "0"}
            
            let elevation = String(div[2])
            hours.append(Int(t1)!)
            mins.append(Int(t2)!)
            elevations.append(elevation)
        }
    }
    
    //let times = adjustTimesForTimeZone(hours: hours, mins: mins)
    //var times = [String]()
    var together = ""
    for i in 0...hours.count - 1
    {
        let h = hours[i]
        let m = mins[i]
        var str_hour = ""
        if h < 10 {str_hour = "0" + String(h)}
        else {str_hour = String(h)}
        var str_mins = ""
        if m < 10 {str_mins = "0" + String(m)}
        else {str_mins = String(m)}
        let time = str_hour + ":" + str_mins
        times.append(time)
    }
    let gap = "                   "
    let small_gap = "                  "
    var rounded_elevations = [Double]()
    var negatives = [Bool]()
    for e in elevations
    {
        var components = e.components(separatedBy: ".")
        components[0] = components[0].replacingOccurrences(of: " ", with: "", options: .literal, range: nil)
        if components[0].hasPrefix("-"){ negatives.append(true) }
        else {negatives.append(false)}
        let whole = Double(components[0])
        var tmp = ""
        var i = 0
        for c in components[1]
        {
            tmp = tmp + String(c)
            i = i + 1
            if i == 5 {break}
        }
        //if tmp.count > 1 {tmp = String(tmp.prefix(1))}
        tmp = "0." + tmp
        let decimal = NumberFormatter().number(from: tmp)?.doubleValue
        print(decimal)
    
        //var decimal = Double(tmp)!
        //decimal = decimal * 10
        //decimal.round()
        //decimal = decimal / 10
        let full = whole! + decimal!
        rounded_elevations.append(full)
    }
    
    var te = [String]()
    
    for i in 0...times.count - 1
    {
        if rounded_elevations[i] > 0 && negatives[i] == true {rounded_elevations[i] = rounded_elevations[i] * -1}
        
        // set the colors array based on size of elevation
        if rounded_elevations[i] >= 50  {color[i] = true}
        else {color[i] = false}
        
        var numberformatter = NumberFormatter()
        //numberformatter.maximumFractionDigits = 1
        //numberformatter.minimumFractionDigits = 1
        numberformatter.positiveFormat = "0.000"
        numberformatter.negativeFormat = "-0.000"
        let number = NSNumber(value:rounded_elevations[i])
        var elevation = numberformatter.string(from:number)!
        elevation = elevation.replacingOccurrences(of: " ", with: "", options: .literal, range: nil)
        if elevation == "0.0" {together = times[i] + gap + " " + elevation}
        else if Double(elevation)! > Double(9.9) {together = times[i] + gap + elevation}
        else if Double(elevation)! < Double(-9.9) {together = times[i] + small_gap + elevation}
        else if negatives[i]{ together = times[i] + gap + elevation }
        else {together = times[i] + gap + " " + elevation }
        print(together)
        te.append(together)
    }
    // find "00:05" and make that the new start
    var index = 0
    var temp = [String]()
    
    if ts == "" {ts = "5"}
    
    for t in te
    {
        let components = t.components(separatedBy: small_gap)
        if components[0] == "00:05" && ts == "5" {break}
        else if components[0] == "00:15" && ts == "15" {break}
        else if components[0] == "00:30" && ts == "30" {break}
        else if components[0] == "00:00" && ts == "60" {break}
        else {index = index + 1}
    }
    var colortmp = [Bool]()
    let end = te.count - 1
    for i in index...end
    {
        temp.append(te[i])
        print(i)
    }
    for i in 0...index-1
    {
        temp.append(te[i])
        print(i)
    }
    for i in index...end { colortmp.append(color[i])}
    for i in 0...index-1 { colortmp.append(color[i])}
    color = colortmp
    
    // buffer top and bottom
    for _ in 1...1 {temp.insert("", at: 0)}
    for _ in 1...3 {temp.append("")}
    // buffer color array to match
    for _ in 1...1 {color.insert(false, at: 0)}
    for _ in 1...3 {color.append(false)}
    
    return temp
}

extension CLLocation {
    func fetchCityAndCountry(completion: @escaping (_ city: String?, _ country:  String?, _ error: Error?) -> ()) {
        CLGeocoder().reverseGeocodeLocation(self) { completion($0?.first?.locality, $0?.first?.country, $1) }
    }
}

func setIntervalLatLong(){timeInterval = "5"}

func setDateLatLong()
{
    let date = Date()
    let format = DateFormatter()
    format.dateFormat = "yyyy-MM-dd"
    let formattedDate = format.string(from: date)
    
    let components = formattedDate.components(separatedBy: "-")
    year = components[0]
    month = components[1]
    day = components[2]
}
