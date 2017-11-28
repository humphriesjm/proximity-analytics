//
//  DataStore.swift
//  ProximityAnalytics
//
//  Created by Jason Humphries on 11/19/17.
//  Copyright © 2017 Jason Humphries. All rights reserved.
//

import CoreBluetooth
import Foundation

// need a way to log the following data in ways that can be visualized:

// array of JSON objects that associate a device name with the rssi over time
// 1) [ deviceName { timestamp : rssi } ]
typealias RSSIJSONData = [ String : [ String : Int ] ]

// array of JSON objects that show this device's acceleration data over time
// 2) [ { timestamp : accelerationData } ]

// array of JSON objects that show this device's pitch, roll, and yaw over time
// 3) [ { timestamp : eulers (pitch, roll, yaw) } ]

// array of JSON objects that show this device's magnetic data over time
// 4) [ { timestamp : magneticData } ]


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
    
    func readAllDataJSON() -> String? {
        let manager = FileManager.default
        guard let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
            print(directoryContents)
            var returnText = ""
            // if you want to filter the directory contents you can do like this:
            let jsonFiles = directoryContents.filter{ $0.pathExtension == "json" }
            print("json urls:", jsonFiles)
            try jsonFiles.forEach({ fileURL in
                let data = try Data(contentsOf: fileURL, options: [])
                if let personArray = try JSONSerialization.jsonObject(with: data, options: []) as? [RSSIJSONData] {
                    print("-- jsonData READING: \(personArray)")
                    returnText.append("\(personArray)\n\n")
                }
            })
            let jsonFileNames = jsonFiles.map{ $0.deletingPathExtension().lastPathComponent }
            print("json list:", jsonFileNames)
            return returnText
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
}




class DiscoveredPeripheral: NSObject {
    let identifier: String
    let deviceName: String
    let peripheral: CBPeripheral
    var rssiValues: [Int]
    var timeValues: [Double]
    
    var rssiJSONDataToWrite = [RSSIJSONData]()
    
    init(identifier: String, deviceName: String, peripheral: CBPeripheral, rssiValues: [Int], timeValues: [Double]) {
        self.identifier = identifier
        self.deviceName = deviceName
        self.peripheral = peripheral
        self.rssiValues = rssiValues
        self.timeValues = timeValues
    }
    
    func rssiAverage() -> Int {
        return self.rssiValues.isEmpty ? 0 : self.rssiValues.reduce(0,+) / self.rssiValues.count
    }
    
    //MARK: Disk write/read JSON
    
    var filePathURL: URL {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
        return url!.appendingPathComponent("Data-\(self.deviceName)-\(self.identifier.prefix(4)).json")
    }
    
    var filePath: String {
        return self.filePathURL.path
    }
    
    func saveDataJSON() {
        guard self.rssiValues.count > 0 else {
            print("** NO RSSI VALUES TO WRITE IN `saveDataJSON()` !!")
            return
        }
        
        for (index, element) in self.rssiValues.enumerated() {
            let rssiItemObject: RSSIJSONData = [ self.deviceName : [ String(format:"%.2f", self.timeValues[index]) : element ] ]
            self.rssiJSONDataToWrite.append(rssiItemObject)
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: self.rssiJSONDataToWrite, options: [])
            try data.write(to: self.filePathURL, options: [])
            print("-- jsonData SAVING: \(NSString(data: data, encoding: 1)!)")
        } catch {
            print("**** ERROR WRITING RSSI JSON TO DISK!! error: \(error.localizedDescription)")
        }
    }
    
    func readDataJSON() -> [RSSIJSONData]? {
        do {
            let data = try Data(contentsOf: self.filePathURL, options: [])
            if let personArray = try JSONSerialization.jsonObject(with: data, options: []) as? [RSSIJSONData] {
                print("-- jsonData READING: \(personArray)")
                return personArray
            }
        } catch {
            print("**** ERROR READING RSSI FILE!! error: \(error.localizedDescription)")
        }
        return nil
    }
}

