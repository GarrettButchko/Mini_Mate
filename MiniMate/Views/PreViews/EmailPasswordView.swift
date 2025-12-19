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
    @State var showSignUp: Bool = false
    
    @Binding var height: CGFloat
    var geometry: GeometryProxy
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?

    @FocusState private var isTextFieldFocused: Bool

    private let characterLimit = 15
    
    var disabled: Bool {
        if !showSignUp {
            return email.isEmpty || password.isEmpty
        } else {
            return email.isEmpty || password.isEmpty || confirmPassword.isEmpty || password != confirmPassword
        }
    }

    var body: some View {
            VStack {
            
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
                
                Spacer()
                // Title
                VStack(spacing: 8) {
                    HStack {
                        Text(showSignUp ? "Sign Up" : "Login")
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
                    
                    if showSignUp {
                        passwordField(title: "Confirm Password", text: $confirmPassword)
                    }

                    Button {
                        if !showSignUp {
                            authModel.signInUIManage(email: email, password: password, authModel: authModel, errorMessage: $errorMessage, showSignUp: $showSignUp, context: context, viewManager: viewManager)
                        } else {
                            authModel.createUser(email: email, password: password) { result in
                                switch result {
                                case .success(let firebaseUser):
                                    authModel.createOrSignInUserAndNavigateToHome(context: context, authModel: authModel, viewManager: viewManager, user: firebaseUser, errorMessage: $errorMessage, signInMethod: .email)
                                case .failure(let error):
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .frame(width: 150, height: 50)
                                .foregroundColor(.green)
                            Text(showSignUp ? "Sign Up" : "Login")
                                .foregroundColor(.white)
                        }
                        .opacity(disabled ? 0.5 : 1)
                    }
                    .disabled(disabled)

                    // Error
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
                Spacer()
                Spacer()
            }
            .padding()
    }

    // MARK: - Helpers

    private func passwordField(title: String, text: Binding<String>, image: String = "lock") -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundColor(.secondary)
            HStack {
                Image(systemName: image)
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


