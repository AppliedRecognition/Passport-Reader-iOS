//
//  VerIDLoader.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 01/05/2023.
//

import Foundation
import VerIDCore

@MainActor
class VerIDLoader: ObservableObject {
    
    @Published var result: Result<VerID,Error>?
    @Published var isVerIDLoaded: Bool = false
    
    init() {
        let veridFactory = VerIDFactory()
        let detrecFactory = VerIDFaceDetectionRecognitionFactory(apiSecret: nil)
        detrecFactory.defaultFaceTemplateVersion = .latest
        detrecFactory.faceTemplateVersions = [.latest]
        veridFactory.faceDetectionFactory = detrecFactory
        veridFactory.faceRecognitionFactory = detrecFactory
        veridFactory.createVerID { result in
            self.result = result
            if case .success(_) = result {
                self.isVerIDLoaded = true
            }
        }
    }
}
