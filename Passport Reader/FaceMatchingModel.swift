//
//  FaceMatchingModel.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 13/08/2025.
//

import Foundation
import SwiftUI
import VerIDCommonTypes
import FaceCapture
import FaceRecognitionR300Core
import FaceRecognitionR300Cloud
import FacialAttributeDetectionCore
import EyewearDetection
import FaceCoveringDetection

@MainActor
@Observable
final class FaceMatchingModel<T: FaceRecognition> where T.TemplateData == [Float], T.Version == R300 {
    
    enum Phase: Equatable {
        case idle
        case extractingDocumentTemplate
        case capturingSelfie
        case extractingSelfieTemplate
        case comparing
        case done(selfieFace: CapturedFace, score: Float, glassesDetected: Bool)
        case failed(Error)
        
        static func == (lhs: Phase, rhs: Phase) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle),
                (.extractingDocumentTemplate, .extractingDocumentTemplate),
                (.capturingSelfie, .capturingSelfie),
                (.extractingSelfieTemplate, .extractingSelfieTemplate),
                (.comparing, .comparing):
                return true
                
            case let (.done(a, a2, a3), .done(b, b2, b3)):
                return a == b && a2 == b2 && a3 == b3
                
            case (.failed, .failed):
                return true
            default:
                return false
            }
        }
    }
    
    var phase: Phase = .idle
    private let documentFace: Face
    private let documentImage: VerIDCommonTypes.Image
    private let faceRecognition: T
    private let faceCoveringDetector: FaceCoveringDetector?
    private let eyewearDetector: EyewearDetector?
    private var documentTemplate: FaceTemplate<T.Version, T.TemplateData>?
    private var selfieFace: CapturedFace?
    private var selfieTemplate: FaceTemplate<T.Version, T.TemplateData>?
    private var glassesDetected: Bool = false
    
    init(documentFace: Face, image: VerIDCommonTypes.Image, faceRecognition: T) {
        self.documentFace = documentFace
        self.documentImage = image
        self.faceRecognition = faceRecognition
        self.faceCoveringDetector = try? FaceCoveringDetector()
        self.eyewearDetector = try? EyewearDetector()
    }
    
    func start() {
        if case .idle = phase {
            Task(priority: .background) { [weak self] in
                guard let self = self else {
                    return
                }
                do {
                    let template = try await self.faceRecognition.createFaceRecognitionTemplates(from: [self.documentFace], in: self.documentImage).first!
                    await MainActor.run {
                        self.documentTemplate = template
                        self.next()
                    }
                } catch {
                    await MainActor.run {
                        self.phase = .failed(error)
                    }
                }
            }
        } else if case .done(_, _, _) = phase {
            selfieFace = nil
            selfieTemplate = nil
            glassesDetected = false
            phase = .capturingSelfie
        }
    }
    
    func next() {
        switch (self.documentTemplate != nil, self.selfieTemplate != nil) {
        case (true, false):
            self.phase = .capturingSelfie
        case (false, true), (false, false):
            self.phase = .extractingDocumentTemplate
        case (true, true):
            self.compareTemplates()
        }
    }
    
    func onSelfie(_ capturedFace: CapturedFace) {
        if case .failed(_) = self.phase {
            return
        }
        self.phase = .extractingSelfieTemplate
        self.selfieFace = capturedFace
        Task(priority: .background) { [weak self] in
            guard let self = self else {
                return
            }
            do {
                if (try await self.faceCoveringDetector?.detect(in: capturedFace.face, image: capturedFace.image)) != nil {
                    throw FaceAttributeError.faceCoveringDetected
                }
                let glassesDetected: Bool
                if let eyewear = try await self.eyewearDetector?.detect(in: capturedFace.face, image: capturedFace.image) {
                    if eyewear.type == .sunglasses {
                        throw FaceAttributeError.sunglassesDetected
                    } else {
                        glassesDetected = true
                    }
                } else {
                    glassesDetected = false
                }
                let template = try await self.faceRecognition.createFaceRecognitionTemplates(from: [capturedFace.face], in: capturedFace.image).first!
                await MainActor.run {
                    self.selfieTemplate = template
                    self.glassesDetected = glassesDetected
                    self.next()
                }
            } catch {
                await MainActor.run {
                    self.phase = .failed(error)
                }
            }
        }
    }
    
    func compareTemplates() {
        if case .failed(_) = self.phase {
            return
        }
        guard let t1 = self.documentTemplate, let t2 = self.selfieTemplate else {
            return
        }
        self.phase = .comparing
        Task(priority: .high) { [weak self] in
            guard let self = self else {
                return
            }
            do {
                let score = try await self.faceRecognition.compareFaceRecognitionTemplates([t1], to: t2).first!
                await MainActor.run {
                    guard let selfieFace = self.selfieFace else {
                        self.phase = .failed(FaceMatchingError.missingSelfieFace)
                        return
                    }
                    self.phase = .done(selfieFace: selfieFace, score: score, glassesDetected: self.glassesDetected)
                }
            } catch {
                await MainActor.run {
                    self.phase = .failed(error)
                }
            }
        }
    }
}
