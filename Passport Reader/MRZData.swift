//
//  MRZData.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 02/05/2023.
//

import Foundation

struct MRZData {
    
    let issuingAuthority: String
    let documentNumber: String
    let dateOfExpiry: Date
    let lastName: String
    let firstName: String
    let nationality: String
    let sex: String
    let dateOfBirth: Date
    
    let dateParser: DateFormatter = {
        let parser = DateFormatter()
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = "yyMMdd"
        return parser
    }()
    
    init?(_ mrz: String) {
        let text = mrz.replacingOccurrences(of: "‹", with: "<")
        if !text.hasPrefix("P<") {
            return nil
        }
        let lines = text.split(separator: "\n").map({String($0)})
        if lines.count != 2 {
            return nil
        }
        var splits = lines[0].split(separator: "<", omittingEmptySubsequences: true).map({String($0)})
        if splits.count < 3 {
            return nil
        }
        if splits[1].count < 4 {
            return nil
        }
        self.issuingAuthority = String(splits[1][splits[1].startIndex..<splits[1].index(splits[1].startIndex, offsetBy: 3)])
        self.lastName = String(splits[1][splits[1].index(splits[1].startIndex, offsetBy: 3)...])
        self.firstName = splits[2]
        splits = lines[1].split(separator: "<", omittingEmptySubsequences: true).map({String($0)})
        if splits.count < 2 {
            return nil
        }
        self.documentNumber = splits[0]
        let expectedDocNumberCheckDigit = MRZChecksum(splits[0]).string
        let actualDocNumberCheckDigit = splits[1].prefix(1)
        if expectedDocNumberCheckDigit != actualDocNumberCheckDigit {
            return nil
        }
        if splits[1].count < 19 {
            return nil
        }
        self.nationality = String(splits[1][splits[1].index(splits[1].startIndex, offsetBy: 1)..<splits[1].index(splits[1].startIndex, offsetBy: 4)])
        let dob = String(splits[1][splits[1].index(splits[1].startIndex, offsetBy: 4)..<splits[1].index(splits[1].startIndex, offsetBy: 10)])
        let expectedDobCheckDigit = MRZChecksum(dob).string
        let actualDobCheckDigit = String(splits[1][splits[1].index(splits[1].startIndex, offsetBy: 10)..<splits[1].index(splits[1].startIndex, offsetBy: 11)])
        if expectedDobCheckDigit != actualDobCheckDigit {
            return nil
        }
        self.sex = String(splits[1][splits[1].index(splits[1].startIndex, offsetBy: 11)..<splits[1].index(splits[1].startIndex, offsetBy: 12)])
        let doe = String(splits[1][splits[1].index(splits[1].startIndex, offsetBy: 12)..<splits[1].index(splits[1].startIndex, offsetBy: 18)])
        let expectedDoeCheckDigit = MRZChecksum(doe).string
        let actualDoeCheckDigit = String(splits[1][splits[1].index(splits[1].startIndex, offsetBy: 18)..<splits[1].index(splits[1].startIndex, offsetBy: 19)])
        if expectedDoeCheckDigit != actualDoeCheckDigit {
            return nil
        }
        guard let dobDate = dateParser.date(from: dob) else {
            return nil
        }
        self.dateOfBirth = dobDate
        guard let doeDate = dateParser.date(from: doe) else {
            return nil
        }
        self.dateOfExpiry = doeDate
    }
}
