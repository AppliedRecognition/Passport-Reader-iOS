//
//  BacEntryView.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 12/08/2025.
//

import SwiftUI

struct BacEntryView: View {
    
    @ObservedObject var bac: Bac
    
    var body: some View {
        VStack {
            HStack {
                Text("Document number")
                Spacer()
                TextField("Document number", text: self.$bac.documentNumber)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.asciiCapable)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.characters)
            }
            .padding(.bottom, 8)
            DatePicker("Date of birth", selection: self.$bac.dateOfBirth, displayedComponents: .date).datePickerStyle(.compact)
            DatePicker("Date of expiry", selection: self.$bac.dateOfExpiry, displayedComponents: .date).datePickerStyle(.compact)
        }
    }
}

#Preview {
    NavigationStack {
        VStack(alignment: .leading, spacing: 8) {
            BacEntryView(
                bac: Bac()
            )
            Button {
                
            } label: {
                Text("Capture")
            }.buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Passport reader")
    }
}
