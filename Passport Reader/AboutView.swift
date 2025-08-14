//
//  AboutView.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 13/08/2025.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("This app shows how to use the Ver\u{2011}ID SDK to compare a face from a travel document to a selfie.")
                Text("The app uses near-field communication (NFC) to read the chip embedded in machine-readable travel documents, such as passports.")
                Text("The image from the travel document is then compared to a selfie captured using Ver\u{2011}ID's face capture library.")
                Text("The app doesn't store the captured document details or the captured face beyond the duration of the app's lifecycle.")
            }
            .frame(maxWidth: 500)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
        }
        .navigationTitle("About")
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
