//
//  UserDefaults.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 12/08/2025.
//

import Foundation

extension UserDefaults {
    
    var bac: Data? {
        get {
            self.data(forKey: "BAC")
        }
        set {
            self.set(newValue, forKey: "BAC")
        }
    }
}
