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
typealias RSSIJSONData = [ String : [ String : Any ] ]

// array of JSON objects that show this device's acceleration data over time
// 2) [ deviceName: { timestamp : [ { "x" : accelerationX, "y" : accelerationY, "z" : accelerationZ, "rotation" : rotation } ] } ]
typealias AccelerationJSONData = [ String : [ String : Any ] ]

// array of JSON objects that show this device's pitch, roll, and yaw over time
// 3) [ deviceName:  { timestamp : [ { "roll" : roll, "pitch" : pitch, "yaw" : yaw } ] } ]
typealias EulerJSONData = [ String : [ String : Any ] ]

// array of JSON objects that show this device's magnetic data over time
// 4) [ deviceName: { "timestamp" : "12313131231", "x" : magneticX, "y" : magneticY, "z" : magneticZ, "accuracy" : accuracy } ]
typealias MagneticJSONData = [ String : [ String : Any ] ]


class DataStore: NSObject {
    
    static let sharedInstance: DataStore = {
        return DataStore()
    }()
    
    var accelerationJSONData = [AccelerationJSONData]()
    var eulerJSONData = [EulerJSONData]()
    var magneticJSONData = [MagneticJSONData]()
    
    var accelerationWriteCount = 0
    var eulerWriteCount = 0
    var magneticWriteCount = 0
    
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
    
    static func saveMyDeviceName(_ name: String) {
        userDefaults.set(name, forKey: Constants.MyDeviceNameKey)
        userDefaults.synchronize()
    }
    
    static func getMyDevicePeripheralName() -> String? {
        if let name = userDefaults.string(forKey: Constants.MyDeviceNameKey) {
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
                if fileURL.absoluteString.contains("rssi") {
                    if let rssiJsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [RSSIJSONData] {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: rssiJsonData, options: [])
                            if let jsonString = String(data: jsonData, encoding: .utf8) {
                                print("-- jsonData READING rssi file: \(jsonString)")
                                returnText.append("RSSI DATA:\n\(jsonString)\n\n")
                            }
                        } catch {
                            print(error)
                        }
                    }
                }
                if fileURL.absoluteString.contains("magnetic") {
                    if let magneticJsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [MagneticJSONData] {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: magneticJsonData, options: [])
                            if let jsonString = String(data: jsonData, encoding: .utf8) {
                                print("-- jsonData READING magnetic file: \(jsonString)")
                                returnText.append("MAGNETIC DATA:\n\(jsonString)\n\n")
                            }
                        } catch {
                            print(error)
                        }
                    }
                }
                if fileURL.absoluteString.contains("euler") {
                    if let eulerJsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [EulerJSONData] {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: eulerJsonData, options: [])
                            if let jsonString = String(data: jsonData, encoding: .utf8) {
                                print("-- jsonData READING euler file: \(jsonString)")
                                returnText.append("EULER DATA:\n\(jsonString)\n\n")
                            }
                        } catch {
                            print(error)
                        }
                    }
                }
                if fileURL.absoluteString.contains("acceleration") {
                    if let accelerationJsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [AccelerationJSONData] {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: accelerationJsonData, options: [])
                            if let jsonString = String(data: jsonData, encoding: .utf8) {
                                print("-- jsonData READING acceleration file: \(jsonString)")
                                returnText.append("ACCELERATION DATA:\n\(jsonString)\n\n")
                            }
                        } catch {
                            print(error)
                        }
                    }
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
        return url!.appendingPathComponent("Data-\(self.deviceName)-\(self.identifier.prefix(4))-rssi.json")
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
            let rssiItemObject: RSSIJSONData = [ self.deviceName : [ "timestamp" : String(format:"%.2f", self.timeValues[index]), "rssi" : element ] ]
            self.rssiJSONDataToWrite.append(rssiItemObject)
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: self.rssiJSONDataToWrite, options: [])
            try data.write(to: self.filePathURL, options: [])
            print("-- jsonData SAVING rssi data: \(NSString(data: data, encoding: 1)!)")
        } catch {
            print("**** ERROR WRITING RSSI JSON TO DISK!! error: \(error.localizedDescription)")
        }
    }
    
    func readDataJSON() -> [RSSIJSONData]? {
        do {
            let data = try Data(contentsOf: self.filePathURL, options: [])
            if let personArray = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [RSSIJSONData] {
                print("-- jsonData READING: \(personArray)")
                return personArray
            }
        } catch {
            print("**** ERROR READING RSSI FILE!! error: \(error.localizedDescription)")
        }
        return nil
    }
}

class AccelerationData {
    let x: Double
    let y: Double
    let z: Double
    let rotation: Double
    let timestampString: String
    
    init(x: Double, y: Double, z: Double, rotation: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.rotation = rotation
        self.timestampString = String(format:"%.2f", Date().timeIntervalSince1970)
    }
}

class EulerData {
    let roll: Double
    let pitch: Double
    let yaw: Double
    let timestampString: String

    init(roll: Double, pitch: Double, yaw: Double) {
        self.roll = roll
        self.pitch = pitch
        self.yaw = yaw
        self.timestampString = String(format:"%.2f", Date().timeIntervalSince1970)
    }
}

class MagneticData {
    let x: Double
    let y: Double
    let z: Double
    let accuracy: Double
    let timestampString: String

    init(x: Double, y: Double, z: Double, accuracy: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.accuracy = accuracy
        self.timestampString = String(format:"%.2f", Date().timeIntervalSince1970)
    }
}



extension DataStore {

    //MARK: Disk write/read JSON

    func accelerationFilePathURL() -> URL {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
        let deviceName = DataStore.getMyDevicePeripheralName() ?? "Unknown"
        return url!.appendingPathComponent("Data-\(deviceName)-acceleration.json")
    }

    func eulerFilePathURL() -> URL {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
        let deviceName = DataStore.getMyDevicePeripheralName() ?? "Unknown"
        return url!.appendingPathComponent("Data-\(deviceName)-euler.json")
    }

    func magneticFilePathURL() -> URL {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
        let deviceName = DataStore.getMyDevicePeripheralName() ?? "Unknown"
        return url!.appendingPathComponent("Data-\(deviceName)-magnetic.json")
    }

    func saveMotionDataJSON(accelerationData: AccelerationData, eulerData: EulerData, magneticData: MagneticData) {
        let deviceName = DataStore.getMyDevicePeripheralName() ?? "Unknown"
        
        let accelerationJSONObject: AccelerationJSONData = [ deviceName : [ "timestamp" : accelerationData.timestampString, "x" : accelerationData.x, "y" : accelerationData.y, "z" : accelerationData.z, "rotation" : accelerationData.rotation ] ]
        self.accelerationJSONData.append(accelerationJSONObject)

        do {
            let data = try JSONSerialization.data(withJSONObject: self.accelerationJSONData, options: [])
            try data.write(to: self.accelerationFilePathURL(), options: [])
            print("-- jsonData SAVING acceleration data: \(NSString(data: data, encoding: 1)!)")
        } catch {
            print("**** ERROR WRITING ACCELERATION JSON TO DISK!! error: \(error.localizedDescription)")
        }

        let eulerJSONObject: EulerJSONData = [ deviceName : [ "timestamp" : eulerData.timestampString, "roll" : eulerData.roll, "pitch" : eulerData.pitch, "yaw" : eulerData.yaw ] ]
        self.eulerJSONData.append(eulerJSONObject)

        do {
            let data = try JSONSerialization.data(withJSONObject: self.eulerJSONData, options: [])
            try data.write(to: self.eulerFilePathURL(), options: [])
            print("-- jsonData SAVING euler data: \(NSString(data: data, encoding: 1)!)")
        } catch {
            print("**** ERROR WRITING EULER MOTION JSON TO DISK!! error: \(error.localizedDescription)")
        }

        let magneticJSONObject: MagneticJSONData = [ deviceName : [ "timestamp" : magneticData.timestampString, "x" : magneticData.x, "y" : magneticData.y, "z" : magneticData.z, "accuracy" : magneticData.accuracy ] ]
        self.magneticJSONData.append(magneticJSONObject)

        do {
            let data = try JSONSerialization.data(withJSONObject: self.magneticJSONData, options: [])
            try data.write(to: self.magneticFilePathURL(), options: [])
            print("-- jsonData SAVING magnetic data: \(NSString(data: data, encoding: 1)!)")
        } catch {
            print("**** ERROR WRITING MAGNETIC JSON TO DISK!! error: \(error.localizedDescription)")
        }
    }
        
    func readAccelerationDataJSON() -> [AccelerationJSONData]? {
        do {
            let data = try Data(contentsOf: self.accelerationFilePathURL(), options: [])
            if let dataArray = try JSONSerialization.jsonObject(with: data, options: []) as? [AccelerationJSONData] {
                print("-- jsonData READING acceleration data: \(dataArray)")
                return dataArray
            }
        } catch {
            print("**** ERROR READING ACCELERATION FILE!! error: \(error.localizedDescription)")
        }
        return nil
    }
    
    func readEulerDataJSON() -> [EulerJSONData]? {
        do {
            let data = try Data(contentsOf: self.eulerFilePathURL(), options: [])
            if let dataArray = try JSONSerialization.jsonObject(with: data, options: []) as? [EulerJSONData] {
                print("-- jsonData READING euler data: \(dataArray)")
                return dataArray
            }
        } catch {
            print("**** ERROR READING EULER FILE!! error: \(error.localizedDescription)")
        }
        return nil
    }
    
    func readMagneticDataJSON() -> [MagneticJSONData]? {
        do {
            let data = try Data(contentsOf: self.magneticFilePathURL(), options: [])
            if let dataArray = try JSONSerialization.jsonObject(with: data, options: []) as? [MagneticJSONData] {
                print("-- jsonData READING magnetic data: \(dataArray)")
                return dataArray
            }
        } catch {
            print("**** ERROR READING MAGNETIC FILE!! error: \(error.localizedDescription)")
        }
        return nil
    }
}

