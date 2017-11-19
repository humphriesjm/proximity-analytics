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
    @IBOutlet weak var navBar: UINavigationBar!
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let myName = DataStore.getMyBluetoothPeripheralName() {
            let titleLabel = UILabel(frame: CGRect.zero)
            titleLabel.text = myName
            titleLabel.sizeToFit()
            self.navBar.topItem?.titleView = titleLabel
        } else {
            // prompt for name
            let nameAlertCon = UIAlertController(title: "Enter your name", message: nil, preferredStyle: .alert)
            let inputAction = UIAlertAction(title: "Save", style: .default, handler: { alert in
                let textField = nameAlertCon.textFields![0] as UITextField
                if let text = textField.text {
                    DataStore.saveMyBluetoothPeripheralName(text)
                    let titleLabel = UILabel(frame: CGRect.zero)
                    titleLabel.text = text
                    titleLabel.sizeToFit()
                    self.navBar.topItem?.titleView = titleLabel
                }
            })
            nameAlertCon.addAction(inputAction)
            nameAlertCon.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            nameAlertCon.addTextField(configurationHandler: { textField in
                textField.placeholder = "Name"
            })
            self.present(nameAlertCon, animated: true, completion: nil)
        }
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

