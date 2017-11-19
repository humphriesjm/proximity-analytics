//
//  FirstViewController.swift
//  ProximityAnalytics
//
//  Created by Jason Humphries on 11/18/17.
//  Copyright © 2017 Jason Humphries. All rights reserved.
//

import CoreBluetooth
import UIKit

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bluetoothSwitch: UISwitch!

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func bluetoothSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            BlueToothTracker.sharedInstance.startBluetoothCentral()
            BlueToothTracker.sharedInstance.startBluetoothPeripheral()
        }
    }

    @IBAction func updateCharacteristicValue(_ sender: UIBarButtonItem) {
        BlueToothTracker.sharedInstance.updateCharacteristicValue()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0 //BlueToothTracker.sharedInstance.peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "nodeCell", for: indexPath)
        cell.textLabel?.text = ""
        cell.detailTextLabel?.text = ""
//        if !BlueToothTracker.sharedInstance.peripherals.isEmpty {
//            cell.textLabel?.text = "Peripheral \(indexPath.row + 1)"
//            cell.detailTextLabel?.text = "Strength:"
//        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }


}

