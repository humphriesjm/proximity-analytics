//
//  MotionViewController.swift
//  ProximityAnalytics
//
//  Created by Jason Humphries on 11/19/17.
//  Copyright © 2017 Jason Humphries. All rights reserved.
//

import CoreMotion
import UIKit

class MotionViewController: UIViewController {

    @IBOutlet weak var deviceMotionSwitch: UISwitch!
    
    @IBOutlet weak var accelerationLabel: UILabel!
    @IBOutlet weak var eulerLabel: UILabel!
    @IBOutlet weak var magneticLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: utility
    
    func degrees(_ radians:Double) -> Double {
        return radians * 180.0 / .pi
    }
    
    
    //MARK: Actions
    
    @IBAction func motionSwitchAction(_ sender: UISwitch) {
        if sender.isOn {
            self.startDeviceMotion()
        } else {
            self.stopDeviceMotion()
        }
    }
    
    
    
    
    
    //MARK: DeviceMotion
    
    func updateDeviceMotionLabels(_ deviceMotion: CMDeviceMotion) {
        // acceleration
        let accelData = deviceMotion.gravity
        let accelX = accelData.x.shortValue
        let accelY = accelData.y.shortValue
        let accelZ = accelData.z.shortValue
        let rotation = atan2(accelData.x, accelData.y) - .pi
        print("Accelerometer Update: [x:\(accelX), y:\(accelY), z:\(accelZ)], rotation: \(self.degrees(rotation).shortValue)")
        self.accelerationLabel.text = "x: \(accelX)\ny:\(accelY)\naccelZ:\(accelZ)\nrotation:\(self.degrees(rotation).shortValue)"

        // euler
        let attitude = deviceMotion.attitude
        let roll = self.degrees(attitude.roll).shortValue
        let pitch = self.degrees(attitude.pitch).shortValue
        let yaw = self.degrees(attitude.yaw).shortValue
        print("Roll: \(roll), Pitch: \(pitch), Yaw: \(yaw)")
        self.eulerLabel.text = "roll: \(roll)\npitch:\(pitch)\nyaw:\(yaw)"

        
        // magnetic
        let magneticData = deviceMotion.magneticField
        let magX = magneticData.field.x.shortValue
        let magY = magneticData.field.y.shortValue
        let magZ = magneticData.field.z.shortValue
        let magAccuracy = magneticData.accuracy.rawValue
        var magAccString = "Uncalibrated"
        if magAccuracy == 0 {
            magAccString = "Low"
        } else if magAccuracy == 1 {
            magAccString = "Medium"
        } else if magAccuracy == 2 {
            magAccString = "High"
        }
        print("MAG - x: \(magX), y: \(magY), z: \(magZ), accuracy: \(magAccString)")
        self.magneticLabel.text = "x: \(magX)\ny: \(magY)\nz: \(magZ)\naccuracy: \(magAccString)"
    }
    
    func startDeviceMotion() {
        let motionMgr = MotionTracker.motionManager
        if motionMgr.isDeviceMotionAvailable {
            motionMgr.deviceMotionUpdateInterval = 1.0 / 3.0
            // Using the gyroscope, Core Motion separates user movement from gravitational acceleration and presents each as its own property of the CMDeviceMotion instance
            //motionMgr.startDeviceMotionUpdates(to: .main, withHandler: { [weak self] (data: CMDeviceMotion?, error) in
            motionMgr.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical, to: .main, withHandler: { [weak self] (data: CMDeviceMotion?, error) in
                guard error == nil else {
                    print("Error with DecviceMotion: \(error?.localizedDescription ?? "Unknown Error")")
                    return
                }
                guard let deviceMotion = data else {
                    print("Error with DecviceMotion: data is bad!")
                    return
                }
                self?.updateDeviceMotionLabels(deviceMotion)
            })
        }
    }
    
    func stopDeviceMotion() {
        MotionTracker.motionManager.stopDeviceMotionUpdates()
    }

    
    
    
    
    
    
    
    
    
    
    
    
    
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
