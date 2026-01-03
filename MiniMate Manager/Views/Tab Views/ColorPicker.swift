//
//  ColorPicker.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/21/25.
//

import SwiftUI

struct ColorPickerView: View {
    
    @EnvironmentObject var viewModel: CourseViewModel
    
    let colors: [Color] = [
        .red,
        .orange,
        .yellow,
        .green,
        .blue,
        .indigo,
        .purple,
        .pink,
        .brown
    ]
    
    @Binding var showColor: Bool
    @Binding var scoreCardColorPicker: Bool
    
    let function: (_ color: Color) -> Void

    var body: some View {
        ZStack {
            // Background blur
            Rectangle()
                .foregroundStyle(.black.opacity(0.5))
                .ignoresSafeArea()
                .transition(.scale.combined(with: .opacity))
            
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
                                        .fill(color.opacity(!scoreCardColorPicker && viewModel.selectedCourse?.courseColors != nil && viewModel.selectedCourse?.courseColors!.contains(color) == true ? 0.3 : 1))
                                        .frame(width: 30, height: 30)
                                }
                        }
                        .disabled(!scoreCardColorPicker && viewModel.selectedCourse?.courseColors != nil && viewModel.selectedCourse?.courseColors!.contains(color) == true)
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
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                }
            }
            .padding()
            .background(){
                RoundedRectangle(cornerRadius: 25)
                    .ifAvailableGlassEffect()
                    .shadow(radius: 5)
            }
            .padding()
            .transition(.scale.combined(with: .opacity))
        }
        
    }
}


