//
//  Bac.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 12/08/2025.
//

import Foundation

class Bac: NSObject, ObservableObject, Codable {
    
    @Published var documentNumber: String = "" {
        didSet {
            self.updateUserDefaults()
        }
    }
    @Published var dateOfBirth: Date = .now.addingTimeInterval(Double(-365 * 30 * 24 * 60 * 60)) {
        didSet {
            self.updateUserDefaults()
        }
    }
    @Published var dateOfExpiry: Date = .now {
        didSet {
            self.updateUserDefaults()
        }
    }
    
    lazy var dateParser: DateFormatter = {
        let parser = DateFormatter()
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = "yyMMdd"
        return parser
    }()
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "YYMMdd"
        return formatter
    }()
    
    var key: String {
        let docNumber = self.documentNumber.padding(toLength: 9, withPad: "<", startingAt: 0)
        let dateOfBirth = self.dateFormatter.string(from: self.dateOfBirth).padding(toLength: 6, withPad: "<", startingAt: 0)
        let dateOfExpiry = self.dateFormatter.string(from: self.dateOfExpiry).padding(toLength: 6, withPad: "<", startingAt: 0)
        return "\(docNumber)\(docNumber.mrzChecksum)\(dateOfBirth)\(dateOfBirth.mrzChecksum)\(dateOfExpiry)\(dateOfExpiry.mrzChecksum)"
    }
    
    enum BACCodingKeys: String, CodingKey {
        case documentNumber, dateOfBirth, dateOfExpiry
    }
    
    override init() {
        if let bacData = UserDefaults.standard.bac, let bac = try? JSONDecoder().decode(Bac.self, from: bacData) {
            self.documentNumber = bac.documentNumber
            self.dateOfBirth = bac.dateOfBirth
            self.dateOfExpiry = bac.dateOfExpiry
        }
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: BACCodingKeys.self)
        self.documentNumber = try container.decode(String.self, forKey: .documentNumber)
        self.dateOfBirth = try container.decode(Date.self, forKey: .dateOfBirth)
        self.dateOfExpiry = try container.decode(Date.self, forKey: .dateOfExpiry)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: BACCodingKeys.self)
        try container.encode(self.documentNumber, forKey: .documentNumber)
        try container.encode(self.dateOfBirth, forKey: .dateOfBirth)
        try container.encode(self.dateOfExpiry, forKey: .dateOfExpiry)
    }
    
    private func updateUserDefaults() {
        Task(priority: .background) {
            if let bac = try? JSONEncoder().encode(self) {
                UserDefaults.standard.bac = bac
            }
        }
    }
}
