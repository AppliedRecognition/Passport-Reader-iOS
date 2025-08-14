//
//  ContentView.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 12/08/2025.
//

import SwiftUI
import NFCPassportReader
import FaceDetectionRetinaFace
import VerIDCommonTypes
import FaceRecognitionArcFaceCloud
import FaceCapture

struct ContentView: View {
    
    @State var navigationPath = NavigationPath()
    @StateObject var bac = Bac()
    @State var error: Error?
    @State var activity: String?
    let passportReader = PassportReader(masterListURL: Bundle.main.url(forResource: "MasterList", withExtension: "pem"))
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Image("Passport")
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .ignoresSafeArea()
                if let activity = self.activity {
                    VStack(spacing: 16) {
                        ProgressView().progressViewStyle(.circular)
                        Text(activity)
                    }
                } else {
                    VStack {
                        VStack(alignment: .leading, spacing: 16) {
                            BacEntryView(bac: self.bac)
                            Button {
                                self.readPassport()
                            } label: {
                                Text("Scan passport")
                                Image(systemName: "wave.3.right")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(self.bac.documentNumber.isEmpty)
                        }
                        .frame(maxWidth: 500)
                        .padding()
                        Spacer()
                    }
                    .padding(.bottom, 100)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .navigationTitle("Passport reader")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.navigationPath.append(Route.about)
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .document(face: let face, image: let image, name: let name, details: let details):
                    PassportView(face: face, image: image, name: name, details: details, faceRecognition: faceRecognition, navigationPath: self.$navigationPath)
                case .comparison(documentFace: let face1, documentImage: let image1, selfieFace: let face2, selfieImage: let image2, score: let score, name: let name):
                    let docImage = FaceImageUtil.cropImage(image1, toFace: face1)
                    let selfieImage = FaceImageUtil.cropImage(image2, toFace: face2)
                    FaceComparisonView(documentFaceImage: docImage, selfieFaceImage: selfieImage, score: score, name: name)
                case .documentDetails(documentFace: let face, documentImage: let image, details: let details):
                    PassportDetailsView(face: face, image: image, details: details)
                case .about:
                    AboutView()
                case .tips:
                    TipsView()
                }
            }
            .alert("Error", isPresented: Binding(get: { self.error != nil }, set: { if !$0 { self.error = nil }}), presenting: self.error) { error in
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
    }
    
    private func readPassport() {
        Task(priority: .high) {
            do {
                let tags: [DataGroupId] = [.COM, .DG1, .DG2, .DG7, .DG11, .DG12, .DG15, .SOD]
                NSLog("MRZ key: \(self.bac.key)")
                let result = try await self.passportReader.readPassport(mrzKey: self.bac.key, tags: tags)
                let name = "\(result.firstName) \(result.lastName)".trimmingCharacters(in: .whitespaces)
                guard let image = result.passportImage, let cgImage = image.cgImage, let veridImage = VerIDCommonTypes.Image(cgImage: cgImage) else {
                    throw NSError()
                }
                guard let face = try await FaceDetectionRetinaFace().detectFacesInImage(veridImage, limit: 1).first else {
                    throw NSError()
                }
                await MainActor.run {
                    self.navigationPath.append(Route.document(face: face, image: veridImage, name: NameUtil.humanizeName(name), details: result.list))
                }
            } catch {
                // NFCPassportReader handles the UI
            }
        }
    }
}

#Preview {
    ContentView()
}

enum Route: Hashable {
    case document(face: Face, image: VerIDCommonTypes.Image, name: String, details: [DocSection])
    case comparison(documentFace: Face, documentImage: VerIDCommonTypes.Image, selfieFace: Face, selfieImage: VerIDCommonTypes.Image, score: Float, name: String)
    case documentDetails(documentFace: Face, documentImage: VerIDCommonTypes.Image, details: [DocSection])
    case about
    case tips
}

let faceRecognition: FaceRecognitionArcFace = {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "FaceRecognitionApiKey") as? String, let urlString = Bundle.main.object(forInfoDictionaryKey: "FaceRecognitionUrl") as? String, let url = URL(string: urlString) {
        return FaceRecognitionArcFace(apiKey: apiKey, url: url)
    } else {
        fatalError()
    }
}()
