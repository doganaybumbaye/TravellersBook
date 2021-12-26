//
//  ViewController.swift
//  TravelBook
//
//  Created by Doğanay Şahin on 8.08.2021.
//

import UIKit
import MapKit
import CoreLocation
import CoreData
class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    var chosenLatidute = Double()
    var chosenLongidute = Double()
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationID : UUID?
    var annotationLatidute = Double()
    var annotationLongidute = Double()
    
    @IBOutlet weak var saveButton: UIButton!
    
    
    @IBOutlet weak var commentField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        let gestureRecognizerKeyboard = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizerKeyboard)
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedTitle != ""{
            
            saveButton.isHidden = true
            

            
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            
            let idString = selectedTitleID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            
                
            
            do {
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0 {
                    for result in results as! [NSManagedObject]{
                        
                        if let title = result.value(forKey: "title") as? String{
                            annotationTitle = title
                            if let subtitle  = result.value(forKey: "subtitle") as? String{
                                annotationSubtitle = subtitle
                                if let id = result.value(forKey: "id") as? UUID{
                                    annotationID = id
                                    if let latidute = result.value(forKey: "latidute") as? Double{
                                        annotationLatidute = latidute
                                        if let longidute = result.value(forKey: "longidute") as? Double{
                                            annotationLongidute = longidute
                                            
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubtitle
                                            
                                            let coordinates = CLLocationCoordinate2D(latitude: annotationLatidute, longitude: annotationLongidute)
                                            
                                            annotation.coordinate = coordinates
                                            mapView.addAnnotation(annotation)
                                            nameField.text = annotationTitle
                                            commentField.text = annotationSubtitle
                                            
                                            locationManager.stopUpdatingLocation()
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            
                                            let region = MKCoordinateRegion(center: coordinates, span: span)
                                            mapView.setRegion(region, animated: true)
                                            
                                        }
                                    }
                                    
                                }
                            }
                        }


                        

                        
                    }
                    
                    
                }
                
            } catch  {
                print("error")
            }
            }else{
            
        }
        
    
    }
    
    
    @objc func hideKeyboard(){
        view.endEditing(true)
    }
    
    @objc func chooseLocation(gestureRecognizer : UILongPressGestureRecognizer){
        
        if nameField.text != ""{
            
        if gestureRecognizer.state == .began{
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom : self.mapView)
            
            chosenLatidute = touchedCoordinates.latitude
            chosenLongidute = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameField.text
            
            annotation.subtitle = commentField.text
            self.mapView.addAnnotation(annotation)
            
        }
        }else{
            makeAlert(title: "Give some name!", message: "Put a name that place first!")
        }
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == ""{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            
            mapView.setRegion(region, animated: true)
        }else{
            
        }
        
       
        
        
        
        

    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            
            pinView?.tintColor = UIColor.blue
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else{
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != ""{
            
            let requestLocation = CLLocation(latitude: annotationLatidute, longitude: annotationLongidute)
            CLGeocoder().reverseGeocodeLocation(requestLocation) {
                (placemarks, error) in
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeWalking]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
    }
    
    
    @IBAction func saveButton(_ sender: Any) {
        
        
        
        
            
        if nameField.text == ""{
            makeAlert(title: "Could not saved!", message: "Please give some name that place!")
        }
        else{
            
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameField.text, forKey: "title")
        newPlace.setValue(commentField.text, forKey: "subtitle")
        newPlace.setValue(chosenLatidute, forKey: "latidute")
        newPlace.setValue(chosenLongidute, forKey: "longidute")
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("succes")
        }
        catch{
            print("eeror")
        }
        NotificationCenter.default.post(name: NSNotification.Name("newLocation"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    }
    
    func makeAlert(title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil)
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
    }
}



