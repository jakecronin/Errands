//
//  Cell.swift
//  Errands
//
//  Created by Jake Cronin on 7/2/17.
//
//

import Foundation
import UIKit

protocol unorderedCellDelegate {
	func upArrowPressed(cell: UnorderedCell)
	func downArrowPressed(cell: UnorderedCell)
}

class UnorderedCell: UITableViewCell{
	
	var errand: Errand?
	var delegate: unorderedCellDelegate?
	
	@IBOutlet weak var upArrow: UIButton!
	@IBOutlet weak var downArrow: UIButton!
	@IBOutlet weak var startLabel: UILabel!
	@IBOutlet weak var minutesLabel: UILabel!
	
	@IBOutlet weak var locationLabel: UILabel!	
	@IBAction func upPressed(sender: AnyObject){
		delegate?.upArrowPressed(cell: self)
	}
	@IBAction func downPressed(sender: AnyObject){
		delegate?.downArrowPressed(cell: self)
	}
	
	@IBOutlet weak var durationField: UITextField!

	
	func update(index: Int, errandsCount: Int){
		if index == 0{
			showStart()
		}else if index == errandsCount - 1{
			showEnd()
		}else{
			showNothing()
		}
	}
	
	func showStart(){
		startLabel.text = "Start"
		startLabel.textColor = UIColor.green
	}
	
	func showEnd(){
		startLabel.text = "End"
		startLabel.textColor = UIColor.red
	}
	func showNothing(){
		startLabel.text = ""
	}
	
	
}


extension UnorderedCell: UITextFieldDelegate{
	func textFieldDidEndEditing(_ textField: UITextField) {
		if let minutes = Double(textField.text!){
			self.errand?.timeAtPlace = minutes * 60
		}else{
			self.errand?.timeAtPlace = 0.0
		}
		print("set time at place for errand \(errand?.name) to \(errand?.timeAtPlace)")
	}
}
