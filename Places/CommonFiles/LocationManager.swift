//
//  LocationManager.swift
//  Qoot Inventory
//
//  Created by Mohammed on 12/06/17.
//  Copyright © 2017 Mohammed. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps
import RxCocoa
import RxSwift
import RxAlamofire

protocol LocationManagerDelegate {
    //Return search address
    func didUpdateSearch(locations: [Location])
    /// When Update Location
    func didUpdateLocation(location: Location, search:Bool,update:Bool)
    
    /// When Failed to Update Location
    func didFailToUpdateLocation()
    
    func didChangeAuthorization(authorized: Bool)
}

class LocationManager: NSObject {
    let disposeBag = DisposeBag()
    
    var latitute: Float = 12.3254453
    var longitude: Float = 77.2456456
    var name: String = ""
    var FullText = ""
    var tempName = ""
    
    var city: String = ""
    var state: String = ""
    var country: String = ""
    var zipcode: String = ""
    var street: String = ""
    var countryCode: String = ""
    var CLlocationObj = CLLocation()
    
    var locationObj: CLLocationManager? = nil
    var delegate: LocationManagerDelegate? = nil
    
    static var shareObj: LocationManager? = nil
    /// Create Shared Instance
    static var shared: LocationManager {
        if shareObj == nil {
            shareObj = LocationManager()
        }
        return shareObj!
    }
    
    override init() {
        super.init()
        locationObj = CLLocationManager()
        locationObj?.delegate = self
        Helper.HelperResponseType.subscribe(onNext: { (success) in
            switch success {
            case .LocationAvalibility,.CameraAvailability,.MediaAvailability:
                UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
                break
            default:
                break
            }
        }).disposed(by: disposeBag)
    }
    /// Start Location Update
    func start() {
        locationObj?.requestWhenInUseAuthorization()
        if CLLocationManager.authorizationStatus() == .denied {
            Helper.showAlertReturn(message: StringConstants.AllowLocationBody(), head: String(format:StringConstants.AllowLocationHead(),Utility.AppName), type: StringConstants.Done(), closeHide: false, responce: Helper.ResponseTypes.LocationAvalibility)
            Helper.hidePI()
            return
        }
        locationObj?.startUpdatingLocation()
    }
    /// Stop Location Update
    func stop() {
        locationObj?.stopUpdatingLocation()
    }
    //MARK: - Google Auto Complete
    
    /// Call Google Auto Complete API
    ///
    /// - Parameter searchText: Words to be Searched
        func search(searchText: String, language: String) {
        
        // Remove Blank space from word
        let text = searchText.replacingOccurrences(of: " ", with: "")
        
        let latitudeTemp = LocationManager.shared.latitute
        let longitudeTemp = LocationManager.shared.longitude
        let key = GoogleKeys.GoogleMapKey
        
        let placeAPI = String(format: GoogleKeys.PlacesAPILink ,text,latitudeTemp,longitudeTemp,language,key)
        
        // Call Service
            
        RxAlamofire.requestJSON(.get, placeAPI).debug().subscribe(onNext: { (head, body) in
            let bodyIn = body as! [String:Any]
            if let array = bodyIn[GoogleKeys.Predictions] as? [Any] {
                var arrayOfLocation = [Location]()
                for dataFrom in array {
                    let data = Location.init(data: dataFrom as! [String : Any])
                    arrayOfLocation.append(data)
                }
                self.delegate?.didUpdateSearch(locations: arrayOfLocation)
            }
        }, onError: { (Error) in
            
        }).disposed(by: disposeBag)
    }
    
    
    func updateLocationData(location : CLLocation , placeIn:Location,flag:Bool) {
        CLlocationObj = location
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location) {
            
            (placemarks, error) -> Void in
            
            if placemarks == nil {
                return
            }
            
            
            let arrayOfPlaces = placemarks as [CLPlacemark]?
            
            // Place details
            let placemark: CLPlacemark = (arrayOfPlaces?[0])!
            
            // Address dictionary
            var flagSearch = true
            // Location name
            if self.tempName.length > 0 {
                self.name = self.tempName
                self.tempName = ""
                flagSearch = true
            }else{
                if let name = placemark.name {
                    self.name = name
                    flagSearch = false
                }
            }
            let placeData = placemark.addressDictionary as! [String : Any]
            // Country
            if let country = placemark.country {
                if GoogleKeys.myCountry.length == 0 {
                    GoogleKeys.myCountry = country
                }
            }
            placeIn.update(data: placeData, location:self.CLlocationObj)
            if flag {
                Utility.saveCurrentAddress(lat: Float(location.coordinate.latitude), long: Float(location.coordinate.longitude),address: placeIn.FullText)
            }
            if self.delegate != nil {
                self.delegate?.didUpdateLocation(location: placeIn ,search: flagSearch,update:flag)
            }
            
        }
    }
    
    
    func googlePlacesInformation(placeId: String, completion: @escaping (_ place: NSDictionary) -> Void) {
        
        let urlString = String(format: GoogleKeys.PlaceEnlarge,placeId,GoogleKeys.GoogleMapKey)
        RxAlamofire.requestJSON(.get, urlString, parameters: [:], headers: [:]).debug().subscribe(onNext: { (head, body) in
            let bodyIn = body as! [String:Any]
            let status = bodyIn["status"] as! String
            if status != "NOT_FOUND" && status != "REQUEST_DENIED" && status != "OVER_QUERY_LIMIT" {
                if let results = bodyIn["result"] as? NSDictionary {
                    completion(results)
                }
            }else if status == "OVER_QUERY_LIMIT" || status == "REQUEST_DENIED" {
                GoogleKeys.SelectedPositionMapKey = GoogleKeys.SelectedPositionMapKey + 1
                Helper.hidePI()
            }else{
                Helper.hidePI()
            }


        }, onError: { (Error) in
        }).disposed(by: disposeBag)
    }
    
    
    func getAddressFromPlace(place:Location) {
//        Helper.showPI(string: StringConstants.ValidateLocation)
        googlePlacesInformation(placeId: place.PlaceId,
                                completion:{ (placeFrom) -> Void in
                                    
                                    
                                    //            let searchResult = NSDictionary()
                                    if placeFrom.count > 0
                                    {
                                        self.tempName = placeFrom.value(forKey: "name") as! String
                                        let latitude =  (((placeFrom.value(forKey: "geometry") as! NSDictionary).value(forKey: "location") as! NSDictionary).value(forKey: "lat") as! NSNumber)
                                        
                                        let longitude =  (((placeFrom.value(forKey: "geometry") as! NSDictionary).value(forKey: "location") as! NSDictionary).value(forKey: "lng") as! NSNumber)
                                        
                                        let locationin = CLLocation(latitude: CLLocationDegrees(truncating: latitude), longitude: CLLocationDegrees(truncating: longitude))
                                        
                                        self.updateLocationData(location: locationin , placeIn:place, flag: false)
                                        
                                        
                                        
                                    }
        })
    }

    
}

extension LocationManager: CLLocationManagerDelegate {
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch(status) {
            
        case .authorizedAlways, .authorizedWhenInUse:
            
            print("Access")
            locationObj?.startUpdatingLocation()
            delegate?.didChangeAuthorization(authorized: true)
            break
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if locations.first != nil {
            stop()
            let location = locations.first
            latitute = Float((location?.coordinate.latitude)!)
            longitude = Float((location?.coordinate.longitude)!)
            updateLocationData(location : location!, placeIn:Location.init(data: [String:Any]()),flag:true)
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("\nDid fail location : %@\n",error.localizedDescription)
            delegate?.didFailToUpdateLocation()
        }
    }
}
