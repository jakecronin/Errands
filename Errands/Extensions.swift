//
//  Extensions.swift
//  Errands
//
//  Created by Jake Cronin on 7/4/17.
//
//

import Foundation


extension TimeInterval{
	var milliseconds: Int{
		return Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
	}
	var seconds: Int{
		return Int(self.remainder(dividingBy: 60))
	}
	var minutes: Int{
		return Int((self/60).remainder(dividingBy: 60))
	}
	var hours: Int{
		return Int(self / (60*60))
	}
	var stringTime: String{
		if self.hours != 0{
			return "\(self.hours)h \(self.minutes)m \(self.seconds)s"
		}else if self.minutes != 0{
			return "\(self.minutes)m \(self.seconds)s"
		}else if self.milliseconds != 0{
			return "\(self.seconds)s \(self.milliseconds)ms"
		}else{
			return "\(self.seconds)s"
		}
	}
}
