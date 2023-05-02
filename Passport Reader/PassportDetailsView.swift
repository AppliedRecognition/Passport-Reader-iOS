//
//  PassportDetailsView.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 28/04/2023.
//

import SwiftUI

struct PassportDetailsView: View {
    
    let details: [DocSection]
    
    init(details: [DocSection]) {
        self.details = details
    }
    
    var body: some View {
        List {
            ForEach(self.details) { section in
                Section(section.name) {
                    ForEach(section.rows) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text(item.value)
                        }
                    }
                }
            }
        }
        .navigationTitle("Document details")
        .navigationBarTitleDisplayMode(.large)
        .listStyle(.plain)
    }
}
