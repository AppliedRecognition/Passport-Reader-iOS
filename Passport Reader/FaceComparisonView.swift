//
//  FaceComparisonView.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 12/08/2025.
//

import SwiftUI

struct FaceComparisonView: View {
    
    let documentFaceImage: UIImage
    let selfieFaceImage: UIImage
    let score: Float
    let name: String
    let threshold: Float
    var message: String
    let title: String
    
    init(documentFaceImage: UIImage, selfieFaceImage: UIImage, score: Float, name: String, glassesDetected: Bool) {
        self.documentFaceImage = documentFaceImage
        self.selfieFaceImage = selfieFaceImage
        self.score = score
        self.name = name
        self.threshold = faceRecognition.defaultThreshold
        self.message = score >= threshold ?
            String(format: "The comparison score %.02f suggests that the captured face is %@.", self.score, self.name) :
            String(format: "The comparison score %.02f suggests that the captured face is not %@.", self.score, self.name)
        self.title = score >= threshold ? name : "Not \(name)"
        if glassesDetected && score < threshold {
            self.message.append(" Face recognition accuracy may be affected by the presence of glasses.")
        }
    }
    
    var body: some View {
        let columns = [GridItem(.flexible(), spacing: 16),
                       GridItem(.flexible(), spacing: 16)]
        
        VStack(spacing: 16) {
            LazyVGrid(columns: columns, spacing: 16) {
                Image(uiImage: documentFaceImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .clipped()
                
                Image(uiImage: selfieFaceImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .clipped()
            }
            Text(self.message)
            Spacer()
        }
        .padding()
        .frame(maxWidth: 560)
        .navigationTitle(self.title)
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        FaceComparisonView(
            documentFaceImage: UIImage(systemName: "person")!,
            selfieFaceImage: UIImage(systemName: "person.fill")!,
            score: 0.7,
            name: "Lazy Cheetah",
            glassesDetected: false
        )
    }
}

#Preview {
    NavigationStack {
        FaceComparisonView(
            documentFaceImage: UIImage(systemName: "person")!,
            selfieFaceImage: UIImage(systemName: "person.fill")!,
            score: 0.2,
            name: "Lazy Cheetah",
            glassesDetected: true
        )
    }
}
