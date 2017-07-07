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
import iAd



class HomeViewController: UIViewController{
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var calculateButton: UIButton!
	
	@IBOutlet weak var arrivalTimeLabel: UILabel!
	@IBOutlet weak var durationLabel: UILabel!
	
	@IBOutlet weak var timeInput: UITextField!
	
	var activityIndicator = UIActivityIndicatorView()
	
	var ordered = false
	var travelTime: Double?
	//var arrivalTime
	
	var errands: [Errand] = []{
		didSet{
			setUnordered()
		}
	}
	var errandsManager = ErrandsManager()
	
}

extension HomeViewController{
	override func viewDidLoad() {
		self.canDisplayBannerAds = true
		errandsManager = ErrandsManager()
		errandsManager.delegate = self
		
		timeInput.text = Date().displayDate
		let datePickerView: UIDatePicker = UIDatePicker()
		datePickerView.date = Date()
		timeInput.inputView = datePickerView
		datePickerView.addTarget(self, action: #selector(self.dateValueChanged(_:)), for: UIControlEvents.valueChanged)
		addToolBar(to: timeInput)

	}
	func setUnordered(){
		arrivalTimeLabel.text = "Arrival Time Not Calculated"
		durationLabel.text = "Duration Not Calcualted"
		self.ordered = false
	}
	func setOrdered(){
		self.ordered = true
		if travelTime != nil{
			durationLabel.text = "Time on road: \(travelTime!.stringTime)"
		}
		if let last = errands.last{
			arrivalTimeLabel.text = "Arrive at final location: \(errands.last!.timeOfArrival.displayDate)"
		}
		tableView.reloadData()
	}
	
	func beginActivityIndicator(){
		activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
		activityIndicator.center = self.view.center
		activityIndicator.hidesWhenStopped = true
		activityIndicator.color = themeMainColor
		self.view.addSubview(activityIndicator)
		activityIndicator.startAnimating()
		UIApplication.shared.beginIgnoringInteractionEvents()
	}
	func stopActivityIndicator(){
		self.activityIndicator.stopAnimating()
		UIApplication.shared.endIgnoringInteractionEvents()
	}
	
	func dateValueChanged(_ sender: UIDatePicker){
		timeInput.text = sender.date.displayDate
	}
	
	fileprivate func getPositionText(index: Int) -> String{
		switch index {
		case 0:
			return "Start"
		case errands.count - 1:
			return "Finish"
		default:
			return "\(index)"
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
		return t.stringTime
	}
	func addToolBar(to textField: UITextField){
		let toolBar = UIToolbar()
		toolBar.barStyle = .default
		toolBar.isTranslucent = true
		toolBar.tintColor = themeMainColor
		let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePressed))
		toolBar.setItems([doneButton], animated: false)
		
		toolBar.isUserInteractionEnabled = true
		toolBar.sizeToFit()
		textField.inputAccessoryView = toolBar
	}
	func donePressed() {
		view.endEditing(true)
	}
}

extension HomeViewController: ErrandsManagerDelegate{
	func didGetShortestPath(path: [Errand]?, duration: Double?){
		guard path != nil else{
			print("error, got shortest path, but it was nil. not chanigng array")
			return
		}
		errands = path!
		travelTime = duration
		setOrdered()
		stopActivityIndicator()
	}
}

//Actions or Events
extension HomeViewController{
	@IBAction func calculateButton(_ sender: UIButton){
		guard errands.count >= 2 else{
			print("not enough places to calculate optimal rout")
			return
		}
		guard errands.count < 6 else{
			print("error, too many locations.")
			return
		}
		beginActivityIndicator()
		if let date = timeInput.text?.dateFromDisplay{
			errands[0].timeOfArrival = date
		}else{
			errands[0].timeOfArrival = Date()
		}
		errandsManager.constructShortestPath(with: errands, startIndex: 0, endIndex: errands.count-1)
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
		if ordered{
			let cell = tableView.dequeueReusableCell(withIdentifier: "OrderedCell") as! OrderedCell
			cell.errand = errands[indexPath.row]
			cell.locationLabel.text = errands[indexPath.row].name
			cell.positionLabel.text = getPositionText(index: indexPath.row)
			cell.positionLabel.textColor = themeMainColor
			let arrive = errands[indexPath.row].timeOfArrival
			let timeAt = errands[indexPath.row].timeAtPlace
			cell.arrivalLabel.text = "Arrive at: \(arrive.displayDate)"
			cell.leaveLabel.text = "Leave at: \(arrive.addingTimeInterval(timeAt).displayDate)"
			return cell
		}else if indexPath.row == errands.count{
			return tableView.dequeueReusableCell(withIdentifier: "AddCell") as! AddCell
		}else{
			let cell = tableView.dequeueReusableCell(withIdentifier: "UnorderedCell") as! UnorderedCell
			cell.locationLabel.text = errands[indexPath.row].name
			cell.errand = errands[indexPath.row]
			cell.delegate = self
			cell.update(index: indexPath.row, errandsCount: errands.count)
			addToolBar(to: cell.durationField)
			return cell
		}
	}
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
		if ordered{
			return errands.count
		}else{
			return errands.count + 1
		}
	}
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath){
		if editingStyle == UITableViewCellEditingStyle.delete{
			errands.remove(at: (indexPath as NSIndexPath).row)
			tableView.reloadData()
		}
	}
	func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		if indexPath.row == errands.count{
			return true
		}else{
			return false
		}
	}
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		print("selected cell")
		if let cell = tableView.cellForRow(at: indexPath) as? AddCell{
			performSegue(withIdentifier: "segueToMap", sender: self)
		}
	}
	func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		print("moving cell")
		if let cell = tableView.cellForRow(at: sourceIndexPath) as? UnorderedCell{
			if sourceIndexPath.row == 0{
				cell.showStart()
			}else if sourceIndexPath.row == errands.count - 1{
				cell.showEnd()
			}else{
				cell.showNothing()
			}
		}else if let cell = tableView.cellForRow(at: destinationIndexPath) as? UnorderedCell{
			if destinationIndexPath.row == 0{
				cell.showStart()
			}else if destinationIndexPath.row == errands.count - 1{
				cell.showEnd()
			}else{
				cell.showNothing()
			}
		}
	}
}

extension HomeViewController: unorderedCellDelegate{
	func upArrowPressed(cell: UnorderedCell) {
		print("up pressed for \(cell.errand!.name)")
		for i in 1..<errands.count {//start at second one, because first cannot move up
			if errands[i] == cell.errand!{
				errands[i] = errands[i - 1]
				errands[i - 1] = cell.errand!
				let at = IndexPath(row: i, section: 0)
				let to = IndexPath(row: i-1, section: 0)
				let movingUp = tableView.cellForRow(at: at) as! UnorderedCell
				let movingDown = tableView.cellForRow(at: to) as! UnorderedCell
				movingUp.update(index: i-1, errandsCount: errands.count)
				movingDown.update(index: i, errandsCount: errands.count)
				tableView.moveRow(at: at, to: to)
				return
			}
		}
	}
	func downArrowPressed(cell: UnorderedCell) {
		print("down pressed for \(cell.errand!.name)")
		for i in 0..<errands.count - 1{	//only go to second to last, because last cannot be moved down
			if errands[i] == cell.errand!{
				errands[i] = errands[i+1]
				errands[i+1] = cell.errand!
				let at = IndexPath(row: i, section: 0)
				let to = IndexPath(row: i+1, section: 0)
				let movingDown = tableView.cellForRow(at: at) as! UnorderedCell
				let movingUp = tableView.cellForRow(at: to) as! UnorderedCell
				movingDown.update(index: i+1, errandsCount: errands.count)
				movingUp.update(index: i, errandsCount: errands.count)
				tableView.moveRow(at: at, to: to)
				return
			}
		}
	}
	
}



















