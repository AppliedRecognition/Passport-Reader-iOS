//
//  MRZScanner.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 02/05/2023.
//

import SwiftUI
import UIKit
import VisionKit

@available(iOS 16, *)
struct MRZScanner: UIViewControllerRepresentable {
    
    @Binding var isScanning: Bool
    @StateObject var bac: BAC
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate
        )
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if self.isScanning {
            try? uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

@available(iOS 16, *)
class Coordinator: NSObject, DataScannerViewControllerDelegate {
    
    let scanner: MRZScanner
    
    init(_ scanner: MRZScanner) {
        self.scanner = scanner
    }
    
    func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        if let mrzData = addedItems.compactMap({ item in
            if case .text(let text) = item {
                return MRZData(text.transcript)
            }
            return nil
        }).first {
            self.scanner.bac.documentNumber = mrzData.documentNumber
            self.scanner.bac.dateOfBirth = mrzData.dateOfBirth
            self.scanner.bac.dateOfExpiry = mrzData.dateOfExpiry
            self.scanner.isScanning = false
        }
    }
}
