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
    var spacing: CGFloat
    
    var makeColor: Color? = nil
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            HStack {
                Text(title)
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(.mainOpp)
                Spacer()
            }
            content()
        }
        .padding()
        .background{
            RoundedRectangle(cornerRadius: 25)
                .fill(.sub)
                .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
        }
        
    }
}
