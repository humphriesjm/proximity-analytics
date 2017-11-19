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

class BlueToothTracker: NSObject {
    static let sharedInstance: BlueToothTracker = {
        return BlueToothTracker()
    }()
    
    // hello service
    //static let helloServiceUUID = "D51BE279-655A-4413-815E-5F560681C2D0"
    static let helloServiceUUID = "655A"
    let beviiBTHelloServiceCBUUID = CBUUID(string: helloServiceUUID)
    // hello service -> ID characteristic
    //static let helloIDCharacteristicUUID = "EEBEA6C5-28B1-45E5-90F8-EA9A1AAB9B64"
    static let helloIDCharacteristicUUID = "28B1"
    let beviiBTHelloIDCharacteristicCBUUID = CBUUID(string: helloIDCharacteristicUUID)
    // hello service -> Notify characteristic
    //static let helloNotifyCharacteristicUUID = "B8CE525D-0447-4AA5-8446-313DC65FA372"
    static let helloNotifyCharacteristicUUID = "0447"
    let beviiBTHelloNotifyCharacteristicCBUUID = CBUUID(string: helloNotifyCharacteristicUUID)
    
    var characteristic: CBMutableCharacteristic?
    var service: CBMutableService?
    
    public var isCentralRunning: Bool = false
    public var isPeripheralRunning: Bool = false
    
    var btCentralManager: CBCentralManager?
    var btPeripheralManager: CBPeripheralManager?
    //var peripherals: [CBPeripheral] = []
    var peripheral: CBPeripheral?
    
    fileprivate override init() {
        super.init()
        print("-- BlueToothTracker init -")
    }
    
    func startBluetoothCentral() {
        // 1)
        let opts = [CBCentralManagerOptionShowPowerAlertKey: true]
        self.btCentralManager = CBCentralManager(delegate: self, queue: nil, options: opts)
        print("-- startBluetoothCentral() -- btCentralManager created -")
        self.isCentralRunning = true
    }
    
    func startBluetoothPeripheral() {
        self.btPeripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        print("-- startBluetoothPeripheral() -- btPeripheralManager created -")
        self.isPeripheralRunning = true
    }
    
    func updateCharacteristicValue() {
        let data = "Hello Friend!".data(using: .utf8)
        self.characteristic?.value = data!
        self.btPeripheralManager?.updateValue(data!, for: self.characteristic!, onSubscribedCentrals: nil)
    }
}





extension BlueToothTracker: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("-- btsk - \(#function)")
        if central.state == .poweredOn {
            // 2)
            let scanOptions = [ CBCentralManagerScanOptionAllowDuplicatesKey : true]
            self.btCentralManager?.scanForPeripherals(withServices: [self.beviiBTHelloServiceCBUUID], options: scanOptions)
            print("-- btsk - didUpdateState. btCentralManager scanning -")
        } else {
            print("-- btsk - didUpdateState. btCentralManager NOT scanning -")
        }
    }
    
    // 3)
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("-- btsk - didDiscover peripheral: \(peripheral.description); RSSI: \(RSSI); RSSI.stringValue: \(RSSI.stringValue); advertisementData: \(advertisementData)")
        
        // 4)
        self.peripheral = peripheral
        self.btCentralManager?.connect(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : true])
    }
    
    // 5)
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // CONNECTION ESTABLISHED TO PERIPHERAL
        print("-- btsk - didConnect peripheral with identifier(\(peripheral.identifier)) and name(\(peripheral.name ?? "no name"))")
        peripheral.delegate = self
        if peripheral.state == .connected {
            // 6)
            peripheral.discoverServices([self.beviiBTHelloServiceCBUUID])
        } else {
            print("-- btsk - didConnect. peripheral - peripheral.state != .connected \(peripheral.state)")
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
        self.btCentralManager?.connect(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : true])
    }
    
}







extension BlueToothTracker: CBPeripheralDelegate {
    
    // 7)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("-- btsk - \(#function)")
        if let services = peripheral.services {
            print("-- btsk - didDiscoverServices: \(services)")
            for service in services {
                // 8)
                print("-- btsk - discoverCharacteristics for service: \(service)")
                peripheral.discoverCharacteristics([self.beviiBTHelloServiceCBUUID], for: service)
            }
        }
    }
    
    // 9)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("-- btsk - \(#function)")
        if service.uuid == self.beviiBTHelloServiceCBUUID {
            if let characteristics = service.characteristics {
                for char in characteristics {
                    if char.uuid == self.beviiBTHelloIDCharacteristicCBUUID {
                        // 10a)
                        // read the characteristic just once, as it will not continue to update
                        peripheral.readValue(for: char)
                    } else if char.uuid == self.beviiBTHelloNotifyCharacteristicCBUUID {
                        // 10b)
                        // subscribe to updates for this characteristic, as it will continue to update
                        peripheral.setNotifyValue(true, for: char)
                    } else if char.uuid == self.beviiBTHelloServiceCBUUID {
                        // 10c)
                        peripheral.setNotifyValue(true, for: char)
                        peripheral.readValue(for: char)
                    }
                }
            }
        } else {
            print("\n-- btsk - didDiscoverChar - WRONG SERVICE: service.uuid: \(service.uuid.uuidString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("-- btsk - \(#function)")
        // 11)
        peripheral.readRSSI()
        if characteristic.uuid == self.beviiBTHelloIDCharacteristicCBUUID {
            print("-- btsk - peripheral didUpdateValueForChar \(String(describing: characteristic.value))")
        } else if characteristic.uuid == self.beviiBTHelloNotifyCharacteristicCBUUID {
            print("-- btsk - peripheral didUpdateValueForChar \(String(describing: characteristic.value))")
        } else if characteristic.uuid == self.beviiBTHelloServiceCBUUID {
            print("-- btsk - peripheral didUpdateValueForChar \(String(describing: characteristic.value))")
        }
    }
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        print("-- btsk - \(#function)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("-- btsk - \(#function)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        print("-- btsk - \(#function)")
        print("-- btsk - **** DID READ RSSI: \(RSSI)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        print("-- btsk - \(#function)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
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
            self.btPeripheralManager?.add(service!)
            let advertisementDict = [ CBAdvertisementDataServiceUUIDsKey : [service!.uuid], CBAdvertisementDataLocalNameKey: "Jason Device \(arc4random_uniform(10))" ] as [String : Any]
            self.btPeripheralManager?.startAdvertising(advertisementDict)
            print("-- btsk (p) - didUpdateState. Added Service & Started Advertising. dict: \(advertisementDict)")
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print("-- btsk (p) - peripheralManagerIsReady. peripheral: \(peripheral.description)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("-- btsk (p) - didReceiveRead. peripheral: \(peripheral.description); request: \(request.description)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("-- btsk (p) - didAdd service. service: \(service.description); error: \(String(describing: error?.localizedDescription))")
        if error != nil {
            print("-- btsk (p) didAdd service. ERROR: \(error?.localizedDescription ?? "?")")
            return
        }
        print("-- btsk (p) didAdd service \(self.beviiBTHelloServiceCBUUID.uuidString). SUCCESS")
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, didReceiveReadRequest request: CBATTRequest!) {
        NSLog("peripheralManager didReceiveReadRequest for characteristic %@", self.characteristic!)
        
        if request.characteristic.uuid.isEqual(characteristic?.uuid) {
            // Set the correspondent characteristic's value to the request
            request.value = self.characteristic?.value
            
            // Respond to the request
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


