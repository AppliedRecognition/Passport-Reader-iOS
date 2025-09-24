//
//  Errors.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 27/08/2025.
//

import Foundation

enum FaceDetectionError: LocalizedError {
    case noFaceDetected
    
    var errorDescription: String? {
        switch self {
        case .noFaceDetected:
            return NSLocalizedString("No face detected", comment: "")
        }
    }
}

enum ImageError: LocalizedError {
    case imageConversionFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return NSLocalizedString("Image conversion failed", comment: "")
        }
    }
}

enum FaceMatchingError: LocalizedError {
    case missingSelfieFace
    
    var errorDescription: String? {
        switch self {
        case .missingSelfieFace:
            return NSLocalizedString("Selfie face is missing", comment: "")
        }
    }
}

enum FaceAttributeError: LocalizedError {
    case faceCoveringDetected
    case sunglassesDetected
    
    var errorDescription: String? {
        switch self {
        case .faceCoveringDetected:
            return NSLocalizedString("Detected face covering", comment: "")
        case .sunglassesDetected:
            return NSLocalizedString("Detected sunglasses", comment: "")
        }
    }
}
