//
//  Cell.swift
//  Errands
//
//  Created by Jake Cronin on 7/2/17.
//
//

import Foundation
import UIKit

protocol cellDelegate {
	func upArrowPressed(cell: Cell)
	func downArrowPressed(cell: Cell)
}

class Cell: UITableViewCell{
	
	var errand: Errand?
	var delegate: cellDelegate?
	
	@IBOutlet weak var upArrow: UIButton!
	@IBOutlet weak var downArrow: UIButton!
	
	@IBOutlet weak var locationLabel: UILabel!
	@IBOutlet weak var orderLabel: UILabel!
	
	@IBAction func upPressed(sender: AnyObject){
		delegate?.upArrowPressed(cell: self)
	}
	@IBAction func downPressed(sender: AnyObject){
		delegate?.downArrowPressed(cell: self)
	}


	
	
}
