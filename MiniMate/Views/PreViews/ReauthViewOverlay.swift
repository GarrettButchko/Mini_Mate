// ReauthViewOverlay.swift
// MiniMate
//
// Updated to use AuthViewModel.deleteAccount with AuthCredential

import SwiftUI
import FirebaseAuth

/// Overlay for reauthentication before account deletion
struct ReauthViewOverlay: View {
    @Environment(\.modelContext) private var context
    @ObservedObject var authModel: AuthViewModel
    
    private var userRepo: UserRepository { UserRepository(context: context) }

    @ObservedObject var viewManager: ViewManager
    

    @Binding var showLoginOverlay: Bool
    @Binding var isSheetPresent: Bool

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // Transparent background to disable taps
            Color.black.opacity(0.01)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showLoginOverlay = false
                    }
                }

            // Dialog
            VStack(spacing: 20) {
                Text("Reauthenticate")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Enter your credentials to delete your account.")
                    .font(.caption)
                    .multilineTextAlignment(.center)

                // Email
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.gray)
                        TextField("example@example", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }

                // Password
                VStack(alignment: .leading, spacing: 4) {
                    Text("Password")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.gray)
                        SecureField("••••••••", text: $password)
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }

                // Confirm Deletion
                Button(action: {
                    authModel.deleteAccount(email: email, password: password) { result in
                        switch result {
                        case .success:
                            withAnimation {
                                showLoginOverlay = false
                                isSheetPresent = false
                                viewManager.navigateToWelcome()
                            }
                            if let id = authModel.currentUserIdentifier {
                                userRepo.deleteLocal(id: id) { _ in }
                            }
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                }) {
                    Text("Confirm Deletion")
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                // Error
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .frame(maxWidth: 350)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .ignoresSafeArea()
        .zIndex(1)
    }
}
