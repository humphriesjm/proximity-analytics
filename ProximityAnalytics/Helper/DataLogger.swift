//
//  DataLogger.swift
//  ProximityAnalytics
//
//  Created by Jason Humphries on 11/21/17.
//  Copyright © 2017 Jason Humphries. All rights reserved.
//

import Foundation

class DataLogger {
    
    // need a way to log the following data in ways that can be visualized:
    
    // array of JSON objects that associate a device name with the rssi over time
    // 1) [ deviceName { timestamp : rssi } ]
    
    // array of JSON objects that show this device's acceleration data over time
    // 2) [ { timestamp : accelerationData } ]
    
    // array of JSON objects that show this device's pitch, roll, and yaw over time
    // 3) [ { timestamp : eulers (pitch, roll, yaw) } ]
    
    // array of JSON objects that show this device's magnetic data over time
    // 4) [ { timestamp : magneticData } ]
    
}
