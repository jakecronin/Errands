//
//  AdViewController.swift
//  Errands
//
//  Created by Jake Cronin on 7/7/17.
//
//

import Foundation
import UIKit
import GoogleMobileAds

class AdViewController: UIViewController{
	var activityIndicator = UIActivityIndicatorView()

	override func viewDidLoad() {
		print("view did load, loading ad")
		GADRewardBasedVideoAd.sharedInstance().delegate = self
	}
	
	override func viewDidAppear(_ animated: Bool) {
		presentAd()
	}
	func presentAd(){
		beginActivityIndicator()
		let request = GADRequest()
		//request.testDevices = [kGADSimulatorID, "9D6F8FE6-6ACA-5E9A-A496-61A0AE85D71A"]
		GADRewardBasedVideoAd.sharedInstance().load(request, withAdUnitID: "ca-app-pub-7240573263963478/2266054941")
	}
	func beginActivityIndicator(){
		activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
		activityIndicator.center = self.view.center
		activityIndicator.hidesWhenStopped = true
		activityIndicator.color = themeMainColor
		self.view.addSubview(activityIndicator)
		activityIndicator.startAnimating()
	}
	func stopActivityIndicator(){
		self.activityIndicator.stopAnimating()
	}
	
	
}
extension AdViewController: GADRewardBasedVideoAdDelegate{
	
	func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd,
	                        didRewardUserWith reward: GADAdReward) {
		print("Reward received with currency: \(reward.type), amount \(reward.amount).")
	}
	
	func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd:GADRewardBasedVideoAd) {
		print("Reward based video ad is received.")
		if GADRewardBasedVideoAd.sharedInstance().isReady == true {
			GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: self)
			stopActivityIndicator()
		}
		
	}
	
	func rewardBasedVideoAdDidOpen(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
		print("Opened reward based video ad.")
	}
	
	func rewardBasedVideoAdDidStartPlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
		print("Reward based video ad started playing.")
	}
	
	func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
		print("Reward based video ad is closed.")
		tabBarController?.selectedIndex = 0
	}
	
	func rewardBasedVideoAdWillLeaveApplication(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
		print("Reward based video ad will leave application.")
	}
	
	func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd,
	                        didFailToLoadWithError error: Error) {
		print("Reward based video ad failed to load.")
		tabBarController?.selectedIndex = 0
	}
}
