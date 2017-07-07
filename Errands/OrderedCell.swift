//
//  OrderedCell.swift
//  Errands
//
//  Created by Jake Cronin on 7/5/17.
//
//

import Foundation
import UIKit


class OrderedCell: UITableViewCell{
	
	var errand: Errand?
	
	@IBOutlet weak var locationLabel: UILabel!
	@IBOutlet weak var positionLabel: UILabel!
	@IBOutlet weak var arrivalLabel: UILabel!
	@IBOutlet weak var leaveLabel: UILabel!
}
