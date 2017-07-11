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
import GoogleMobileAds


class HomeViewController: UIViewController{
	
	var bannerView: GADBannerView!
	
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
		super.viewDidLoad()
		
		bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
		self.view.addSubview(bannerView)
		bannerView.center = self.view.center
		bannerView.frame.origin.y = self.view.frame.maxY - bannerView.frame.height - 44
		bannerView.adUnitID = bannerAdID
		bannerView.rootViewController = self
		let request = GADRequest()
		request.testDevices = [kGADSimulatorID]//, "9D6F8FE6-6ACA-5E9A-A496-61A0AE85D71A"]
		bannerView.load(request)
		
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
		if errands.last != nil{
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
		setUnordered()
		tableView.reloadData()
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
	
	func errorMessage(string: String){
		let nameAlertView = UIAlertController(title: "Error", message: string, preferredStyle: UIAlertControllerStyle.alert)
		nameAlertView.addAction(UIAlertAction(title: "Darn", style: .cancel, handler: nil))
		self.present(nameAlertView, animated: true, completion: nil)
	}
}

extension HomeViewController: ErrandsManagerDelegate{
	func didGetShortestPath(path: [Errand]?, duration: Double?){
		guard path != nil else{
			print("error, got shortest path, but it was nil. not chanigng array")
			errorMessage(string: "There was an error optimizing your route. Make sure that all destintaions can be reached by car")
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
		guard errands.count <= 6 else{
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
			cell.arrivalLabel.text = "Arrive: \(arrive.displayDate)"
			cell.leaveLabel.text = "Leave: \(arrive.addingTimeInterval(timeAt).displayDate)"
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
			if indexPath.row == 0 || indexPath.row == errands.count - 1{
				cell.durationField.text = "0"
				cell.durationField.isHidden = true
				cell.minutesLabel.isHidden = true
			}else{
				cell.durationField.isHidden = false
				cell.minutesLabel.isHidden = false
			}
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
		if (tableView.cellForRow(at: indexPath) as? AddCell) != nil{
			performSegue(withIdentifier: "segueToMap", sender: self)
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
				if i-1 == 0{
					print("editting the index \(i)")
					movingUp.durationField.text = "0"
					movingUp.durationField.isHidden = true
					movingUp.minutesLabel.isHidden = true
					movingDown.durationField.isHidden = false
					movingDown.minutesLabel.isHidden = false
				}else if i == errands.count - 1{
					movingUp.minutesLabel.isHidden = false
					movingUp.durationField.isHidden = false
					movingDown.minutesLabel.isHidden = true
					movingDown.durationField.isHidden = true
					movingDown.durationField.text = "0"
				}
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
				if i+1 == errands.count - 1{
					print("editting going down hidden stuff ")
					movingDown.durationField.text = "0"
					movingDown.durationField.isHidden = true
					movingDown.minutesLabel.isHidden = true
					movingUp.durationField.isHidden = false
					movingUp.minutesLabel.isHidden = false
				}else if i == 0{
					movingUp.minutesLabel.isHidden = true
					movingUp.durationField.isHidden = true
					movingUp.durationField.text = "0"
					movingDown.minutesLabel.isHidden = false
					movingDown.durationField.isHidden = false
				}
				return
			}
		}
	}
	
}



















