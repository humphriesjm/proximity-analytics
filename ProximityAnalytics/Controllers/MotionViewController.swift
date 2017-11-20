//
//  MotionViewController.swift
//  ProximityAnalytics
//
//  Created by Jason Humphries on 11/19/17.
//  Copyright © 2017 Jason Humphries. All rights reserved.
//

import UIKit

class MotionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        MotionTracker.motionManager.startMagnetometerUpdates(to: OperationQueue.main) { (data, error) in
            // data is CMMagnetometerData?
            if let data = data {
                print("got magnetometer data: \(data)")
            }
        }
    }

}
