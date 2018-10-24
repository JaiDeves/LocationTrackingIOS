//
//  OlaVC.swift
//  LocationTracking
//
//  Created by apple on 10/23/18.
//  Copyright © 2018 apple. All rights reserved.
//


import UIKit
import GoogleMaps
import SwiftLocation
import GooglePlaces


class OlaVC: UIViewController {

    @IBOutlet weak var pickUp_txf: UITextField!
    @IBOutlet weak var drop_txf: UITextField!
    @IBOutlet weak var startTrip_btn: UIButton!
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet weak var dropView: UIView!
    @IBOutlet weak var pickUpView: UIView!
    private var locations = [CLLocation]()
    private var path = GMSMutablePath()
    private var polyline = GMSPolyline()
    private var pickUpMarker = GMSMarker()
    private var dropMarker = GMSMarker()
    private var isFirstMessage = true
    let raceCarIcon = UIImage(named: "race_car")!
    let pickUpPinIcon = UIImage(named: "pickUpPin")!
    let dropPinIcon = UIImage(named: "dropPin")!
    
    var reverseGeocodeResponse:GMSReverseGeocodeResponse?
    
    var demoCoords:NSArray = NSArray()
    var selectedTxf:UITextField?
    var fromPlace:GMSPlace?
    var toPlace:GMSPlace?
    var pickUpLocation:CLLocation?
    var dropLocation:CLLocation?
    
    
    let carMovement = ARCarMovement()
    
    
    var textFieldBackgroundColor:UIColor?
    
    
    @IBAction func dropSelected(_ sender: Any) {
        if dropLocation == nil{
            let autocompleteController = GMSAutocompleteViewController()
            autocompleteController.delegate = self
            present(autocompleteController, animated: true, completion: nil)
        }
        if !startTrip_btn.isHidden{
            textFieldSelected(drop_txf)
        }
    
    }
    
    
    @IBAction func pickUpSelected(_ sender: Any) {
        if !startTrip_btn.isHidden{
            textFieldSelected(pickUp_txf)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate  = self
        drop_txf.delegate = self
        pickUp_txf.delegate = self
        mapView.settings.myLocationButton = true
        carMovement.delegate = self
        startTrip_btn.addTarget(self, action: #selector(startTripAction), for: .touchUpInside)
        getCurrentLocation()
        textFieldBackgroundColor = dropView.backgroundColor
        textFieldSelected(pickUp_txf)
    }
    
    func textFieldSelected(_ textField:UITextField){
        selectedTxf = textField
        if textField == pickUp_txf{
            pickUpView.backgroundColor = textFieldBackgroundColor
            dropView.backgroundColor = textFieldBackgroundColor?.withAlphaComponent(0.5)
            if let location = pickUpLocation{
                updateMapFrame(newLocation: location, zoom: 17)
            }
            
        }else{
            dropView.backgroundColor = textFieldBackgroundColor
            pickUpView.backgroundColor = textFieldBackgroundColor?.withAlphaComponent(0.5)
            if let location = dropLocation{
                updateMapFrame(newLocation: location, zoom: 17)
            }
        }
        
    }
   
    
    @objc func startTripAction(){
        if  dropLocation != nil{
            trackUser()
            startTrip_btn.isHidden = true
            getPolylineRoute(from: pickUpLocation!.coordinate, to: dropLocation!.coordinate)
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
        if startTrip_btn.isHidden == true{
            if let last = locations.last{
//                carMovement.ARCarMovement(marker: currentPositionMarker, oldCoordinate: last.coordinate, newCoordinate: currentLocation.coordinate, mapView: mapView, bearing: 0)
            }
        }else{
            if selectedTxf == drop_txf{
                self.dropMarker =  GMSMarker(position: currentLocation.coordinate)
                self.dropMarker.icon = dropPinIcon
                self.dropMarker.map = self.mapView
            }else{
                self.pickUpMarker =  GMSMarker(position: currentLocation.coordinate)
                self.pickUpMarker.icon = pickUpPinIcon
                self.pickUpMarker.map = self.mapView
            }
            
        }
    }
    
    
//    func addMarker(place:GMSPlace){
//        let marker = GMSMarker(position: place.coordinate)
//        marker.title = place.name
//        marker.map = mapView
//        if place == fromPlace{
//            fromMarker?.map = nil
//            fromMarker = marker
//            marker.icon = GMSMarker.markerImage(with: .green)
//        }else{
//            toMarker?.map = nil
//            toMarker = marker
//        }
//    }
    
    func reverseGeoCode(coordinate:CLLocationCoordinate2D){
        //        let url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(coordinate.latitude),\(coordinate.longitude)&key=\(otherKey)"
        GMSGeocoder().reverseGeocodeCoordinate(coordinate) { (response, error) in
            print(response.debugDescription)
            self.selectedTxf?.text = response?.firstResult()?.lines?.first
            self.reverseGeocodeResponse = response
            //            GMSPlacesClient().lookUpPlaceID("", callback: { (place, error) in
            //                self.toPlace = place
            //            })
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
                            
                            DispatchQueue.main.async {
                                self.showPath(polyStr: points!)
                                let bounds = GMSCoordinateBounds(coordinate: source, coordinate: destination)
                                let update = GMSCameraUpdate.fit(bounds, with: UIEdgeInsets(top: 170, left: 30, bottom: 30, right: 30))
                                self.mapView!.moveCamera(update)
                                self.pickUpMarker.icon = self.raceCarIcon
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
extension OlaVC:ARCarMovementDelegate{
    func ARCarMovementMoved(_ Marker: GMSMarker) {
//        self.currentPositionMarker =  Marker
//        self.currentPositionMarker.icon = raceCarIcon
//        self.currentPositionMarker.map = self.mapView
    }
}


extension OlaVC:GMSMapViewDelegate{
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        if !startTrip_btn.isHidden{
            if selectedTxf == drop_txf{
                dropMarker.position = position.target
                dropLocation = CLLocation(latitude: position.target.latitude, longitude:position.target.longitude)
            }else{
                pickUpMarker.position = position.target
                pickUpLocation = CLLocation(latitude: position.target.latitude, longitude:position.target.longitude)
            }
            reverseGeoCode(coordinate: position.target)
        }
        
    }
    
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        
    }
}

extension OlaVC:UITextFieldDelegate{
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if !startTrip_btn.isHidden{
            let autocompleteController = GMSAutocompleteViewController()
            autocompleteController.delegate = self
            present(autocompleteController, animated: true, completion: nil)
            selectedTxf = textField
            textFieldSelected(textField)
        }        
        return false
    }
}


extension OlaVC: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
        if selectedTxf == drop_txf{
            toPlace = place
            dropLocation = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        }else{
            fromPlace = place
            pickUpLocation = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            //            getPolylineRoute(from: locations.first!.coordinate, to: toPlace!.coordinate)
        }
        updateMapFrame(newLocation: CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude), zoom: 17.0)
        updateCurrentPositionMarker(currentLocation: CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude))
        
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
