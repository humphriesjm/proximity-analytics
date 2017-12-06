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
    
    //MARK: Actions
    
    @IBAction func motionSwitchAction(_ sender: UISwitch) {
        if sender.isOn {
            MotionTracker.sharedInstance.startDeviceMotion(withUpdateHandler: { [weak self] (data: CMDeviceMotion?) in
                if let deviceMotionData = data {
                    self?.updateDeviceMotionLabels(deviceMotionData)
                }
            })
        } else {
            MotionTracker.sharedInstance.stopDeviceMotion()
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
        let accelerationDataObject = AccelerationData(x: accelData.x, y: accelData.y, z: accelData.z, rotation: rotation)
        print("Accelerometer Update: [x:\(accelX), y:\(accelY), z:\(accelZ)], rotation: \(MotionTracker.degrees(rotation).shortValue)")
        self.accelerationLabel.text = "x: \(accelX)\ny:\(accelY)\naccelZ:\(accelZ)\nrotation:\(MotionTracker.degrees(rotation).shortValue)"

        // euler
        let attitude = deviceMotion.attitude
        let roll = MotionTracker.degrees(attitude.roll).shortValue
        let pitch = MotionTracker.degrees(attitude.pitch).shortValue
        let yaw = MotionTracker.degrees(attitude.yaw).shortValue
        let eulerDataObject = EulerData(roll: MotionTracker.degrees(attitude.roll), pitch: MotionTracker.degrees(attitude.pitch), yaw: MotionTracker.degrees(attitude.yaw))
        print("Roll: \(roll), Pitch: \(pitch), Yaw: \(yaw)")
        self.eulerLabel.text = "roll: \(roll)\npitch:\(pitch)\nyaw:\(yaw)"

        
        // magnetic
        let magneticData = deviceMotion.magneticField
        let magX = magneticData.field.x.shortValue
        let magY = magneticData.field.y.shortValue
        let magZ = magneticData.field.z.shortValue
        let magAccuracy = magneticData.accuracy.rawValue
        let magneticDataObject = MagneticData(x: magneticData.field.x, y: magneticData.field.y, z: magneticData.field.z, accuracy: Double(magAccuracy))
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
        
        DataStore.sharedInstance.saveMotionDataJSON(accelerationData: accelerationDataObject, eulerData: eulerDataObject, magneticData: magneticDataObject)
    }

}
