//
//  LocationSearchTable.swift
//  Errands
//
//  Created by Jake Cronin on 5/27/16.
//
//

import Foundation
import UIKit
import MapKit

class LocationSearchTable: UITableViewController{
	//variables
	var mapSearchDelegate:mapSearch? = nil	//create instance to hande map search
	var mapView: MKMapView? = nil	//variable for mapview
	var matchingItems: [MKMapItem] = []		//array of map items which include location and related data
	
	func parseAddress(_ selectedItem: MKPlacemark) -> String{	//this function parses an address from a given placemark. Includes latitude, longitude, country, state, city, and street address associated with the specified coordinate
		let streetNumberAndNameSpace = (selectedItem.subThoroughfare != nil &&  selectedItem.thoroughfare != nil) ? " ": ""		//subThoroughfare is street number. thoroughfare is steet name
		let steetAndCitySpace = (selectedItem.thoroughfare != nil || selectedItem.subThoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""	//subAdministrative area is county, administrativeArea is state (sometimes abbreviated)
		let cityAndStateSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
		let addressLine = String(format: "%@%@%@%@%@%@%@", selectedItem.subThoroughfare ?? "", streetNumberAndNameSpace, selectedItem.thoroughfare ?? "", steetAndCitySpace, selectedItem.subAdministrativeArea ?? "", cityAndStateSpace,selectedItem.administrativeArea ?? "")
		
		return addressLine
	}
}


extension LocationSearchTable: UISearchResultsUpdating{		//extionsion to conform to UISearchResultsUpdating protocol
	
	func updateSearchResults(for searchController: UISearchController) {		//required to conform to protocol
		guard let mapView = mapView,
			let searchBarText = searchController.searchBar.text else{ return}
		let request = MKLocalSearchRequest()
		request.naturalLanguageQuery = searchBarText
		request.region = mapView.region
		let search = MKLocalSearch(request: request)
		search.start { response, _ in
			guard let response = response else {return}
		self.matchingItems = response.mapItems
		self.tableView.reloadData()
		}
	}
}


extension LocationSearchTable{
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return matchingItems.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
		let selectedItem = matchingItems[(indexPath as NSIndexPath).row].placemark
		cell.textLabel?.text = selectedItem.name
		cell.detailTextLabel?.text = parseAddress(selectedItem)
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let selectedItem = matchingItems[(indexPath as NSIndexPath).row].placemark
		mapSearchDelegate?.placePin(selectedItem)
		dismiss(animated: true, completion: nil)
	}
}
