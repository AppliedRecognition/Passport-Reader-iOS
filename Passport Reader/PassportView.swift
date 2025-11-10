//
//  PassportView.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 12/08/2025.
//

import SwiftUI
import VerIDCommonTypes
import FaceCapture
import FaceRecognitionR300Core
import FaceRecognitionR300Cloud
import FaceDetectionRetinaFace
import SpoofDeviceDetection

@MainActor
struct PassportView<T: FaceRecognition>: View where T.Version == R300, T.TemplateData == [Float] {
    
    let face: Face
    let image: VerIDCommonTypes.Image
    let name: String
    let details: [DocSection]
    let faceImage: UIImage
    @Binding var navigationPath: NavigationPath
    @State private var model: FaceMatchingModel<T>
    @State private var faceCaptureError: Error?
    
    init(face: Face, image: VerIDCommonTypes.Image, name: String, details: [DocSection], faceRecognition: T, navigationPath: Binding<NavigationPath>) {
        self.face = face
        self.image = image
        self.name = name
        self.details = details
        self.faceImage = FaceImageUtil.cropImage(image, toFace: face)
        self._model = State(initialValue: FaceMatchingModel(documentFace: face, image: image, faceRecognition: faceRecognition))
        self._navigationPath = navigationPath
    }
    
    var body: some View {
        ZStack {
            Image("selfie")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .ignoresSafeArea()
            switch self.model.phase {
            case .idle, .extractingDocumentTemplate, .capturingSelfie:
                VStack(alignment: .leading, spacing: 16) {
                    if let docHolderSection = self.details.first(where: { section in
                        section.name == "Document holder"
                    }) {
                        HStack(alignment: .top, spacing: 8) {
                            VStack(spacing: 8) {
                                ForEach(docHolderSection.rows.filter { $0.name != "First name" && $0.name != "Last name" }) { row in
                                    HStack {
                                        Text(row.name)
                                        Spacer()
                                        Text(row.value)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }
                                }
                            }
                            .frame(maxWidth: 320)
                            Spacer()
                            Image(uiImage: self.faceImage)
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    Button {
                        self.captureFace()
                    } label: {
                        Image(systemName: "camera.fill")
                        Text("Capture face")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        self.navigationPath.append(Route.tips)
                    } label: {
                        Image(systemName: "questionmark.circle")
                        Text("Face capture tips")
                    }
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .topLeading)
            case .extractingSelfieTemplate, .comparing:
                VStack(spacing: 16) {
                    ProgressView().progressViewStyle(.circular)
                    Text("Comparing faces")
                }
                .padding(.bottom, 100)
            case .done(selfieFace: _, score: _, glassesDetected: _):
                EmptyView()
            case .failed(let error):
                VStack(spacing: 16) {
                    Text("Error").font(.title)
                    Text(error.localizedDescription)
                }
                .padding(.bottom, 100)
            }
        }
        .navigationTitle(self.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    self.navigationPath.append(Route.documentDetails(documentFace: self.face, documentImage: self.image, details: self.details))
                } label: {
                    Image(systemName: "rectangle.and.text.magnifyingglass")
                }
            }
        }
        .task {
            self.model.start()
        }
        .onChange(of: self.model.phase) { _, phase in
            if case .done(selfieFace: let selfieFace, score: let score, glassesDetected: let glassesDetected) = phase {
                self.navigationPath.append(Route.comparison(documentFace: self.face, documentImage: self.image, selfieFace: selfieFace.face, selfieImage: selfieFace.image, score: score, name: self.name, glassesDetected: glassesDetected))
            }
        }
        .alert("Face capture failed", isPresented: Binding(get: { self.faceCaptureError != nil }, set: { if !$0 { self.faceCaptureError = nil }}), presenting: self.faceCaptureError) { error in
            Button(role: .cancel) {} label: {
                Text("OK")
            }
        } message: { error in
            if error is LocalizedError {
                Text(error.localizedDescription)
            } else {
                EmptyView()
            }
        }
    }
    
    private func captureFace() {
        Task(priority: .high) {
            do {
                let result = await FaceCapture.captureFaces { config in
                    config.faceDetection = try FaceDetectionRetinaFace()
                    config.useBackCamera = false
                    if FaceCaptureSession.supportsDepthCaptureOnDeviceAt(.front) {
                        config.faceTrackingPlugins = [DepthLivenessDetection()]
                    } else if let apiKey = Bundle.main.object(forInfoDictionaryKey: "SpoofDetectionApiKey") as? String, let urlString = Bundle.main.object(forInfoDictionaryKey: "SpoofDetectionApiUrl") as? String, let url = URL(string: urlString) {
                        let spoofDetector = SpoofDeviceDetection(apiKey: apiKey, url: url)
                        config.faceTrackingPlugins = [try LivenessDetectionPlugin(spoofDetectors: [spoofDetector])]
                    }
                }
                switch result {
                case .success(capturedFaces: let faces, metadata: _):
                    let capturedFace = faces.first!
                    self.model.onSelfie(capturedFace)
                case .failure(capturedFaces: _, metadata: _, error: let error):
                    throw error
                case .cancelled:
                    break
                }
            } catch {
                await MainActor.run {
                    self.faceCaptureError = error
                }
            }
        }
    }
}

class MockFaceRecognition: FaceRecognition {
    var defaultThreshold: Float = 0.5
    
    typealias Version = R300
    typealias TemplateData = [Float]
    
    func createFaceRecognitionTemplates(from faces: [VerIDCommonTypes.Face], in image: VerIDCommonTypes.Image) async throws -> [VerIDCommonTypes.FaceTemplate<R300, [Float]>] {
        return faces.map { _ in
            FaceTemplate(data: [0.5])
        }
    }
    
    func compareFaceRecognitionTemplates(_ faceRecognitionTemplates: [VerIDCommonTypes.FaceTemplate<R300, [Float]>], to template: VerIDCommonTypes.FaceTemplate<R300, [Float]>) async throws -> [Float] {
        return faceRecognitionTemplates.map { _ in
            0.6
        }
    }
}

#Preview {
    NavigationStack {
        let image = VerIDCommonTypes.Image(cgImage: UIImage(systemName: "person")!.cgImage!)!
        PassportView(
            face: Face(bounds: CGRect(origin: .zero, size: image.size), angle: .identity, quality: 0, landmarks: [], leftEye: .zero, rightEye: .zero, noseTip: .zero),
            image: image,
            name: "Lazy Cheetah",
            details: [DocSection(name: "Document holder", rows: [
                DocSectionRow(name: "First name", value: "Lazy"),
                DocSectionRow(name: "Last name", value: "Cheetah"),
                DocSectionRow(name: "Nationality", value: "Kenya"),
                DocSectionRow(name: "Sex", value: "Female"),
                DocSectionRow(name: "Date of birth", value: "1 October, 2000")
            ])],
            faceRecognition: MockFaceRecognition(),
            navigationPath: .constant(NavigationPath())
        )
    }
}
