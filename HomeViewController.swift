//
//  HomeViewController.swift
//  Errands
//
//  Created by Jake Cronin on 5/28/16.
//
//


/*
ERROR 1: when updating a node, make sure it is not already in the heap before adding it into the heap. Aka, if it already exists, find it and heapify up rather than inserting a new one

ERRPR 2: current algorithm finds shortest path, but does not guarentee that all places are hit. if all places are similarly close to the start, their shortest path will be from start-errand, rahter than start-otherErrand-errand. 
	-	Overcome this by going depth first

*/

import Foundation
import UIKit
import MapKit

class HomeViewController: UIViewController{
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var calculateButton: UIButton!
	
	@IBOutlet weak var arrivalTimeLabel: UILabel!
	@IBOutlet weak var durationLabel: UILabel!
	
	var errands: [Errand] = []					//holds all destinations | Index 0 is start | Index 1 is end
	var minPath: Path?
	
	var etaCallsCompleted = 0
	var etaCallsToMake = 0
	var minHeap = PathMinHeap()
	
}

extension HomeViewController{
	func constructShortestPath(from: Errand, to: Errand){
		print("started construct shortest path")//find shortest path with breadth first search prioritizing shortest connection
		
		//initialize
		minHeap = PathMinHeap()
		minPath = nil
		let firstPath = Path()
		firstPath.addErrand(errand: from, timeOfArrival: Date())
		minHeap.insert(firstPath)
		
		
		shortestPathHelper(path: minHeap.remove()!)
	}
	func shortestPathHelper(path: Path){
		let pathEnd = path.path.last!
		if minPath != nil && path.travelTime > minPath!.travelTime{
			self.completedAllETACalls()
			return									//kill this path
		}else if path.path.count == errands.count - 1{	//just needs the last destination!
			let finalDestination = errands.last!
			getETA(pathEnd, to: finalDestination, at: path.arrivalTimes[pathEnd]!, completion: { (result) in
				guard result != nil else{
					self.completedAllETACalls()
					return
				}
				path.travelTime = path.travelTime + result!		//update travel time
				if self.minPath == nil || path.travelTime < self.minPath!.travelTime{ //if path is fast, update it
					self.minPath = path
					let timeOfArrival = path.arrivalTimes[pathEnd]!.addingTimeInterval(result!)	//calculate time of arrival
					path.addErrand(errand: finalDestination, timeOfArrival: timeOfArrival)	//append new destination to path
				}
				self.completedAllETACalls()
			})
		}else{		//get shortest path to everyone but first and last, and throw nodes onto queue if they are updated
			etaCallsCompleted = 0
			etaCallsToMake = errands.count - 2 //call to everyone but first and last
			for i in 1..<errands.count-1{
				var thisPath  = path.copy()
				getETA(pathEnd, to: errands[i], at: thisPath.arrivalTimes[pathEnd]!, completion: { (result) in
					self.etaCallsCompleted = self.etaCallsCompleted + 1
					guard result != nil else{
						print("error getting duration for a node")
						if self.etaCallsCompleted >= self.etaCallsToMake{
							self.completedAllETACalls()
						}
						return	//error, kill path
					}
					
					print("appending destination \(self.errands[i].name) to path \(pathEnd.name)")
					//Did not get nil result, so add path onto queue
					thisPath.travelTime = thisPath.travelTime + result!
					let arrivalTime = thisPath.arrivalTimes[pathEnd]!.addingTimeInterval(result!)
					thisPath.addErrand(errand: self.errands[i], timeOfArrival: arrivalTime)
					
					//Quick weedout of absurdly long paths
					if self.minPath == nil || thisPath.travelTime < self.minPath!.travelTime{
						self.minHeap.insert(thisPath)
					}
					if self.etaCallsCompleted >= self.etaCallsToMake{
						self.completedAllETACalls()
						return
					}
				})
			}
		}
	}
	func getETA(_ from: Errand, to: Errand, at: Date, completion: @escaping (_ eta: Double?) -> Void){
		if from.mapItem == to.mapItem{
			completion(Double.infinity)
			return
		}
		let request: MKDirectionsRequest = MKDirectionsRequest()
		var eta: Double?
		request.source = from.mapItem
		request.destination = to.mapItem
		request.departureDate = at
		request.transportType = MKDirectionsTransportType.automobile
		
		let directions: MKDirections = MKDirections(request: request)
		
		directions.calculateETA { (response: MKETAResponse?, error: Error?) in
			if error != nil {
				print("error getting ETA between \(from.name) and \(to.name)")
				print(error!)
				completion(nil)
			}
			guard response != nil else{
				print("error, response is nil in calculateETA")
				completion(nil)
				return
			}
			print("successfully completed eta request from \(from.name) to \(to.name)")
			eta = response!.expectedTravelTime
			completion(eta)
		}
	}

	//MARK: "Delegate" Functions
	func completedAllETACalls() {				//called when finished calcing all distances from a node, move on to next
		print("completed all etacalls called with heap: \(minHeap.print())")
		if let path = minHeap.remove(){
			shortestPathHelper(path: path)
		}else{									//if there is no next, we are done
			didGetShortestPath()
		}
	}
	func didGetShortestPath(){	//called when shortest path algorithm has completed, aka minheap is empty
		//END ACTIVITY INDIVATOR, Reload Table
		print("did get shortest path called")
		guard self.minPath != nil else{
			print("error, got shortest path, but it was nil. not chanigng array")
			return
		}
		
		errands = minPath!.path
		tableView.reloadData()
		setLabels(duration: minPath?.travelTime, arriveAt: minPath?.arrivalTimes[minPath!.path.last!])
		
	}
	
	func setLabels(duration: Double?, arriveAt: Date?){
		if duration == nil{
			durationLabel.text = "duration not calculated"
		}else{
			durationLabel.text = "Duration is: \(duration!.stringTime))"
		}
		if arriveAt == nil{
			arrivalTimeLabel.text = "Arrival time not calculated"
		}else{
			arrivalTimeLabel.text = "Arrive at: \(String(describing: arriveAt!)))"
		}
	}
	
	//Formatting
	func cellTextLabel(_ x: Int) -> String{
		
		if x == errands.count - 1{
			return "End"
		}
		let s: String
		switch x{
		case 0: s = "Start"
		case 1: s = "1st"
		case 2: s = "2nd"
		case 3: s = "3rd"
		default: s = "\(x-1)th"
		}
		return s
	}
	func formatETA(_ t: Double) -> String{
		var s = "Your trip will take "
		let time: Int = Int(t)
		let seconds: Int = time % 60
		let minutes: Int = (time / 60) % 60
		let hours: Int = (time / 60 / 60) % 24
		let days: Int = (time / 60 / 60 / 24)
		if days == 1{
			s = s + "\(days) day "
		}else if days > 1{
			s = s + "\(days) days "
		}
		if hours == 1{
			s = s + "\(hours) hour "
		}else if hours > 1{
			s = s + "\(hours) hours "
		}
		if minutes == 1{
			s = s + "\(minutes) minute "
		}else if days > 1{
			s = s + "\(minutes) minutes "
		}
		if seconds == 1{
			s = s + "\(seconds) second"
		}else if days > 1{
			s = s + "\(seconds) seconds"
		}
		return s
	}
}

//Actions or Events
extension HomeViewController{
	@IBAction func calculateButton(_ sender: UIButton){
		guard errands.count >= 2 else{
			print("not enough places to calculate optimal rout")
			return
		}
		constructShortestPath(from: errands[0], to: errands[errands.count - 1])
	}
	@IBAction func unwindToHome(_ segue: UIStoryboardSegue){	//take destination and name from
		let mapViewController: MapViewController = segue.source as! MapViewController
		let mapItem = MKMapItem(placemark: mapViewController.selectedPin!)
		let newErrand: Errand = Errand(mapItem: mapItem, name: mapViewController.name, index: errands.count)
		errands.append(newErrand)	//append tuple of mapItem and the name of this errand
		tableView.reloadData()
	}
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource{
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! Cell
		cell.locationLabel.text = errands[indexPath.row].name
		cell.orderLabel.text = cellTextLabel(indexPath.row)
		cell.errand = errands[indexPath.row]
		cell.delegate = self
		
		return cell
	}
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
		setLabels(duration: nil, arriveAt: nil)
		return errands.count
	}
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath){
		if editingStyle == UITableViewCellEditingStyle.delete{
			errands.remove(at: (indexPath as NSIndexPath).row)
			tableView.reloadData()
		}
	}
}

extension HomeViewController: cellDelegate{
	func upArrowPressed(cell: Cell) {
		print("up pressed for \(cell.errand!.name)")
		for i in 1..<errands.count {//start at second one, because first cannot move up
			if errands[i] == cell.errand!{
				errands[i] = errands[i - 1]
				errands[i - 1] = cell.errand!
				tableView.reloadData()
				return
			}
		}
	}
	func downArrowPressed(cell: Cell) {
		print("down pressed for \(cell.errand!.name)")
		for i in 0..<errands.count - 1{	//only go to second to last, because last cannot be moved down
			if errands[i] == cell.errand!{
				errands[i] = errands[i+1]
				errands[i+1] = cell.errand!
				tableView.reloadData()
				return
			}
		}
	}
	
}

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
	let index : Int		//the position of this destination in the optimal path
}
class Path{	//allows maintaining multiple different paths in heap
	var path = [Errand]()
	var arrivalTimes = [Errand: Date]()
	
	func addErrand(errand: Errand, timeOfArrival: Date){
		path.append(errand)
		arrivalTimes[errand] = timeOfArrival
	}
	
	var travelTime: Double = 0
	func compare(to: Path) -> Bool{	//returns true if this path is prioritized. 1. most destinations, 2. shortest duration
		if self.path.count > to.path.count{
			return true
		}else if to.path.count > self.path.count{
			return false
		}else{
			if self.travelTime < to.travelTime{
				return true
			}else{
				return false
			}
		}
	}
	
	func copy() -> Path{
		let toReturn = Path()
		for path in self.path{
			toReturn.travelTime = self.travelTime
			toReturn.path.append(path)
			toReturn.arrivalTimes[path] = self.arrivalTimes[path]
		}
		return toReturn
	}
}

class PathMinHeap{		//heap starts at size 20 to avoid resizing, but resize check is in place for app scaling
	var heap = [Path]()
	
	func swap(_ x: Int, y: Int){
		let temp = heap[x]
		heap[x] = heap[y]
		heap [y] = temp
	}
	func insert(_ path: Path){
		heap.append(path)
		if heap.count > 1{	//may need to heapify
			var newPathIndex = heap.count - 1
			var parentIndex = (newPathIndex - 1) / 2
			while path.compare(to: heap[parentIndex]){
				swap(newPathIndex, y: parentIndex)
				newPathIndex = parentIndex
				parentIndex = (parentIndex - 1) / 2
			}
		}
	}
	func remove() -> Path?{
		let toRemove = heap.first
		if heap.count <= 1{
			heap = [Path]()
		}else{
			heap[0] = heap[heap.count - 1]
			heap.removeLast()
			reheap(0)
		}
		return toRemove
	}
	func isEmpty() -> Bool{
		return heap.count < 1
	}

	func print() -> String{
		if isEmpty(){
			return "empty"
		}else{
			var toReturn = ""
			for node in heap{
				toReturn.append("\(node.path.last!.name), ")
			}
			return toReturn
		}
	}
	
	private func reheap(_ start: Int){	//figure out which child is shortest, and swap
		let leftIndex = (start + 1) * 2 - 1
		let rightIndex = (start + 1) * 2
		
		//end if there is no left leaf
		guard leftIndex > heap.count else{
			return
		}
		
		//run full comparison if there is also a right index
		if rightIndex < heap.count{	//right exists
			if heap[rightIndex].compare(to: heap[leftIndex]){ //right is best leaf
				if heap[rightIndex].compare(to: heap[start]){//right is better than start too
					swap(rightIndex, y: start)
					reheap(rightIndex)
				}
			}
			//no right leaf, just run comparison on left
		}else{
			if heap[leftIndex].compare(to: heap[start]){
				swap(start*2, y: start)
				reheap(start*2)
			}
		}
	}
}



















