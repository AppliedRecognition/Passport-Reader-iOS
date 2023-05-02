//
//  NFCPassportModel+VerID.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 29/04/2023.
//

import Foundation
import NFCPassportReader

extension NFCPassportModel {
    
    var list: [DocSection] {
        let dateParser = {
            let parser = DateFormatter()
            parser.dateFormat = "yyMMdd"
            return parser
        }()
        let dateFormatter = {
            let formatter = DateFormatter()
            formatter.timeStyle = .none
            formatter.dateStyle = .long
            return formatter
        }()
        let dob: String
        if let date = dateParser.date(from: self.dateOfBirth) {
            dob = dateFormatter.string(from: date)
        } else {
            dob = self.dateOfBirth
        }
        let doe: String
        if let date = dateParser.date(from: self.documentExpiryDate) {
            doe = dateFormatter.string(from: date)
        } else {
            doe = self.documentExpiryDate
        }
        var activeAuthentication: String = "Not supported"
        if self.activeAuthenticationSupported {
            activeAuthentication = self.activeAuthenticationPassed ? "Passed" : "Failed"
        }
        var chipAuthentication: String = "Not supported"
        if self.isChipAuthenticationSupported {
            switch self.chipAuthenticationStatus {
            case .notDone:
                chipAuthentication = "Not done"
            case .success:
                chipAuthentication = "Passed"
            case .failed:
                chipAuthentication = "Failed"
            @unknown default:
                chipAuthentication = "Unknown"
            }
        }
        var authenticationType = "None"
        var paceStatus = "Not supported"
        if self.isPACESupported {
            switch self.PACEStatus {
            case .notDone:
                paceStatus = "Not done"
            case .success:
                paceStatus = "Passed"
                authenticationType = "PACE"
            case .failed:
                paceStatus = "Failed"
            @unknown default:
                paceStatus = "Unknown"
            }
        }
        var bacStatus = "None"
        switch self.BACStatus {
        case .notDone:
            bacStatus = "Not done"
        case .success:
            bacStatus = "Passed"
            authenticationType = "BAC"
        case .failed:
            bacStatus = "Failed"
        @unknown default:
            bacStatus = "Unknown"
        }
        return [
            DocSection(name: "Document holder", rows: [
                DocSectionRow(name: "First name", value: self.firstName),
                DocSectionRow(name: "Last name", value: self.lastName),
                DocSectionRow(name: "Nationality", value: self.nationality),
                DocSectionRow(name: "Sex", value: self.gender),
                DocSectionRow(name: "Date of birth", value: dob)
            ]),
            DocSection(name: "Document", rows: [
                DocSectionRow(name: "Document number", value: self.documentNumber),
                DocSectionRow(name: "Issuing authority", value: self.issuingAuthority),
                DocSectionRow(name: "Date of expiry", value: doe)
            ]),
            DocSection(name: "Verification", rows: [
                DocSectionRow(name: "Active authentication", value: activeAuthentication),
                DocSectionRow(name: "Chip authentication", value: chipAuthentication),
                DocSectionRow(name: "Access control", value: authenticationType),
                DocSectionRow(name: "PACE authentication", value: paceStatus),
                DocSectionRow(name: "BAC authentication", value: bacStatus),
                DocSectionRow(name: "Document signing certificate", value: self.documentSigningCertificateVerified ? "Verified" : "Unverified"),
                DocSectionRow(name: "Country signing certificate", value: self.passportCorrectlySigned ? "Verified" : "Unverified"),
                DocSectionRow(name: "Tamper detection", value: self.passportDataNotTampered ? "Passed" : "Unverified")
            ])
        ]
    }
}

struct DocSection: Identifiable {
    
    let id = UUID()
    let name: String
    let rows: [DocSectionRow]
}

struct DocSectionRow: Identifiable {
    
    let id = UUID()
    let name: String
    let value: String
}
