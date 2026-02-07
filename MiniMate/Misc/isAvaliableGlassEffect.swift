//
//
//  isAvaliableGlassEffect.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/19/25.
//
import SwiftUI

extension Shape {
    @ViewBuilder
    func ifAvailableGlassEffect(strokeWidth: CGFloat = 1, opacity: CGFloat = 0.30, makeColor: Color? = nil) -> some View {
        let fillColor = (makeColor ?? Color.subTwo).opacity(opacity)
        let strokeColor = (makeColor ?? Color.subTwo)

        if #available(iOS 26.0, *) {
            self
                .fill(fillColor)
                .glassEffect(in: self)
                .clipShape(self) // clip BEFORE adding border
                .overlay(self.stroke(strokeColor, lineWidth: strokeWidth)) // ← correct border
        } else {
            self
                .ultraThinMaterialVsColorFill(makeColor: fillColor)
                .clipShape(self)
                .overlay(self.stroke(strokeColor, lineWidth: strokeWidth))
                .shadow(radius: 10)
        }
    }
}


extension View {
    @ViewBuilder
    func ultraThinMaterialVsColor(makeColor: Color?) -> some View {
        if let makeColor {
            self
                .background(makeColor.opacity(0.50))
        } else {
            self
                .background(.ultraThinMaterial)
        }
    }
}

extension Shape {
    @ViewBuilder
    func ultraThinMaterialVsColorFill(makeColor: Color?) -> some View {
        if let makeColor {
            self
                .fill(makeColor.opacity(0.50))
        } else {
            self
                .fill(.ultraThinMaterial)
        }
    }
}


