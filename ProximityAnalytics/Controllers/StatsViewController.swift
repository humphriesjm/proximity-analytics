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
    
}

