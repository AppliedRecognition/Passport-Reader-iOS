//
//  FaceComparisonView.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 01/05/2023.
//

import SwiftUI
import VerIDUI
import NormalDistribution

struct FaceComparisonView: View {
    
    let documentFace: FaceCapture
    let liveFace: FaceCapture
    let threshold: Float = 4.0
    @EnvironmentObject var verIDLoader: VerIDLoader
    @State var comparisonResult: Result<Float,Error>?
    @State var probability: Double?
    var barTitle: String {
        switch self.comparisonResult {
        case .none:
            return "..."
        case .success(let score):
            return String(format: "Score %.02f", score)
        case .failure(_):
            return "Error"
        }
    }
    
    init(documentFace: FaceCapture, liveFace: FaceCapture) {
        self.documentFace = documentFace
        self.liveFace = liveFace
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(uiImage: self.documentFace.faceImage).resizable().aspectRatio(4/5, contentMode: .fit).frame(height: 150).cornerRadius(8).padding(.trailing, 16)
                Image(uiImage: self.liveFace.faceImage).resizable().aspectRatio(4/5, contentMode: .fit).frame(height: 150).cornerRadius(8)
                Spacer()
            }
            .padding(.bottom, 16)
            switch self.comparisonResult {
            case .none:
                ProgressView {
                    Text("Comparing faces")
                }.progressViewStyle(.circular)
            case .success(let score):
                if score >= self.threshold {
                    Text(String(format: "The face matching score %.02f indicates a likelihood of %.0f%% that the person on the ID card is the same person as the one in the selfie. We recommend a threshold of %.02f for a positive identification when comparing faces from identity cards.", score, self.probability ?? 0, self.threshold))
                } else {
                    Text(String(format: "The face matching score %.02f indicates that the person on the ID card is likely NOT the same person as the one in the selfie. We recommend a threshold of %.02f for a positive identification when comparing faces from identity cards.", score, self.threshold))
                }
                Spacer()
            case .failure(let error):
                Text("Comparison failed: \(error.localizedDescription)")
                Spacer()
            }
        }
        .navigationTitle(self.barTitle)
        .navigationBarTitleDisplayMode(.large)
        .padding()
        .task {
            if let result = self.verIDLoader.result, case .success(let verID) = result {
                do {
                    let score = try verID.faceRecognition.compareSubjectFaces([documentFace.face], toFaces: [liveFace.face])
                    self.probability = try? NormalDistribution().cumulativeProbability(Double(score.floatValue)) * 100
                    self.comparisonResult = .success(score.floatValue)
                } catch {
                    self.probability = nil
                    self.comparisonResult = .failure(error)
                }
            }
        }
    }
}

//struct FaceComparisonView_Previews: PreviewProvider {
//    static var previews: some View {
//        FaceComparisonView()
//    }
//}
