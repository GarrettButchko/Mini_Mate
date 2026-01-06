//
//  VerifyView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 1/6/26.
//

import SwiftUI
import FirebaseAuth
import SwiftData

/// View for new users to sign up and create an account
struct VerifyView: View {
    @Environment(\.modelContext) private var context
    
    @ObservedObject var viewManager: ViewManager
    @ObservedObject var authModel: AuthViewModel
    
    @Binding var showVerify: Bool
    @Binding var showEmail: Bool
    
    var body: some View {
        VStack {
            // Back Button
            HStack {
                Button(action: {
                    withAnimation {
                        showEmail = true
                    }
                }) {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "arrow.left")
                                .font(.headline)
                                .foregroundStyle(.green)
                        )
                }
                Spacer()
            }
            
            Spacer()
            // Title
            VStack(spacing: 8) {
                HStack {
                    Text("Verify email to Continue")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                HStack {
                    Text("I'll be waiting ;)")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            Spacer()
            
            
        }
        .padding()
    }
}
