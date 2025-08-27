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
import FaceRecognitionArcFaceCore
import FaceRecognitionArcFaceCloud

@MainActor
@Observable
final class FaceMatchingModel<T: FaceRecognition> where T.TemplateData == [Float], T.Version == V24 {
    
    enum Phase: Equatable {
        case idle
        case extractingDocumentTemplate
        case capturingSelfie
        case extractingSelfieTemplate
        case comparing
        case done(selfieFace: CapturedFace, score: Float)
        case failed(Error)
        
        static func == (lhs: Phase, rhs: Phase) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle),
                (.extractingDocumentTemplate, .extractingDocumentTemplate),
                (.capturingSelfie, .capturingSelfie),
                (.extractingSelfieTemplate, .extractingSelfieTemplate),
                (.comparing, .comparing):
                return true
                
            case let (.done(a, a2), .done(b, b2)):
                return a == b && a2 == b2
                
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
    private var documentTemplate: FaceTemplate<T.Version, T.TemplateData>?
    private var selfieFace: CapturedFace?
    private var selfieTemplate: FaceTemplate<T.Version, T.TemplateData>?
    
    init(documentFace: Face, image: VerIDCommonTypes.Image, faceRecognition: T) {
        self.documentFace = documentFace
        self.documentImage = image
        self.faceRecognition = faceRecognition
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
        } else if case .done(_, _) = phase {
            selfieFace = nil
            selfieTemplate = nil
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
                let template = try await self.faceRecognition.createFaceRecognitionTemplates(from: [capturedFace.face], in: capturedFace.image).first!
                await MainActor.run {
                    self.selfieTemplate = template
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
                    self.phase = .done(selfieFace: selfieFace, score: score)
                }
            } catch {
                await MainActor.run {
                    self.phase = .failed(error)
                }
            }
        }
    }
}
