//
//  SearchBarView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/19/25.
//

import SwiftUI

struct SearchBarView: View {
    
    @Binding var searchText: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .ifAvailableGlassEffect()
                .frame(height: 50)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search", text: $searchText)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.trailing, 5)
            }
            .padding()
        }
    }
}
