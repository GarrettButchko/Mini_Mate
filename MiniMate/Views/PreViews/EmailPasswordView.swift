// SignUpView.swift
// MiniMate
//
// Refactored to use AuthViewModel and UserModel

import SwiftUI
import FirebaseAuth
import SwiftData

/// View for new users to sign up and create an account
struct EmailPasswordView: View {
    @Environment(\.modelContext) private var context

    @ObservedObject var viewManager: ViewManager
    @ObservedObject var authModel: AuthViewModel
    
    @Binding var showEmail: Bool
    
    @Binding var height: CGFloat
    var geometry: GeometryProxy
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    @FocusState private var isTextFieldFocused: Bool

    private let characterLimit = 15

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                Spacer()
                // Title
                VStack(spacing: 8) {
                    HStack {
                        Text("Sign Up / Login")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    HStack {
                        Text("Enter email and password")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                Spacer()

                // Form Fields
                VStack(spacing: 20) {
                    // Email Field
                    VStack(alignment: .leading) {
                        Text("Email")
                            .foregroundColor(.secondary)
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.secondary)
                            TextField("example@example", text: $email)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .focused($isTextFieldFocused)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 25)
                            .fill(.ultraThinMaterial))
                        .overlay(RoundedRectangle(cornerRadius: 25)
                            .stroke(.ultraThickMaterial))
                    }

                    passwordField(title: "Password", text: $password)

                    Button {
                        authModel.signInUIManage(email: email, password: password, authModel: authModel, errorMessage: $errorMessage, context: context, viewManager: viewManager)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .frame(width: 150, height: 50)
                                .foregroundColor(.green)
                            Text("Sign Up / Login")
                                .foregroundColor(.white)
                        }
                    }

                    // Error
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.pink)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
                Spacer()
                Spacer()
            }
            .padding()

            // Back Button
            HStack {
                Button(action: {
                    isTextFieldFocused = false
                    withAnimation {
                        showEmail = false
                    }
                    
                    height = 220
                    
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
            .padding()
        }
    }

    // MARK: - Helpers

    private func passwordField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundColor(.secondary)
            HStack {
                Image(systemName: "lock")
                    .foregroundColor(.secondary)
                SecureField("••••••", text: text)
                    .focused($isTextFieldFocused)
                    .onChange(of: text.wrappedValue) { _ , newValue in
                        if newValue.count > characterLimit {
                            text.wrappedValue = String(newValue.prefix(characterLimit))
                        }
                    }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial))
            .overlay(RoundedRectangle(cornerRadius: 25)
                .stroke(.ultraThickMaterial))
        }
    }
}


