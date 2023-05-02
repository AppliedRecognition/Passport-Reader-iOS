//
//  MRZChecksum.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 02/05/2023.
//

import Foundation

class MRZChecksum {
    
    let number: Int
    lazy var string: String = {
        String(format: "%d", self.number)
    }()
    
    init(_ checkString: String) {
        let characterDict  = ["0" : "0", "1" : "1", "2" : "2", "3" : "3", "4" : "4", "5" : "5", "6" : "6", "7" : "7", "8" : "8", "9" : "9", "<" : "0", " " : "0", "A" : "10", "B" : "11", "C" : "12", "D" : "13", "E" : "14", "F" : "15", "G" : "16", "H" : "17", "I" : "18", "J" : "19", "K" : "20", "L" : "21", "M" : "22", "N" : "23", "O" : "24", "P" : "25", "Q" : "26", "R" : "27", "S" : "28","T" : "29", "U" : "30", "V" : "31", "W" : "32", "X" : "33", "Y" : "34", "Z" : "35"]
        var sum = 0
        var m = 0
        let multipliers : [Int] = [7, 3, 1]
        for c in checkString {
            guard let lookup = characterDict["\(c)"], let number = Int(lookup) else {
                continue
            }
            let product = number * multipliers[m]
            sum += product
            m = (m+1) % 3
        }
        self.number = (sum % 10)
    }
}

extension MRZChecksum: CustomStringConvertible {
    
    var description: String {
        return self.string
    }
}

extension String {
    
    init(_ mrzChecksum: MRZChecksum) {
        self = mrzChecksum.string
    }
}
