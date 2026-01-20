//
//  StatCard.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/13/25.
//
import SwiftUI

struct StatCard: View {
    @Environment(\.colorScheme) private var colorScheme
    var title: String
    var value: String
    var color: Color
    var cornerRadius: CGFloat = 25

    var body: some View {
        HStack{
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .foregroundStyle(.mainOpp)
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                Spacer()
            }
            Spacer()
        }
        .padding()
        .frame(height: 120)
        .background(colorScheme == .light
                    ? AnyShapeStyle(Color.white)
                    : AnyShapeStyle(.ultraThinMaterial))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
