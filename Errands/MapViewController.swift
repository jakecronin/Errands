
//
//  ViewController.swift
//  Errands
//
//  Created by Jake Cronin on 5/24/16.
//
//

import UIKit
import MapKit

protocol mapSearch{
	func placePin(_ placemark: MKPlacemark)
}

class MapViewController: UIViewController {
	
	var selectedPin:MKPlacemark? = nil				//pin data indlcues coordinates and associated location data
	var resultSearchController: UISearchController? = nil	//controll results from search bar
	var name = "" //used to store the nae of the selectedPin
	
	
	@IBOutlet weak var mapView: MKMapView!
	
	
	let locationManager = CLLocationManager()	//use to configure when location data should be used?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		locationManager.delegate = self								//declare delegate for location Manager
		locationManager.desiredAccuracy = kCLLocationAccuracyBest	//delare accuracy of the location Manager
		locationManager.requestWhenInUseAuthorization()
		print("about to request location")
		locationManager.requestLocation()							//get current location from location Manager
		print("requested location")
		let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable	//Create a locationSearchTable from LocationSearchTable view controller
		resultSearchController = UISearchController(searchResultsController: locationSearchTable)
		resultSearchController?.searchResultsUpdater = locationSearchTable
		let searchBar = resultSearchController!.searchBar	//initialize searchbar for the resultSearchController
		searchBar.sizeToFit()
		searchBar.placeholder = "Enter a location"
		navigationItem.titleView = resultSearchController?.searchBar	//put searchbar in the titleview
		resultSearchController?.hidesNavigationBarDuringPresentation = false
		resultSearchController?.dimsBackgroundDuringPresentation = true
		definesPresentationContext = true
		locationSearchTable.mapView = mapView
		locationSearchTable.mapSearchDelegate = self
	}
	
	/*override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject?) {
		if segue.identifier == "unwindToHome"{
			//let homeViewController = segue!.destinationViewController as! HomeViewController
			//print("this better be a name: " + name)
			let mapItem = MKMapItem(placemark: selectedPin!)
			homeViewController.newDestination = (mapItem, name)
			homeViewController.destinations.append(homeViewController.newDestination)
			selectedPin = nil
		}
	}*/
	
	func buttonAddPress(){
		let nameAlertView = UIAlertController(title: "Errand Name", message: "Please enter the name of this errand", preferredStyle: UIAlertControllerStyle.alert)
		nameAlertView.addTextField { (textField) in
		}
		nameAlertView.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
			let nameField = nameAlertView.textFields![0] as UITextField
			if nameField.text != ""{
				self.name = nameField.text!
			}
			else{
				self.name = "My Errand"
			}
			print("about to unwind")
			self.performSegue(withIdentifier: "unwindToHome", sender: self)
		}))
		self.present(nameAlertView, animated: true, completion: nil)
	}
	
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}



extension MapViewController: CLLocationManagerDelegate{	//delegate for locationManager
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		if status == .authorizedWhenInUse{
			locationManager.requestLocation()
		}else{
			print("unaurthorized to get location")
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		print("getting current location")
		if let location = locations.first{
			print("got current location")
			let span = MKCoordinateSpanMake(0.05, 0.05)
			let region = MKCoordinateRegion(center: location.coordinate, span: span)
			mapView.setRegion(region, animated: true)
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("Error with location manager: \(error)")
	}
}

extension MapViewController: mapSearch{
	
	func placePin(_ placemark: MKPlacemark) {
		selectedPin = placemark
		mapView.removeAnnotations(mapView.annotations)	//get rid of all other pins
		//build annotation to place
		let annotation = MKPointAnnotation()
		annotation.coordinate = placemark.coordinate
		annotation.title = placemark.name
		if let city = placemark.locality,
			let state = placemark.administrativeArea{
			annotation.subtitle = "\(city) \(state)"
		}
		mapView.addAnnotation(annotation)
		let span = MKCoordinateSpanMake(0.05, 0.05)
		let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
		mapView.setRegion(region, animated: true)
	}
}

extension MapViewController: MKMapViewDelegate{
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
		if annotation is MKUserLocation{
			return nil
		}
		let reuseID = "pin"
		var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
		pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
		pinView?.pinTintColor = themeMainColor
		pinView?.canShowCallout = true
		let smallSquare = CGSize(width: 50, height: 50)
		let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
		button.setTitle("Add", for: UIControlState())
		button.backgroundColor = UIColor.blue
		button.addTarget(self, action: #selector(MapViewController.buttonAddPress), for: .touchUpInside)
		button.showsTouchWhenHighlighted = true
		pinView?.leftCalloutAccessoryView = button
		return pinView
		
	}
	
}






