//
//  SectionStatsView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/13/25.
//
import SwiftUI
import SwiftData

struct SectionStatsView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    var title: String
    var makeColor: Color? = nil
    @ViewBuilder var content: () -> Content
    
    

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(.mainOpp)
                Spacer()
            }
            content()
        }
        .padding()
        .ultraThinMaterialVsColor(makeColor: makeColor)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
}
