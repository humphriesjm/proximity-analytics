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
    var peripheralConnectedObserver: NSObjectProtocol?
    var peripheralDisconnectedObserver: NSObjectProtocol?
    var peripheralNames: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addPeripheralConnectionChangeNotificationObservers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removePeripheralConnectionChangeNotificationObservers()
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
        return self.peripheralNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "nodeCell", for: indexPath)
        cell.textLabel?.text = ""
        cell.detailTextLabel?.text = ""
        if !self.peripheralNames.isEmpty {
            cell.textLabel?.text = self.peripheralNames[indexPath.row]
            //cell.detailTextLabel?.text = "Strength:"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    
    func addPeripheralConnectionChangeNotificationObservers() {
        self.peripheralConnectedObserver = NotificationCenter.default.addObserver(forName: kNotificationPeripheralConnected,
                                                                                  object: nil,
                                                                                  queue: nil,
                                                                                  using: peripheralConnectedNotification)
        self.peripheralDisconnectedObserver = NotificationCenter.default.addObserver(forName: kNotificationPeripheralDisconnected,
                                                                                     object: nil,
                                                                                     queue: nil,
                                                                                     using: peripheralDisconnectedNotification)
    }
    
    func removePeripheralConnectionChangeNotificationObservers() {
        NotificationCenter.default.removeObserver(self.peripheralConnectedObserver as Any)
        NotificationCenter.default.removeObserver(self.peripheralDisconnectedObserver as Any)
    }
    
    func peripheralConnectedNotification(notification: Notification) {
        print("- peripheralConnectedNotification, userInfo: \(String(describing: notification.userInfo ?? [:]))")
        if let peripheralName = notification.userInfo!["peripheralName"] as? String {
            if !self.peripheralNames.contains(peripheralName) {
                self.peripheralNames.append(peripheralName)
                self.tableView.reloadData()
            }
        }
    }
    
    func peripheralDisconnectedNotification(notification: Notification) {
        print("- peripheralDisconnectedNotification, userInfo: \(String(describing: notification.userInfo ?? [:]))")
        if let peripheralName = notification.userInfo!["peripheralName"] as? String {
            if self.peripheralNames.contains(peripheralName) {
                if let x = self.peripheralNames.index(of: peripheralName) {
                    self.peripheralNames.remove(at: x)
                    self.tableView.reloadData()
                }
            }
        }
    }


}

