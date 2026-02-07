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
    var cornerRadius: CGFloat = 12

    var body: some View {
        HStack{
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .foregroundStyle(.mainOpp)
                    .fontWeight(.semibold)
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                Spacer()
            }
            Spacer()
        }
        .padding()
        .background(colorScheme == .light
                    ? AnyShapeStyle(Color.white)
                    : AnyShapeStyle(.ultraThinMaterial))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
