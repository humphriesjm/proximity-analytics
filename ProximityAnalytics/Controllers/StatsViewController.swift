//
//  SecondViewController.swift
//  ProximityAnalytics
//
//  Created by Jason Humphries on 11/18/17.
//  Copyright © 2017 Jason Humphries. All rights reserved.
//

import UIKit

class StatsViewController: UIViewController {
    
    @IBOutlet weak var readDataButton: UIButton!
    @IBOutlet weak var dataTextView: UITextView!
    @IBOutlet weak var shareBBI: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func readDataPressed(_ sender: UIButton) {
        let discoveredPeripherals = DataStore.sharedInstance.getDiscoveredPeripherals()
        if !discoveredPeripherals.isEmpty {
            //if let desiredPeripheral = discoveredPeripherals.filter({ $0.identifier == peripheral.identifier.uuidString }).first {
            discoveredPeripherals.forEach({ peripheral in
                if let thisPeripheralJSON = peripheral.readDataJSON() {
                    self.dataTextView.text = "\(thisPeripheralJSON)"
                }
            })
        }
    }
    
    @IBAction func readAllDataPressed(_ sender: UIButton) {
        if let allJSON = DataStore.sharedInstance.readAllDataJSON() {
            self.dataTextView.text = allJSON
        } else {
            self.dataTextView.text = "NO JSON IN FILE"
        }
    }
    
    @IBAction func shareBBIPressed(_ sender: UIBarButtonItem) {
        guard let text = self.dataTextView.text else {
            print("NO TEXT")
            return
        }
        let textToShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.excludedActivityTypes = [ UIActivityType.postToFacebook ]
        self.present(activityViewController, animated: true, completion: nil)
    }
}

