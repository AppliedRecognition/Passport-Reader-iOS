//
//  CameraPreviewView.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 10/08/2023.
//

import UIKit
import AVFoundation

/// View that shows camera preview
public class CameraPreviewView: UIView {
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return self.layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return self.videoPreviewLayer.session
        }
        set {
            self.videoPreviewLayer.session = newValue
        }
    }
    
    // MARK: UIView
    
    public override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
