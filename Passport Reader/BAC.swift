//
//  BAC.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 28/04/2023.
//

import Foundation
import BlinkID

class BAC: NSObject, ObservableObject, Codable {
    
    @Published var documentNumber: String = "" {
        didSet {
            self.updateUserDefaults()
        }
    }
    @Published var dateOfBirth: Date = .now.addingTimeInterval(-365 * 30 * 24 * 60 * 60) {
        didSet {
            self.updateUserDefaults()
        }
    }
    @Published var dateOfExpiry: Date = .now {
        didSet {
            self.updateUserDefaults()
        }
    }
    
    lazy var blinkIdRecognizer: MBBlinkIdSingleSideRecognizer = {
        let recognizer = MBBlinkIdSingleSideRecognizer()
        recognizer.recognitionModeFilter.enableMrzPassport = true
        return recognizer
    }()
    
    lazy var dateParser: DateFormatter = {
        let parser = DateFormatter()
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = "yyMMdd"
        return parser
    }()
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "YYMMdd"
        return formatter
    }()
    
    var key: String {
        let docNumber = self.documentNumber.padding(toLength: 9, withPad: "<", startingAt: 0)
        let dateOfBirth = self.dateFormatter.string(from: self.dateOfBirth).padding(toLength: 6, withPad: "<", startingAt: 0)
        let dateOfExpiry = self.dateFormatter.string(from: self.dateOfExpiry).padding(toLength: 6, withPad: "<", startingAt: 0)
        let docNumberChecksum = MRZChecksum(docNumber)
        let dateOfBirthChecksum = MRZChecksum(dateOfBirth)
        let dateOfExpiryChecksum = MRZChecksum(dateOfExpiry)
        return "\(docNumber)\(docNumberChecksum)\(dateOfBirth)\(dateOfBirthChecksum)\(dateOfExpiry)\(dateOfExpiryChecksum)"
    }
    
    enum BACCodingKeys: String, CodingKey {
        case documentNumber, dateOfBirth, dateOfExpiry
    }
    
    override init() {
        if let bacData = UserDefaults.standard.bac, let bac = try? JSONDecoder().decode(BAC.self, from: bacData) {
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
        if let bac = try? JSONEncoder().encode(self) {
            UserDefaults.standard.bac = bac
        }
    }
    
    func captureMRZ() {
        /** Create BlinkID settings */
        let settings: MBBlinkIdOverlaySettings = MBBlinkIdOverlaySettings()
        
        /** Crate recognizer collection */
        let recognizerList = [self.blinkIdRecognizer]
        let recognizerCollection: MBRecognizerCollection = MBRecognizerCollection(recognizers: recognizerList)
        
        /** Create your overlay view controller */
        let blinkIdOverlayViewController: MBBlinkIdOverlayViewController = MBBlinkIdOverlayViewController(settings: settings, recognizerCollection: recognizerCollection, delegate: self)
        
        /** Create recognizer view controller with wanted overlay view controller */
        guard let recognizerRunnerViewController: UIViewController = MBViewControllerFactory.recognizerRunnerViewController(withOverlayViewController: blinkIdOverlayViewController) else {
            return
        }
        
        /** Present the recognizer runner view controller. You can use other presentation methods as well (instead of presentViewController) */
        guard let rootViewController = UIApplication.shared.connectedScenes.compactMap({ scene in
            return (scene as? UIWindowScene)?.keyWindow?.rootViewController
        }).first else {
            return
        }
        rootViewController.present(recognizerRunnerViewController, animated: true)
    }
}

extension BAC: MBBlinkIdOverlayViewControllerDelegate {
    
    func blinkIdOverlayViewControllerDidFinishScanning(_ blinkIdOverlayViewController: MBBlinkIdOverlayViewController, state: MBRecognizerResultState) {
        if state == .valid {
            blinkIdOverlayViewController.recognizerRunnerViewController?.pauseScanning()
            DispatchQueue.main.async {
                blinkIdOverlayViewController.dismiss(animated: true, completion: nil)
                let result = self.blinkIdRecognizer.result
                self.documentNumber = result.mrzResult.documentNumber.trimmingCharacters(in: CharacterSet(charactersIn: "<").union(.whitespacesAndNewlines))
                if let dobString = result.mrzResult.dateOfBirth.originalDateString, let dob = self.dateParser.date(from: dobString) {
                    self.dateOfBirth = dob
                }
                if let doeString = result.mrzResult.dateOfExpiry.originalDateString, let doe = self.dateParser.date(from: doeString) {
                    self.dateOfExpiry = doe
                }
            }
        }
    }
    
    func blinkIdOverlayViewControllerDidTapClose(_ blinkIdOverlayViewController: MBBlinkIdOverlayViewController) {
        blinkIdOverlayViewController.dismiss(animated: true)
    }
}
