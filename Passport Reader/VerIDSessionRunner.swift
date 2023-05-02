//
//  VerIDSessionRunner.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 01/05/2023.
//

import Foundation
import VerIDUI
import VerIDCore
import SwiftUI
import AVFoundation

@MainActor
class VerIDSessionRunner: ObservableObject, VerIDSessionDelegate {
    
    @Published var sessionResult: VerIDSessionResult?
    @Published var isSessionRunning: Bool = false
    
    func startSession(verID: VerID) {
        DispatchQueue.main.async {
            if self.isSessionRunning {
                return
            }
            let settings = LivenessDetectionSessionSettings()
            let session = VerIDSession(environment: verID, settings: settings)
            session.delegate = self
            session.start()
            self.isSessionRunning = true
        }
    }
    
    nonisolated func didFinishSession(_ session: VerIDSession, withResult result: VerIDSessionResult) {
        DispatchQueue.main.async {
            self.sessionResult = result
            self.isSessionRunning = false
        }
    }
    
    nonisolated func didCancelSession(_ session: VerIDSession) {
        DispatchQueue.main.async {
            self.isSessionRunning = false
        }
    }
}
