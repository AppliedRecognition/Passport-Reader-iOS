//
//  ContentView.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 28/04/2023.
//

import SwiftUI
import NFCPassportReader
import VerIDUI
import VisionKit

struct ContentView: View {
    
    @StateObject var bac: BAC = BAC()
    @StateObject var verIDLoader: VerIDLoader = VerIDLoader()
    @StateObject var microblinkKeyLoader: MicroblinkKeyLoader = MicroblinkKeyLoader()
    @State var capturedDocument: NFCPassportModel?
    @State var documentCaptured: Bool = false
    @State var faceCapture: FaceCapture?
    @State var showingCapturedDocument: Bool = false
    @State var faceDetectionError: Error?
    
    var passportReader: PassportReader = PassportReader(logLevel: .error)
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image("Passport")
                    }.ignoresSafeArea()
                }.ignoresSafeArea()
                if let result = self.microblinkKeyLoader.result, case .success(_) = result {
                    if let faceDetectionError = self.faceDetectionError {
                        Text(faceDetectionError.localizedDescription)
                    } else if let document = self.capturedDocument, let faceCapture = self.faceCapture, self.showingCapturedDocument {
                        NavigationLink(isActive: self.$showingCapturedDocument) {
                            let name = "\(document.firstName) \(document.lastName)"
                            PassportView(faceCapture: faceCapture, name: name, details: document.list)
                        } label: {
                            EmptyView()
                        }
                    } else if self.capturedDocument != nil && self.faceCapture == nil {
                        ProgressView {
                            Text("Detecting a face")
                        }.progressViewStyle(.circular)
                    } else {
                        VStack(alignment: .leading) {
                            HStack {
                                TextField(text: self.$bac.documentNumber, prompt: Text("Document number")) {
                                    Text("Document number")
                                }
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.characters)
                                .padding(.bottom, 8)
                                .frame(maxWidth: 300)
                                Button {
                                    self.bac.captureMRZ()
                                } label: {
                                    Image(systemName: "camera.fill").imageScale(.large)
                                }
                                .padding(.bottom, 8)
                                Spacer()
                            }
                            DatePicker("Date of birth", selection: self.$bac.dateOfBirth, displayedComponents: .date).datePickerStyle(.compact).frame(maxWidth: 340)
                            DatePicker("Date of expiry", selection: self.$bac.dateOfExpiry, displayedComponents: .date).datePickerStyle(.compact).frame(maxWidth: 340)
                            Button {
                                self.readPassport()
                            } label: {
                                Text("Read passport")
                                Image(systemName: "wave.3.right")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(self.bac.documentNumber.trimmingCharacters(in: .alphanumerics.inverted).isEmpty)
                            .padding(.top, 16)
                            Spacer()
                        }
                        .navigationTitle("Passport Reader")
                        .padding()
                        //                    .task {
                        //                        if #available(iOS 16, *), DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                        //                            self.isScanningText.toggle()
                        //                        }
                        //                    }
                    }
                } else if microblinkKeyLoader.result == nil {
                    ProgressView {
                        Text("Downloading licence keys")
                    }.progressViewStyle(.circular)
                } else {
                    Text("Failed to download BlinkID licence key")
                }
            }
        }
        .onChange(of: self.verIDLoader.isVerIDLoaded) { _ in
            self.detectFaceOnDocument()
        }
        .onChange(of: self.documentCaptured) { _ in
            self.detectFaceOnDocument()
        }
        .navigationViewStyle(.stack)
        .environmentObject(verIDLoader)
    }
    
    private func readPassport() {
        self.faceCapture = nil
        self.capturedDocument = nil
        self.documentCaptured = false
        Task {
            do {
                let tags: [DataGroupId] = [.COM, .DG1, .DG2, .DG7, .DG11, .DG12, .DG15, .SOD]
                let document = try await self.passportReader.readPassport(mrzKey: self.bac.key, tags: tags)
                await MainActor.run {
                    self.capturedDocument = document
                    self.documentCaptured = true
                }
            } catch {
                NSLog("Failed to read passport: %@", error.localizedDescription)
            }
        }
    }
    
    private func detectFaceOnDocument() {
        if let result = self.verIDLoader.result, case .success(let verID) = result, let utils = verID.utilities, let docImage = self.capturedDocument?.passportImage {
            Task {
                let image = self.image(docImage, paddedToWidth: 720) ?? docImage
                do {
                    guard let face = try await utils.faceDetection.detectRecognizableFacesInImage(image, limit: 1).first else {
                        // TODO: Error
                        throw NSError()
                    }
                    let faceCapture = try FaceCapture(face: face, bearing: .straight, image: image)
                    await MainActor.run {
                        self.faceDetectionError = nil
                        self.faceCapture = faceCapture
                        self.showingCapturedDocument = true
                    }
                } catch {
                    await MainActor.run {
                        self.faceDetectionError = error
                    }
                }
            }
        }
    }
    
    private func image(_ image: UIImage, paddedToWidth minWidth: CGFloat) -> UIImage? {
        if image.size.width < minWidth {
            let borderWidth = minWidth - image.size.width
            UIGraphicsBeginImageContext(CGSize(width: minWidth, height: image.size.height + borderWidth))
            defer {
                UIGraphicsEndImageContext()
            }
            if let context = UIGraphicsGetCurrentContext() {
                context.setFillColor(UIColor.gray.cgColor)
                context.fill([CGRect(x: 0, y: 0, width: borderWidth, height: image.size.height + borderWidth)])
            }
            image.draw(at: CGPoint(x: borderWidth, y: borderWidth))
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        return nil
    }
}
