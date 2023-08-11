//
//  CameraViewController.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 10/08/2023.
//

import UIKit
import AVFoundation
import Vision
import SwiftUI

class CameraViewController: UIViewController {
    
    var cameraControl: CameraControl!
    @IBOutlet var cameraPreviewView: CameraPreviewView!
    var videoOrientation: AVCaptureVideoOrientation {
        if let orientation = self.view.window?.windowScene?.interfaceOrientation {
            switch orientation {
            case .portraitUpsideDown:
                return .portraitUpsideDown
            case .landscapeLeft:
                return .landscapeLeft
            case .landscapeRight:
                return .landscapeRight
            default:
                return .portrait
            }
        } else {
            return .portrait
        }
    }
    weak var delegate: MRZCameraViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.cameraControl = CameraControl(sampleBufferDelegate: self)
        self.cameraPreviewView.videoPreviewLayer.videoGravity = .resizeAspectFill
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateCameraPreviewSize()
        self.cameraControl.startCamera { result in
            if case .success() = result {
                self.cameraPreviewView.session = self.cameraControl.captureSession
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.cameraPreviewView.session = nil
        self.cameraControl.stopCamera()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animateAlongsideTransition(in: self.view, animation: nil, completion: { context in
            if !context.isCancelled {
                self.updateCameraPreviewSize()
            }
        })
    }
    
    @IBAction func cancel() {
        self.dismiss(animated: true)
    }
    
    private func updateCameraPreviewSize() {
        self.cameraPreviewView.frame = self.view.bounds
        self.cameraPreviewView.videoPreviewLayer.frame = self.view.bounds
        if self.cameraPreviewView.videoPreviewLayer.connection?.isVideoOrientationSupported == .some(true) {
            self.cameraPreviewView.videoPreviewLayer.connection?.videoOrientation = self.videoOrientation
        }
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer)
        let request = VNRecognizeTextRequest(completionHandler: self.recognizeTextHandler(request:error:))
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        do {
            try requestHandler.perform([request])
        } catch {
            
        }
    }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        let strings = observations.compactMap {
            $0.topCandidates(1).first?.string.replacingOccurrences(of: #"[‹≤]"#, with: "<", options: .regularExpression, range: nil)
        }
        if !strings.isEmpty, let startIndex = strings.firstIndex(where: { $0.starts(with: "P<") }), startIndex + 1 < strings.count {
            let mrzLines = strings[startIndex...startIndex+1]
            if let mrzData = MRZData(mrzLines.joined(separator: "\n")) {
                DispatchQueue.main.async {
                    self.delegate?.cameraViewController(self, didFindMRZ: mrzData)
                }
            }
        }
    }
}

struct TextRecognitionCamera: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = CameraViewController
    
    func makeUIViewController(context: Context) -> CameraViewController {
        return UIStoryboard(name: "Camera", bundle: Bundle.main).instantiateInitialViewController() as! CameraViewController
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {        
    }
}

protocol MRZCameraViewControllerDelegate: AnyObject {
    
    func cameraViewController(_ cameraViewController: CameraViewController, didFindMRZ mrzData: MRZData)
}
