//
//  PassportView.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 01/05/2023.
//

import SwiftUI
import VerIDCore
import VerIDUI

struct PassportView: View {
    
    let faceCapture: FaceCapture
    let name: String
    let details: [DocSection]
    @EnvironmentObject var verIDLoader: VerIDLoader
    @StateObject var verIDSessionRunner: VerIDSessionRunner = VerIDSessionRunner()
    @State var showingComparisonResult: Bool = false
    
    init(faceCapture: FaceCapture, name: String, details: [DocSection]) {
        self.faceCapture = faceCapture
        self.name = name
        self.details = details
    }
    
    var body: some View {
        if let faceCapture = self.verIDSessionRunner.sessionResult?.faceCaptures.first(where: { $0.bearing == .straight }), self.showingComparisonResult {
            NavigationLink(isActive: self.$showingComparisonResult) {
                FaceComparisonView(documentFace: self.faceCapture, liveFace: faceCapture)
            } label: {
                EmptyView()
            }
        } else {
            ZStack {
                GeometryReader { proxy in
                    VStack {
                        Spacer()
                        Image("selfie").resizable().aspectRatio(contentMode: .fit).frame(width: proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing, height: proxy.size.height + proxy.safeAreaInsets.bottom, alignment: .bottomTrailing).offset(y: proxy.safeAreaInsets.bottom)
                    }.ignoresSafeArea()
                }
                VStack(alignment: .leading) {
                    HStack {
                        NavigationLink {
                            PassportDetailsView(details: self.details)
                        } label: {
                            Image(uiImage: self.faceCapture.faceImage)
                                .resizable()
                                .aspectRatio(4/5, contentMode: .fit)
                                .frame(height: 150)
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                    HStack {
                        VerIDButton(label: "Compare to selfie") {
                            self.captureSelfie()
                        }
                        Spacer()
                    }
                    .padding(.top, 16)
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(self.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        PassportDetailsView(details: self.details)
                    } label: {
                        Text("Details")
                    }
                }
            }
        }
    }
    
    private func captureSelfie() {
        guard let result = self.verIDLoader.result, case .success(let verID) = result else {
            return
        }
        self.verIDSessionRunner.sessionResult = nil
        self.showingComparisonResult = true
        self.verIDSessionRunner.startSession(verID: verID)
    }
}

struct VerIDButton: View {
    
    @EnvironmentObject var verIDLoader: VerIDLoader
    
    let label: String
    let onTap: () -> Void
    
    init(label: String, onTap: @escaping () -> Void) {
        self.label = label
        self.onTap = onTap
    }
    
    var body: some View {
        switch verIDLoader.result {
        case .none:
            Button {
                
            } label: {
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding(.trailing, 1)
                Text(self.label)
            }
            .buttonStyle(.borderedProminent)
            .disabled(true)
        case .success(_):
            Button(action: self.onTap) {
                Image(systemName: "camera.fill")
                Text(self.label)
            }
            .buttonStyle(.borderedProminent)
        case .failure(_):
            Button {
                
            } label: {
                Image(systemName: "hand.raised.fill")
                Text(self.label)
            }
            .buttonStyle(.borderedProminent)
            .disabled(true)
        }
    }
}
