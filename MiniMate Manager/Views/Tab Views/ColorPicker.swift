//
//  ColorPicker.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/21/25.
//

import SwiftUI

struct ColorPickerView: View {
    
    let colors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown, .gray, .black
    ]
    
    @Binding var showColor: Bool
    
    let function: (_ color: Color) -> Void

    var body: some View {
        ZStack {
            // Background blur
            Rectangle()
                .foregroundStyle(.ultraThinMaterial)
                .ignoresSafeArea()
            
            // Popup card
            VStack(spacing: 20) {
                Text("Pick a Color")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 20) {
                    ForEach(colors, id: \.self) { color in
                        Button {
                            function(color)
                        } label: {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 30, height: 30)
                                }
                        }
                    }
                }
                
                Button {
                    withAnimation() {
                        showColor = false
                    }
                } label: {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .padding()
            .transition(.scale.combined(with: .opacity))
        }
        
    }
}


