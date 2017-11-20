//
//  DataStore.swift
//  ProximityAnalytics
//
//  Created by Jason Humphries on 11/19/17.
//  Copyright © 2017 Jason Humphries. All rights reserved.
//

import Foundation

class DataStore: NSObject {
    
    static let sharedInstance: DataStore = {
        return DataStore()
    }()
    
    //MARK: DiscoveredPeripherals
    
    private var discoveredPeripherals: [DiscoveredPeripheral] = []
    
    func addDiscoveredPeripheral(_ peripheral: DiscoveredPeripheral) {
        let desiredPeripheral = self.discoveredPeripherals.filter({ $0.identifier == peripheral.identifier }).first
        if desiredPeripheral == nil {
            self.discoveredPeripherals.append(peripheral)
        }
    }
    
    func getDiscoveredPeripherals() -> [DiscoveredPeripheral] {
        return self.discoveredPeripherals
    }
    
    func removeDiscoveredPeripheral(_ peripheral: DiscoveredPeripheral) {
        let x = self.discoveredPeripherals.index { p -> Bool in
            return p.identifier == peripheral.identifier
        }
        guard let pIndex = x else { return }
        self.discoveredPeripherals.remove(at: pIndex)
    }
    
    
    //MARK: UserDefaults
    
    static let userDefaults = UserDefaults.standard
    
    static func saveMyBluetoothPeripheralName(_ name: String) {
        userDefaults.set(name, forKey: Constants.MyBluetoothPeripheralNameKey)
        userDefaults.synchronize()
    }
    
    static func getMyBluetoothPeripheralName() -> String? {
        if let name = userDefaults.string(forKey: Constants.MyBluetoothPeripheralNameKey) {
            return name
        }
        return nil
    }
}
