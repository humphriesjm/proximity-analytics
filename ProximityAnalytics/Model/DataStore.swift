//
//  DataStore.swift
//  ProximityAnalytics
//
//  Created by Jason Humphries on 11/19/17.
//  Copyright © 2017 Jason Humphries. All rights reserved.
//

import Foundation

class DataStore {
    static let userDefaults = UserDefaults.standard
    
    static func saveMyBluetoothPeripheralName(_ name: String) {
        userDefaults.set(name, forKey: Constants.MyBluetoothPeripheralNameKey)
        userDefaults.synchronize()
    }
    
    static func getMyBluetoothPeripheralName() -> String? {
        if let name = userDefaults.string(forKey: Constants.MyBluetoothPeripheralNameKey) {
            return name
        }
        return nil
    }
    
//    static func addSearchTermToHistory(_ term: String) {
//        var searchHistory = userDefaults.array(forKey: Constants.SearchHistoryUserDefaultsKey) as? [String]
//        if searchHistory != nil {
//            // terms exist in search history -- prevent dupes
//            if searchHistory!.contains(term) == false {
//                searchHistory!.append(term)
//            }
//            self.saveSearchHistoryArray(searchHistory: searchHistory!)
//        } else {
//            // no terms exist yet in search history. create new search history with new term.
//            userDefaults.set([term], forKey: Constants.SearchHistoryUserDefaultsKey)
//            userDefaults.synchronize()
//        }
//    }
    
//    static func getSearchHistory() -> [String]? {
//        if let searchHistory = userDefaults.array(forKey: Constants.SearchHistoryUserDefaultsKey) as? [String] {
//            return searchHistory
//        }
//        return nil
//    }
    
//    static func getLastSearchTerm() -> String? {
//        if let currentSearchHistory = self.getSearchHistory() {
//            return currentSearchHistory.last
//        }
//        return nil
//    }
}
