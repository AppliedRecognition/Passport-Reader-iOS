//
//  PassportDetailsView.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 13/08/2025.
//

import SwiftUI
import VerIDCommonTypes

struct PassportDetailsView: View {
    
    let details: [DocSection]
    let faceImage: UIImage
    
    init(face: Face, image: VerIDCommonTypes.Image, details: [DocSection]) {
        self.details = details
        self.faceImage = FaceImageUtil.cropImage(image, toSquareCenteredAt: CGPoint(x: face.bounds.midX, y: face.bounds.midY))
    }
    
    var body: some View {
        List {
            Image(uiImage: self.faceImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
                .listRowInsets(EdgeInsets())
            ForEach(details) { section in
                Section {
                    ForEach(section.rows) { row in
                        HStack {
                            Text(row.name)
                            Spacer()
                            Text(row.value)
                        }
                    }
                } header: {
                    Text(section.name)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Document details")
    }
}

#Preview {
    let image = VerIDCommonTypes.Image(cgImage: UIImage(systemName: "person")!.cgImage!)!
    let face = Face(bounds: CGRect(origin: .zero, size: image.size), angle: .identity, quality: 0, landmarks: [], leftEye: .zero, rightEye: .zero, noseTip: .zero)
    return NavigationStack {
        PassportDetailsView(
            face: face,
            image: image,
            details: [
                DocSection(name: "Document holder", rows: [
                    DocSectionRow(name: "First name", value: "LAZY"),
                    DocSectionRow(name: "Last name", value: "CHEETAH"),
                    DocSectionRow(name: "Nationality", value: "CAN"),
                    DocSectionRow(name: "Sex", value: "F"),
                    DocSectionRow(name: "Date of birth", value: "October 1, 2000")
                ]),
                DocSection(name: "Document", rows: [
                    DocSectionRow(name: "Document number", value: "ABC123456"),
                    DocSectionRow(name: "Issuing authority", value: "CAN"),
                    DocSectionRow(name: "Date of expiry", value: "20 August, 2035")
                ]),
                DocSection(name: "Verification", rows: [
                    DocSectionRow(name: "Active authentication", value: "Passed"),
                    DocSectionRow(name: "Chip authentication", value: "Passed"),
                    DocSectionRow(name: "Access control", value: "BAC"),
                    DocSectionRow(name: "PACE authentication", value: "Not done"),
                    DocSectionRow(name: "BAC authentication", value: "Passed"),
                    DocSectionRow(name: "Document signing certificate", value: "Verified"),
                    DocSectionRow(name: "Country signing certificate", value: "Verified"),
                    DocSectionRow(name: "Tamper detection", value: "Unverified")
                ])
            ]
        )
    }
}
