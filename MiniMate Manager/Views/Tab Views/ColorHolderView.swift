//
//  ColorHolderView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/21/25.
//

import SwiftUI

struct ColorHolderView: View {
    
    var color: Color? = nil
    
    @Binding var showDeleteColor: Bool
    @Binding var showColor: Bool
    
    let showFunction: () -> Void
    let deleteFunction: () -> Void
    
    var body: some View {
        
    if let color {
        Button {
            showDeleteColor = true
        } label: {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 40, height: 40)
                .overlay(content: {
                    Circle()
                        .fill(color)
                        .frame(width: 30, height: 30)
                })
        }
        .alert("Delete color?", isPresented: $showDeleteColor){
            Button("Delete", role: .destructive, action: {
                deleteFunction()
            })
            Button("Cancel", role: .cancel, action: {showDeleteColor = false})
        } message: {
            Text("Are you sure you want to delete this color?")
        }
    } else {
        Button {
            withAnimation(){
                showFunction()
                showColor = true
            }
        } label: {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "plus")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
        }
    }
    }
}


