//
//  CameraControl.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 10/08/2023.
//

import UIKit
import AVFoundation

/// Encapsulates interaction with the device camera
class CameraControl {
    
    let sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate
    let captureSessionQueue = DispatchQueue(label: "com.appliedrec.videocapture")
    private let captureDevice: AVCaptureDevice! = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
    let captureSession = AVCaptureSession()
    private lazy var videoDataOutput: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        let pixelFormat: OSType = kCVPixelFormatType_32BGRA
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:pixelFormat]
        output.setSampleBufferDelegate(self.sampleBufferDelegate, queue: self.captureSessionQueue)
        return output
    }()
    
    init(sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        self.sampleBufferDelegate = sampleBufferDelegate
    }
    
    func configureCaptureSession(completion: @escaping (Error?) -> Void) {
        let configureSession: () -> Void = {
            self.captureSessionQueue.async { [weak self] in
                guard let `self` = self else {
                    return
                }
                self.captureSession.beginConfiguration()
                defer {
                    self.captureSession.commitConfiguration()
                }
                var configError: Error?
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: self.captureDevice)
                    guard self.captureSession.canAddInput(videoDeviceInput) else {
                        return
                    }
                    self.captureSession.addInput(videoDeviceInput)
                    guard self.captureSession.canAddOutput(self.videoDataOutput) else {
                        return
                    }
                    self.captureSession.addOutput(self.videoDataOutput)
                    configError = nil
                } catch {
                    configError = error
                }
                DispatchQueue.main.async {
                    completion(configError)
                }
            }
        }
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
            case .authorized:
                configureSession()
                break
            case .notDetermined:
                self.captureSessionQueue.suspend()
                AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { [weak self] granted in
                    guard let `self` = self else {
                        return
                    }
                    self.captureSessionQueue.resume()
                    if granted {
                        configureSession()
                    }
                })
            default:
                NSLog("Camera not authorized or available")
                return
            }
        }
    }
    
    func startCamera(completion: @escaping (Result<Void,Error>) -> Void) {
        self.configureCaptureSession { error in
            if let err = error {
                completion(.failure(err))
                return
            }
            self.captureSessionQueue.async { [weak self] in
                guard let self = self else {
                    return
                }
                if self.captureSession.isRunning {
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                    return
                }
                do {
                    try self.captureDevice.lockForConfiguration()
                    if self.captureDevice.isExposureModeSupported(AVCaptureDevice.ExposureMode.continuousAutoExposure) {
                        self.captureDevice.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
                    }
                    if self.captureDevice.isFocusModeSupported(AVCaptureDevice.FocusMode.continuousAutoFocus) {
                        self.captureDevice.focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
                    } else if self.captureDevice.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) {
                        self.captureDevice.focusMode = AVCaptureDevice.FocusMode.autoFocus
                    }
                    if self.captureDevice.isFocusPointOfInterestSupported {
                        self.captureDevice.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                self.captureDevice.unlockForConfiguration()
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            }
        }
    }
    
    func stopCamera(completion: (() -> Void)? = nil) {
        self.captureSessionQueue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            if let callback = completion {
                DispatchQueue.main.async {
                    callback()
                }
            }
        }
    }
}
