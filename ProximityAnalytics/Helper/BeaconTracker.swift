//
//  BeaconTracker.swift
//  ProximityAnalytics
//
//  Created by Jason Humphries on 11/18/17.
//  Copyright © 2017 Jason Humphries. All rights reserved.
//

import CoreBluetooth
import CoreLocation
import Foundation

class BeaconTracker: NSObject {
    static let sharedInstance: BeaconTracker = {
        return BeaconTracker()
    }()
    
    
}

