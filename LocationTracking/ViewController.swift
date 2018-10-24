//
//  ViewController.swift
//  LocationTracking
//
//  Created by apple on 10/12/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit
import GoogleMaps
import SwiftLocation
import GooglePlaces

let otherKey = "AIzaSyDdAg9m9iZ4ch4ivTIVERX2j96UkkimYQc"


class ViewController: UIViewController {
    
    @IBOutlet weak var stackViewBackground: UIView!
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var startTripButton: UIButton!
    
    var isDemo = false
    private var locations = [CLLocation]()
    private var path = GMSMutablePath()
    private var polyline = GMSPolyline()
    private var currentPositionMarker = GMSMarker()
    private var isFirstMessage = true
    let raceCarIcon = UIImage(named: "race_car")
    var currentLocation:CLLocation?
    
    @IBOutlet weak var from_txf: UITextField!
    @IBOutlet weak var to_txf: UITextField!
    
    
    var demoCoords:NSArray = NSArray()
    var selectedTxf:UITextField?
    var fromPlace:GMSPlace?
    var toPlace:GMSPlace?
    var fromMarker:GMSMarker?
    var toMarker:GMSMarker?
    let carMovement = ARCarMovement()
    var oldCoord:CLLocationCoordinate2D?
    var counter = 0
    
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate  = self
        from_txf.delegate = self
        to_txf.delegate = self
        mapView.settings.myLocationButton = true
        carMovement.delegate = self
        startTripButton.addTarget(self, action: #selector(startTripAction), for: .touchUpInside)
        
        if isDemo{
            handleDemo()
        }else{
            getCurrentLocation()
        }
    }
    
    func handleDemo(){
        guard isDemo else { return }
        
        if let path = Bundle.main.path(forResource: "coordinates", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? NSArray{
                    self.demoCoords = jsonResult
                }
            } catch {
                // handle error
                print(error)
            }
        }
        
        oldCoord = CLLocationCoordinate2D(latitude: 40.7416627, longitude: -74.0049708)
        updateMapFrame(newLocation: CLLocation(latitude: 40.7416627, longitude: -74.0049708), zoom: 14)
        
        
        self.currentPositionMarker =  GMSMarker(position: oldCoord!)
        self.currentPositionMarker.icon = raceCarIcon
        self.currentPositionMarker.map = self.mapView
        
        //set counter value 0
        //
        self.counter = 0;
        
        //start the timer, change the interval based on your requirement
        //
        self.timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(handleTimer(_:)), userInfo: nil, repeats: true)
        self.timer.fire()
        
        let lat = (self.demoCoords.lastObject as! [String:Double])["lat"]!
        let long = (self.demoCoords.lastObject as! [String:Double])["long"]!
        let newCoord = CLLocationCoordinate2D(latitude: lat, longitude: long)
        getPolylineRouteForDemo(from: oldCoord!, to: newCoord)
        stackViewBackground.isHidden = true
        stackView.isHidden = true
        startTripButton.isHidden = true
    }
    
    
    @objc func handleTimer(_ timer:Timer){
        
        if (self.counter < self.demoCoords.count) {
            let lat = (self.demoCoords[self.counter] as! [String:Double])["lat"]!
            let long = (self.demoCoords[self.counter] as! [String:Double])["long"]!
            
            let newCoord = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            /**
             *  You need to pass the created/updating marker, old & new coordinate, mapView and bearing value from backend
             *  to turn properly. Here coordinates json files is used without new bearing value. So that
             *  bearing won't work as expected.
             */
            self.carMovement.ARCarMovement(marker: self.currentPositionMarker, oldCoordinate: self.oldCoord!, newCoordinate: newCoord, mapView: self.mapView, bearing: 0)
            //instead value 0, pass latest bearing value from backend
            
            self.oldCoord = newCoord
            self.counter = self.counter + 1; //increase the value to get all index position from array
        }
        else {
            self.timer.invalidate()
            self.timer = Timer()
        }
    }
    
    @objc func startTripAction(){
        if  toPlace != nil{
            trackUser()
            startTripButton.isHidden = true
        }else{
            let alertVC = UIAlertController(title: "", message: "Please enter Destination", preferredStyle: .alert)
            let okAction  = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertVC.addAction(okAction)
            self.present(alertVC, animated: true, completion: nil)
        }
    }
    
    
    func getCurrentLocation(){
        Locator.currentPosition(accuracy: .neighborhood, onSuccess: { (location) -> (Void) in
            self.locations  = []
            self.locations.append(location)
            //            self.updateOverlay(currentPosition: location)
            // Update the map frame
            self.updateMapFrame(newLocation: location, zoom: 17.0)
            // Update Marker position
            self.updateCurrentPositionMarker(currentLocation: location)
            
        }) { (error, location) -> (Void) in
            
        }
    }
    
    func trackUser(){
        Locator.subscribePosition(accuracy: .city, onUpdate: { (location) -> (Void) in
            print(location)
            
            if let lastLocation = self.locations.last{
                //                if lastLocation.distance(from: location) > 10{
                
                
                // Drawing the line
                //                    self.updateOverlay(currentPosition: location)
                // Update the map frame
                self.updateMapFrame(newLocation: location, zoom: 17.0)
                // Update Marker position
                self.updateCurrentPositionMarker(currentLocation: location)
                
                self.locations.append(location)
                //                }
            }else{
                self.locations.append(location)
                if (self.isFirstMessage) {
                    //                    self.initializePolylineAnnotation()
                    self.isFirstMessage = false
                }
                // Drawing the line
                //                self.updateOverlay(currentPosition: location)
                // Update the map frame
                self.updateMapFrame(newLocation: location, zoom: 17.0)
                // Update Marker position
                self.updateCurrentPositionMarker(currentLocation: location)
            }
            
        }) { (error, location) -> (Void) in
            
        }
    }
    
    func initializePolylineAnnotation() {
        self.polyline.strokeColor = UIColor.blue
        self.polyline.strokeWidth = 5.0
        self.polyline.map = self.mapView
    }
    func updateOverlay(currentPosition: CLLocation) {
        self.path.add(currentPosition.coordinate)
        self.polyline.path = self.path
    }
    func updateMapFrame(newLocation: CLLocation, zoom: Float) {
        let camera = GMSCameraPosition.camera(withTarget: newLocation.coordinate, zoom: zoom)
        DispatchQueue.main.async{
            self.mapView.animate(to: camera)
        }
    }
    
    func updateCurrentPositionMarker(currentLocation: CLLocation) {
        //        let head = currentLocation.course
        //        self.currentPositionMarker.rotation = head
        if let last = locations.last{
            carMovement.ARCarMovement(marker: currentPositionMarker, oldCoordinate: last.coordinate, newCoordinate: currentLocation.coordinate, mapView: mapView, bearing: 0)
        }
        
    }
    
    func addMarker(place:GMSPlace){
        let marker = GMSMarker(position: place.coordinate)
        marker.title = place.name
        marker.map = mapView
        if place == fromPlace{
            fromMarker?.map = nil
            fromMarker = marker
            marker.icon = GMSMarker.markerImage(with: .green)
        }else{
            toMarker?.map = nil
            toMarker = marker
        }
    }
    func getPolylineRouteForDemo(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D){
        
        if let path = Bundle.main.path(forResource: "coordinatesRoutes", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let json : [String:Any] = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]{
                    //                        print(json)
                    guard let routes = json["routes"] as? NSArray else {
                        return
                    }
                    
                    if (routes.count > 0) {
                        let overview_polyline = routes[0] as? NSDictionary
                        let dictPolyline = overview_polyline?["overview_polyline"] as? NSDictionary
                        
                        let points = dictPolyline?.object(forKey: "points") as? String
                        
                        self.showPath(polyStr: points!)
                        
                        DispatchQueue.main.async {
                            let bounds = GMSCoordinateBounds(coordinate: source, coordinate: destination)
                            let update = GMSCameraUpdate.fit(bounds, with: UIEdgeInsets(top: 170, left: 30, bottom: 30, right: 30))
                            self.mapView!.moveCamera(update)
                        }
                    }
                }
            }catch {
                print("error in JSONSerialization")
            }
            
        }
    }
    
    func getPolylineRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D){
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(source.latitude),\(source.longitude)&destination=\(destination.latitude),\(destination.longitude)&sensor=true&mode=driving&key=AIzaSyDdAg9m9iZ4ch4ivTIVERX2j96UkkimYQc")!
        print(url)
        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }
            else {
                do {
                    print(String.init(data: data!, encoding: String.Encoding.utf8))
                    if let json : [String:Any] = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any]{
                        //                        print(json)
                        guard let routes = json["routes"] as? NSArray else {
                            return
                        }
                        
                        if (routes.count > 0) {
                            let overview_polyline = routes[0] as? NSDictionary
                            let dictPolyline = overview_polyline?["overview_polyline"] as? NSDictionary
                            
                            let points = dictPolyline?.object(forKey: "points") as? String
                            
                            self.showPath(polyStr: points!)
                            
                            DispatchQueue.main.async {
                                let bounds = GMSCoordinateBounds(coordinate: source, coordinate: destination)
                                let update = GMSCameraUpdate.fit(bounds, with: UIEdgeInsets(top: 170, left: 30, bottom: 30, right: 30))
                                self.mapView!.moveCamera(update)
                            }
                        }
                        else {
                            DispatchQueue.main.async {
                                
                            }
                        }
                    }
                }
                catch {
                    print("error in JSONSerialization")
                    DispatchQueue.main.async {
                        
                    }
                }
            }
        })
        task.resume()
    }
    
    func showPath(polyStr :String){
        let path = GMSPath(fromEncodedPath: polyStr)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 5.0
        polyline.strokeColor = UIColor.blue
        polyline.map = mapView // Your map view
    }
    
}
extension ViewController:ARCarMovementDelegate{
    func ARCarMovementMoved(_ Marker: GMSMarker) {
        self.currentPositionMarker =  Marker
        self.currentPositionMarker.icon = raceCarIcon
        self.currentPositionMarker.map = self.mapView
    }
}


extension ViewController:GMSMapViewDelegate{
    
}
extension ViewController:UITextFieldDelegate{
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
        selectedTxf = textField
        return false
    }
}


extension ViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
        if selectedTxf == from_txf{
            fromPlace = place
            updateMapFrame(newLocation: CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude), zoom: 17.0)
        }else{
            toPlace = place
            getPolylineRoute(from: locations.first!.coordinate, to: toPlace!.coordinate)
        }
        addMarker(place: place)
        selectedTxf?.text = place.name
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}
