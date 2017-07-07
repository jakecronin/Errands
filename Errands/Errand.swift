//
//  Errand.swift
//  Errands
//
//  Created by Jake Cronin on 7/5/17.
//
//

import Foundation
import MapKit

class Errand: Hashable{
	public static func ==(lhs: Errand, rhs: Errand) -> Bool{ //hold each destination and its id number
		if lhs.name == rhs.name && lhs.mapItem == rhs.mapItem && lhs.hashValue == rhs.hashValue{
			return true
		}else{
			return false
		}
	}
	
	init(mapItem: MKMapItem, name: String, index: Int) {
		self.mapItem = mapItem
		self.name = name
		self.index = index
		hashValue = mapItem.hashValue
	}
	
	var hashValue: Int
	
	let mapItem: MKMapItem
	let name: String
	var index : Int		//the position of this destination in the optimal path

	var timeAtPlace: Double = 0
	var timeOfArrival: Date = Date()
	
}
