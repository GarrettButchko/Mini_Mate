//
//  isAvaliableGlassEffect.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/19/25.
//
import SwiftUI

extension Shape {
    @ViewBuilder
    func ifAvailableGlassEffect() -> some View {
        if #available(iOS 26.0, *) {
            self
                .fill(Color(.subTwo).opacity(0.3))
                .glassEffect(in: self)
                .clipShape(self) // clip BEFORE adding border
                .overlay(self.stroke(Color(.subTwo), lineWidth: 1)) // ← correct border
        } else {
            self
                .fill(.ultraThinMaterial)
                .clipShape(self)
                .overlay(self.stroke(Color(.subTwo), lineWidth: 1))
                .shadow(radius: 10)
        }
    }
}
