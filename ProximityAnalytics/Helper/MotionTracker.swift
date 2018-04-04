//
//  MotionTracker.swift
//  ProximityAnalytics
//
//  Created by Jason Humphries on 11/19/17.
//  Copyright © 2017 Jason Humphries. All rights reserved.
//

import CoreLocation
import CoreMotion
import Foundation

class MotionTracker: NSObject {
    static let sharedInstance: MotionTracker = {
        return MotionTracker()
    }()
    
    static let motionManager: CMMotionManager = {
       return CMMotionManager()
    }()
    
    override init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground),
                                               name: .UIApplicationDidEnterBackground,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActive),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIApplicationDidEnterBackground,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIApplicationDidBecomeActive,
                                                  object: nil)
    }
    
    func startDeviceMotion(withUpdateHandler updateHandler: @escaping (CMDeviceMotion?) -> ()) {
        let motionMgr = MotionTracker.motionManager
        if motionMgr.isDeviceMotionAvailable {
            motionMgr.deviceMotionUpdateInterval = 1.0 / 3.0
            // Using the gyroscope, Core Motion separates user movement from gravitational acceleration and presents each as its own property of the CMDeviceMotion instance
            //motionMgr.startDeviceMotionUpdates(to: .main, withHandler: { [weak self] (data: CMDeviceMotion?, error) in
            motionMgr.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical, to: .main, withHandler: { (data: CMDeviceMotion?, error) in
                guard error == nil else {
                    print("Error with DecviceMotion: \(error?.localizedDescription ?? "Unknown Error")")
                    updateHandler(nil)
                    return
                }
                guard let deviceMotion = data else {
                    print("Error with DecviceMotion: data is bad!")
                    updateHandler(nil)
                    return
                }
                updateHandler(deviceMotion)
            })
        }
    }
    
    func stopDeviceMotion() {
        MotionTracker.motionManager.stopDeviceMotionUpdates()
    }
    
    //MARK: utility
    
    static func degrees(_ radians:Double) -> Double {
        return radians * 180.0 / .pi
    }

    
    
    
    
    //////
    // MARK: RAW DATA - Not using because DeviceMotion has a better representation for the purposes of this app.
    
    
    //MARK: Accelerometer
    
    func updateAccelerationLabel(_ data: CMAccelerometerData) {
        //
    }
    
    func startAccelerometer() {
        let motionMgr = MotionTracker.motionManager
        if motionMgr.isAccelerometerAvailable {
            motionMgr.accelerometerUpdateInterval = 1.0 / 250.0
            motionMgr.startAccelerometerUpdates(to: .main, withHandler: { [weak self] (accelData: CMAccelerometerData?, error) in
                if error != nil {
                    print("Accelerometer Error: \(error?.localizedDescription ?? "Unknown Error")")
                    return
                }
                guard let accelData = accelData else {
                    print("Bad Acceleration Data!")
                    return
                }
                let accelX = accelData.acceleration.x
                let accelY = accelData.acceleration.y
                let accelZ = accelData.acceleration.z
                print("Accelerometer Update: [x:\(accelX), y:\(accelY), z:\(accelZ)]")
                self?.updateAccelerationLabel(accelData)
            })
        }
    }
    
    func stopAccelerometer() {
        MotionTracker.motionManager.stopAccelerometerUpdates()
    }
    
    
    
    
    //MARK: Gyro
    
    func updateGyroLabel(_ data: CMGyroData) {
        //
    }
    
    func startGyro() {
        let motionMgr = MotionTracker.motionManager
        if motionMgr.isGyroAvailable {
            motionMgr.gyroUpdateInterval = 1.0 / 30.0
            motionMgr.startGyroUpdates(to: .main, withHandler: { [weak self] (data: CMGyroData?, error) in
                if error != nil {
                    print("Gyro Error: \(error?.localizedDescription ?? "Unknown Error")")
                    return
                }
                guard let gyroData = data else {
                    print("Bad Gyro Data!")
                    return
                }
                let gyroX = gyroData.rotationRate.x
                let gyroY = gyroData.rotationRate.y
                let gyroZ = gyroData.rotationRate.z
                print("Gyro Update: [x:\(gyroX), y:\(gyroY), z:\(gyroZ)]")
                self?.updateGyroLabel(gyroData)
            })
        }
    }
    
    func stopGyro() {
        MotionTracker.motionManager.stopGyroUpdates()
    }
    
    
    
    
    //MARK: Magnetometer
    
    func updateMagnetometerLabel(_ data: CMMagnetometerData) {
        //
    }
    
    func startMagnetometer() {
        let motionMgr = MotionTracker.motionManager
        if motionMgr.isMagnetometerAvailable {
            motionMgr.magnetometerUpdateInterval = 1.0 / 30.0
            motionMgr.startMagnetometerUpdates(to: OperationQueue.main) { [weak self] (data: CMMagnetometerData?, error) in
                // data is CMMagnetometerData?
                if error != nil {
                    print("Magnetometer Error: \(error?.localizedDescription ?? "Unknown Error")")
                    return
                }
                guard let magnetometerData = data else {
                    print("Bad Magnetometer Data!")
                    return
                }
                let magX = magnetometerData.magneticField.x
                let magY = magnetometerData.magneticField.y
                let magZ = magnetometerData.magneticField.z
                print("Magnetometer Update: [x:\(magX), y:\(magY), z:\(magZ)]")
                self?.updateMagnetometerLabel(magnetometerData)
            }
            
        }
    }
    
    func stopMagnetometer() {
        MotionTracker.motionManager.stopMagnetometerUpdates()
    }


}

extension Double {
    var shortValue: String {
        return String(format: "%.4f", self)
    }
}

