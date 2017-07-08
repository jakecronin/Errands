//
//  ErrandsManager.swift
//  Errands
//
//  Created by Jake Cronin on 7/5/17.
//
//

import Foundation
import MapKit

protocol ErrandsManagerDelegate {
	func didGetShortestPath(path: [Errand]?, duration: Double?)
}

class ErrandsManager{
	
	var errands: [Errand] = []
	
	var etaCallsCompleted = 0{
		didSet{
			print("callsCopmleted: \(etaCallsCompleted)")
		}
	}//track how many eta callbacks have completed, so we know when to move on
	var etaCallsToMake = 0		//how many eta callbacks we are waiting for
	
	var delegate: ErrandsManagerDelegate?
	
	fileprivate var minHeap = PathMinHeap()
	fileprivate var minPath: Path?
	
	fileprivate var endIndex: Int!
	fileprivate var startIndex: Int!

	
	func constructShortestPath(with errands: [Errand]?, startIndex: Int, endIndex: Int){
		print("constructing shortest path in errands manager")
		guard errands != nil else{
			print("cannot construct shortest path in errands manager, received errands is nil")
			return
		}
		self.errands = errands!
		self.endIndex = endIndex
		self.startIndex = startIndex
		
		//Allow each errand to know where it is for hashing
		for i in 0..<self.errands.count{
			self.errands[i].index = i
		}
		
		//initialize
		minHeap = PathMinHeap()
		minPath = nil
		let firstPath = Path(errands: errands!.count)
		firstPath.addErrand(errand: errands![startIndex], timeOfArrival: errands![startIndex].timeOfArrival)
		minHeap.insert(firstPath)
		
		print("started construct shortest path, start: \(errands![startIndex].name), End: \(errands![endIndex].name)")

		shortestPathHelper(path: firstPath)
	}
	
	fileprivate func shortestPathHelper(path: Path){
		print("Entering Shortest Path Helper on Path: \(path.toString())")
		let pathEnd = path.path.last!
		if minPath != nil && path.travelTime > minPath!.travelTime{	//There exists a better solution, trash this path.
			print("killing path, too long")
			self.finishedLookingAtPath()
			return									//kill this path
		}else if path.path.count == errands.count - 1{	//just needs the last destination!
			print("path is on last destination")
			let leaveAt = path.arrivalTimes[pathEnd]!.addingTimeInterval(pathEnd.timeAtPlace)
			print("leave time for \(errands[endIndex]) is \(leaveAt.displayDate)")
			getETA(pathEnd, to: errands[endIndex], at: leaveAt, completion: { (result) in
				guard result != nil else{
					print("error, result was nil when getting path \(pathEnd.name) to end destination \(self.errands[self.endIndex].name)")
					self.endWithError()
					return
				}
				path.travelTime = path.travelTime + result!		//update travel time
				if self.minPath == nil || path.travelTime < self.minPath!.travelTime{ //If this could be the fastest path, update minPath
					let timeOfArrival = path.arrivalTimes[pathEnd]!.addingTimeInterval(pathEnd.timeAtPlace).addingTimeInterval(result!)
					path.addErrand(errand: self.errands[self.endIndex], timeOfArrival: timeOfArrival)
					self.minPath = path
				}
				self.finishedLookingAtPath()
			})
		}else{		//get shortest path to everyone but first and last, and throw nodes onto queue if they are updated
			print("path has multiple destinations to hit: errands count \(errands.count)")
			etaCallsCompleted = 0
			etaCallsToMake = errands.count - path.path.count - 1 //call to everyone not yet in path and not last
			for i in 0..<errands.count{
				if i == self.endIndex || i == self.startIndex || path.contains(index: i){
					print("skipping index \(i), \(errands[i].name)")
					continue
				}
				print("looking at destination index \(i)")
				let newPath  = path.copy()
				let leaveAt = path.arrivalTimes[pathEnd]!.addingTimeInterval(pathEnd.timeAtPlace)
				getETA(pathEnd, to: errands[i], at: leaveAt, completion: { (result) in
					print("in getETA completion")
					self.etaCallsCompleted = self.etaCallsCompleted + 1
					guard result != nil else{
						self.endWithError()
						return	//error, kill path
					}
					let newPath = path.copy()
					newPath.travelTime = newPath.travelTime + result!
					let arrivalTime = newPath.arrivalTimes[pathEnd]!.addingTimeInterval(pathEnd.timeAtPlace).addingTimeInterval(result!)
					newPath.addErrand(errand: self.errands[i], timeOfArrival: arrivalTime)
					
					//Quick weedout of absurdly long paths
					if self.minPath == nil || newPath.travelTime < self.minPath!.travelTime{
						print("throwing path into heap")
						self.minHeap.insert(newPath)
					}
					if self.etaCallsCompleted >= self.etaCallsToMake{
						self.finishedLookingAtPath()
						return
					}else{
						print("finished \(self.etaCallsCompleted), need \(self.etaCallsToMake)")
					}
				})
			}
		}
	}
	fileprivate func getETA(_ from: Errand, to: Errand, at: Date, completion: @escaping (_ eta: Double?) -> Void){
		if from.mapItem == to.mapItem{	//do not let paths connect to themselves
			completion(nil)
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
			guard error == nil else{
				print("error getting ETA between \(from.name) and \(to.name)")
				print(error!)
				completion(nil)
				return
			}
			guard response != nil else{
				print("error, response is nil in calculateETA")
				completion(nil)
				return
			}
			eta = response!.expectedTravelTime
			completion(eta)
		}
	}
	fileprivate func finishedLookingAtPath() {	//called when finished calcing all distances from a node, move on to next
		print("completed all etacalls called with heap: \(minHeap.print())")
		if let path = minHeap.remove(){		//continue while heap is not empty
			shortestPathHelper(path: path)
		}else if delegate != nil{
			if minPath != nil{
				for errand in minPath!.path{
					errand.timeOfArrival = minPath!.arrivalTimes[errand]!
				}
			}
			delegate!.didGetShortestPath(path: minPath?.path, duration: minPath?.travelTime)
		}else{
			print("finished getting shortest path, but delegate is nil for errands manager, so result isn't going anywhere")
		}
	}
	fileprivate func endWithError(){
		delegate!.didGetShortestPath(path: nil, duration: nil)
	}

}

fileprivate class Path{	//allows maintaining multiple different paths in heap
	var path = [Errand]()
	var arrivalTimes = [Errand: Date]()
	var hash: [Bool]!		//direct hash to see who we do and do not contain
	var travelTime: Double = 0
	
	init(errands: Int) {
		hash = [Bool](repeatElement(false, count: errands))
	}
	
	func addErrand(errand: Errand, timeOfArrival: Date){
		path.append(errand)
		hash[errand.index] = true
		arrivalTimes[errand] = timeOfArrival
	}
	
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
	func contains(errand: Errand) -> Bool{
		return hash[errand.index]
	}
	func contains(index: Int) -> Bool{
		return hash[index]
	}
	
	func copy() -> Path{
		let toReturn = Path(errands: self.hash.count)
		toReturn.travelTime = self.travelTime
		
		for path in self.path{
			toReturn.path.append(path)
			toReturn.arrivalTimes[path] = self.arrivalTimes[path]
		}
		toReturn.hash = [Bool]()
		for bool in self.hash{
			toReturn.hash.append(bool)
		}
		
		return toReturn
	}
	func toString() -> String{
		var toReturn = "["
		for errand in path{
			toReturn.append("\(errand.name) ,")
		}
		toReturn.append("]")
		return toReturn
	}
}

fileprivate class PathMinHeap{		//heap starts at size 20 to avoid resizing, but resize check is in place for app scaling
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
				toReturn.append("\n\(node.toString())")
			}
			toReturn.append("\n")
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





