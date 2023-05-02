//
//  UserDefaults+PassportReader.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 01/05/2023.
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
