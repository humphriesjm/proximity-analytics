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
    
}
