//
//  BluetoothTracker.swift
//  ProximityAnalytics
//
//  Created by Jason Humphries on 11/18/17.
//  Copyright © 2017 Jason Humphries. All rights reserved.
//

import CoreBluetooth
import Foundation

// Signals to collect

//  1.    RSSI of another device
//          - How far are the other devices from me?
//          - Who is the closest to me?
//          - How does that compare to other devices?)
//  2.    Acceleration
//          - Am I moving?
//          - How quickly am I moving?
//          - Are there movements that people tend to do when they are in conversations?)
//  3.    Ambient light or camera sensor
//          - Is the phone in someone’s hand?
//          - Or is it in a pocket or purse?
//  4.    Pitch, yaw, and roll
//          - What do these values look like when someone is actively using/holding the phone?
//          - What do they look like when the phone is stored away and they are standing or walking?
//  5.    Magnetic data
//          - Does this data change when approaching another device?
//          - How can we use these numbers to determine where the phone is on a person?
//          - Can we detect direction?


let kNotificationPeripheralConnected = NSNotification.Name(rawValue: "com.humphriesj.proximity-analytics.notification.peripheralConnected")
let kNotificationPeripheralDisconnected = NSNotification.Name(rawValue: "com.humphriesj.proximity-analytics.notification.peripheralDisconnected")
let kNotificationPeripheralRSSIUpdate = NSNotification.Name(rawValue: "com.humphriesj.proximity-analytics.notification.peripheralRSSIUpdate")


class BlueToothTracker: NSObject {
    static let sharedInstance: BlueToothTracker = {
        return BlueToothTracker()
    }()
    
    // hello service
    //static let helloServiceUUID = "D51BE279-655A-4413-815E-5F560681C2D0"
    static let helloServiceUUID = "655A"
    let beviiBTHelloServiceCBUUID = CBUUID(string: helloServiceUUID)
    
    var characteristic: CBMutableCharacteristic?
    var service: CBMutableService?
    
    public var isCentralRunning: Bool = false
    public var isPeripheralRunning: Bool = false
    var rssiReadTimer: Timer?
    
    var btCentralManager: CBCentralManager?
    var btPeripheralManager: CBPeripheralManager?
    
    var valueData: NSMutableData?
    
    fileprivate override init() {
        super.init()
        print("-- BlueToothTracker init -")
    }
    
    func startBluetoothCentral() {
        // 1)
        if self.btCentralManager == nil {
            let opts = [CBCentralManagerOptionShowPowerAlertKey: true, CBCentralManagerOptionRestoreIdentifierKey: "bluetoothCentralRestoreKey"] as [String : Any]
            self.btCentralManager = CBCentralManager(delegate: self, queue: nil, options: opts)
            print("-- btsk << 1 >> startBluetoothCentral() -- btCentralManager created -")
            self.isCentralRunning = true
        }
    }
    
    func startBluetoothPeripheral() {
        if self.btPeripheralManager == nil {
            self.btPeripheralManager = CBPeripheralManager(delegate: self, queue: nil)
            print("-- startBluetoothPeripheral() -- btPeripheralManager created -")
            self.isPeripheralRunning = true
        }
    }
    
    func updateCharacteristicValue() {
        guard let char = self.characteristic else {
            print("*** ERROR: self.characteristic is nil!!")
            return
        }
        let data = "Hello Friend!".data(using: .utf8)
        char.value = data!
        self.btPeripheralManager?.updateValue(data!, for: char, onSubscribedCentrals: nil)
    }
}





extension BlueToothTracker: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("-- btsk - \(#function)")
        if central.state == .poweredOn {
            // 2)
            let scanOptions = [ CBCentralManagerScanOptionAllowDuplicatesKey : true]
            self.btCentralManager?.scanForPeripherals(withServices: [self.beviiBTHelloServiceCBUUID], options: scanOptions)
            print("-- btsk << 2 >> - scanForPeripherals()")
        } else {
            print("-- btsk - NOT scanning -")
        }
    }
    
    //  (called on the queue given when CBCentralManager is created)  (advertisementData is from the manufacturer)
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // 3)
        guard RSSI.intValue != 127 else { return }
        let txPower = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataTxPowerLevelKey) as? String
        assert(txPower == nil, "txPower is NOT NIL!?!?!")
        print("-- btsk - didDiscover peripheral: \(String(peripheral.identifier.uuidString.prefix(4))); RSSI: \(RSSI)")
        
        let desiredPeripheral = DataStore.sharedInstance.getDiscoveredPeripherals().filter({ $0.identifier == peripheral.identifier.uuidString }).first
        if desiredPeripheral != nil && desiredPeripheral?.peripheral.state != .disconnected {
            desiredPeripheral!.rssiValues.append(RSSI.intValue)
            desiredPeripheral!.timeValues.append(Date().timeIntervalSince1970)
            print("-- btsk - updated LocalPeripheral. RSSI average: \(desiredPeripheral!.rssiAverage())")
            return
        } else {
            peripheral.delegate = self
            let deviceName = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? String
            let discoveredPeripheral = DiscoveredPeripheral(identifier: peripheral.identifier.uuidString, deviceName: deviceName ?? String(peripheral.identifier.uuidString.prefix(4)), peripheral: peripheral, rssiValues: [RSSI.intValue], timeValues: [Date().timeIntervalSince1970])
            DataStore.sharedInstance.addDiscoveredPeripheral(discoveredPeripheral)
            print("-- btsk << 3 >> connect(peripheral) - name: \(deviceName ?? "no name :(") -- peripheral id: \(peripheral.identifier.uuidString.prefix(4))")
            self.btCentralManager?.connect(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : true])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // CONNECTION ESTABLISHED TO PERIPHERAL
        print("-- btsk - didConnect peripheral. identifier: (\(peripheral.identifier)); name: (\(peripheral.name ?? "no name"))")
        if peripheral.state == .connected {
            // 4)
            print("-- btsk << 4 >> discoverServices()")
            peripheral.discoverServices([self.beviiBTHelloServiceCBUUID])
            var peripheralName = String(peripheral.identifier.uuidString.prefix(4))
            let desiredPeripheral = DataStore.sharedInstance.getDiscoveredPeripherals().filter({ $0.identifier == peripheral.identifier.uuidString }).first
            if let p = desiredPeripheral {
                peripheralName = p.deviceName
            }
            NotificationCenter.default.post(name: kNotificationPeripheralConnected, object: self, userInfo: [ "peripheralName" : peripheralName ])
        } else {
            print("-- btsk - didConnect peripheral - peripheral.state != .connected \(peripheral.state)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("-- btsk - \(#function)")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        // CONNECTION TO PERIPHERAL FAILED
        print("-- btsk - didFailToConnect. peripheral: \(peripheral); error: \(String(describing: error?.localizedDescription))")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("-- btsk - didDisconnectPeripheral. peripheral: \(peripheral.description); error: \(String(describing: error?.localizedDescription))")
        var peripheralName = String(peripheral.identifier.uuidString.prefix(4))
        let desiredPeripheral = DataStore.sharedInstance.getDiscoveredPeripherals().filter({ $0.identifier == peripheral.identifier.uuidString }).first
        if let p = desiredPeripheral {
            peripheralName = p.deviceName
            DataStore.sharedInstance.removeDiscoveredPeripheral(p)
            NotificationCenter.default.post(name: kNotificationPeripheralDisconnected, object: self, userInfo: [ "peripheralName" : peripheralName ])
        }
        //print("-- btsk - CALLING connect(peripheral) AGAIN BECAUSE IT DISCONNECTED")
        //self.btCentralManager?.connect(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : true])
    }
    
}







extension BlueToothTracker: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("-- btsk - \(#function)")
        if let services = peripheral.services {
            for service in services {
                // 5)
                print("-- btsk << 5 >> discoverCharacteristics() - service: \(service)")
                peripheral.discoverCharacteristics([self.beviiBTHelloServiceCBUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("-- btsk - \(#function)")
        if service.uuid == self.beviiBTHelloServiceCBUUID {
            if let characteristics = service.characteristics {
                // 6)
                for char in characteristics {
                    if char.uuid == self.beviiBTHelloServiceCBUUID {
                        print("-- btsk << 6 >> peripheral.setNotifyValue(true) AND peripheral.readValue(for: char) - char: \(char)")
                        peripheral.readValue(for: char) // "read the latest value"
                        peripheral.setNotifyValue(true, for: char) // "tell us when something changes"
                    }
                }
            }
        } else {
            print("\n-- btsk - didDiscoverChar - WRONG SERVICE: service.uuid: \(service.uuid.uuidString)")
        }
    }
    
    // NOTE: iOS won't tell us if this is NOTIFY or READ
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("-- btsk - \(#function)")
        // 7)
        print("-- btsk - CALLING readRSSI()")
        peripheral.readRSSI()
        if characteristic.uuid == self.beviiBTHelloServiceCBUUID {
            if let characteristicData = characteristic.value {
                let resultValue = [UInt8](characteristicData)
                let stringFromData = NSString(data: characteristicData, encoding: String.Encoding.utf8.rawValue)
                print("-- btsk << 7 >> peripheral didUpdateValueForChar \(String(describing: characteristicData)) \nresultValue: \(resultValue) \nString(data): \(stringFromData ?? "stringFromData error"), peripheral: \(peripheral.identifier.uuidString.prefix(4))")
            } else {
                print("-- btsk << 7 >> peripheral didUpdateValueForChar (NO CHAR.VALUE DATA) \(String(describing: characteristic)), peripheral: \(peripheral.identifier.uuidString.prefix(4))")
            }
        }
        
        self.rssiReadTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            if peripheral.state == .connected {
                print("-- btsk - CALLING readRSSI() IN LOOP")
                peripheral.readRSSI()
            } else {
                print("-- btsk - NOT calling readRSSI() IN LOOP. peripheral is not connected. -- peripheral id: \(peripheral.identifier.uuidString.prefix(4))")
                if self.btCentralManager?.state == .poweredOn {
                    self.btCentralManager?.cancelPeripheralConnection(peripheral)
                } else {
                    print("-- btsk - btCentralManager is not .poweredOn")
                }
            }
        }
        
        // additional stuff available on the characteristic:
        //print("-- btsk - characteristic.properties: \(characteristic.properties)")
        //print("-- btsk - characteristic.isNotifying: \(characteristic.isNotifying)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        print("-- btsk - \(#function)")
        let discoveredPeripherals = DataStore.sharedInstance.getDiscoveredPeripherals()
        if !discoveredPeripherals.isEmpty {
            if let desiredPeripheral = discoveredPeripherals.filter({ $0.identifier == peripheral.identifier.uuidString }).first {
                if desiredPeripheral.peripheral.state != .disconnected {
                    desiredPeripheral.rssiValues.append(RSSI.intValue)
                    desiredPeripheral.timeValues.append(Date().timeIntervalSince1970)
                    print("-- btsk - updated LocalPeripheral: \(desiredPeripheral.identifier.prefix(4)) -- RSSI average: \(desiredPeripheral.rssiAverage())")
                    desiredPeripheral.saveDataJSON()
                    NotificationCenter.default.post(name: kNotificationPeripheralRSSIUpdate, object: self, userInfo: [ "peripheralName" : desiredPeripheral.deviceName ])
                } else {
                    print("-- btsk - desiredPeripheral state != .disconnected")
                }
            }
        }
        print("-- btsk - ****  DID READ RSSI: \(RSSI)  ****")
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("-- btsk - \(#function)")
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("-- btsk - \(#function)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        print("-- btsk - \(#function)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("-- btsk - \(#function)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("-- btsk - \(#function)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("-- btsk - \(#function)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("-- btsk - \(#function)")
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        print("-- btsk - \(#function)")
    }
    
    @available(iOS 11.0, *)
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        print("-- btsk - \(#function)")
    }
}







extension BlueToothTracker: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("-- btsk - \(#function)")
        if peripheral.state == .poweredOn {
            self.characteristic = CBMutableCharacteristic(type: self.beviiBTHelloServiceCBUUID, properties: [CBCharacteristicProperties.read, CBCharacteristicProperties.notify, CBCharacteristicProperties.indicate, CBCharacteristicProperties.write], value: nil, permissions: [CBAttributePermissions.readable, CBAttributePermissions.writeable])
            self.service = CBMutableService(type: self.beviiBTHelloServiceCBUUID, primary: true)
            self.service!.characteristics = [self.characteristic!]
            self.btPeripheralManager?.add(self.service!)
            var myDeviceName = "Device \(arc4random_uniform(100))"
            if let myName = DataStore.getMyBluetoothPeripheralName() {
                myDeviceName = myName
            }
            let advertisementDict = [ CBAdvertisementDataServiceUUIDsKey : [self.service!.uuid], CBAdvertisementDataLocalNameKey: myDeviceName ] as [String : Any]
            print("-- btsk (p) - Added Service & Started Advertising. dict: \(advertisementDict)")
            self.btPeripheralManager?.startAdvertising(advertisementDict)
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print("-- btsk (p) - peripheralManagerIsReady. peripheral: \(peripheral.description)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("-- btsk (p) - didReceiveRead. peripheral: \(peripheral.description); request: \(request.description)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("-- btsk - \(#function)")
        if error != nil {
            print("-- btsk (p) didAdd service. ERROR: \(error?.localizedDescription ?? "?")")
            return
        }
        print("-- btsk (p) didAdd service \(service.uuid) - \(service.description) -- SUCCESS")
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, didReceiveReadRequest request: CBATTRequest!) {
        print("-- btsk - \(#function)")

        if request.characteristic.uuid.isEqual(self.characteristic?.uuid) {
            // Set the correspondent characteristic's value to the request
            request.value = self.characteristic?.value
            
            // Respond to the request
            print("-- btsk (p) respond(to request)")
            self.btPeripheralManager?.respond(to: request, withResult: .success)
        }
        
//        if request.characteristic.uuid == self.characteristic?.uuid {
//            if request.offset > self.characteristic!.value!.count {
//                return peripheral.respond(to: request, withResult: CBATTError.invalidOffset)
//            } else {
//                let subdata = self.characteristic!.value?.subdata(in: request.offset ..< (self.characteristic!.value!.count - request.offset))
//                request.value = subdata
//
//                self.btPeripheralManager?.respond(to: request, withResult: .success)
//            }
//        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("-- btsk (p) - didReceiveWrite. peripheral: \(peripheral.description); requests: \(requests)")
        for request in requests {
            if request.characteristic.uuid.isEqual(characteristic?.uuid) {
                // Set the request's value to the correspondent characteristic
                self.characteristic?.value = request.value
            }
        }
        self.btPeripheralManager?.respond(to: requests[0], withResult: .success)
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("-- btsk (p) - peripheralManagerDidStartAdvertising. peripheral: \(peripheral.description)")
        if error != nil {
            print("-- btsk (p) peripheralManagerDidStartAdvertising. ERROR: \(String(describing: error))")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("-- btsk (p) - peripheral didSubscribeTo. central: \(central.description) characteristic: \(characteristic.description)")
    }
}


