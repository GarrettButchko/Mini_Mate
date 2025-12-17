// ProfileView.swift
// MiniMate
//
// Updated to use UserModel and AuthViewModel

import SwiftUI
import FirebaseAuth
import AuthenticationServices
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    
    @ObservedObject var viewManager: ViewManager
    @ObservedObject var authModel: AuthViewModel
    
    @Binding var isSheetPresent: Bool
    @Binding var showLoginOverlay: Bool
    
    @State private var showingPhotoPicker = false
    
    @State private var pickedImage: UIImage? = nil
    
    @StateObject private var viewModel: ProfileViewModel
    
    init(
        viewManager: ViewManager,
        authModel: AuthViewModel,
        isSheetPresent: Binding<Bool>,
        showLoginOverlay: Binding<Bool>,
        context: ModelContext
    ) {
        self.viewManager = viewManager
        self.authModel = authModel
        self._isSheetPresent = isSheetPresent
        self._showLoginOverlay = showLoginOverlay
        
        _viewModel = StateObject(
            wrappedValue: ProfileViewModel(
                authModel: authModel,
                userRepo: UserRepository(context: context),
                localGameRepo: LocalGameRepository(context: context),
                viewManager: viewManager, isSheetPresent: isSheetPresent
            )
        )
    }
    
    
    var body: some View {
        ZStack {
            VStack {
                // Header and drag indicator
                Capsule()
                    .frame(width: 38, height: 6)
                    .foregroundColor(.gray)
                    .padding(10)
                
                HStack {
                    Text("Profile")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.leading, 30)
                    Spacer()
                    Text("Tap to change photo")
                        .font(.caption)
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        if let photoURL = authModel.firebaseUser?.photoURL {
                            AsyncImage(url: photoURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image("logoOpp")
                                    .resizable()
                                    .scaledToFill()
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        } else {
                            Image("logoOpp")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                        }
                    }
                    .padding(.trailing, 30)
                }
                .sheet(isPresented: $showingPhotoPicker) {
                    PhotoPicker(image: $pickedImage)
                        .onChange(of: pickedImage) { old , newImage in
                            viewModel.managePictureChange(newImage: newImage)
                        }
                }
                
                List {
                    // User Details Section
                    Section("User Details") {
                        if let user = authModel.userModel {
                            HStack {
                                Text("Name:")
                                if viewModel.editProfile {
                                    TextField("Name", text: $viewModel.name)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: viewModel.name) { _, newValue in
                                            if newValue.count > 30 {
                                                viewModel.name = String(newValue.prefix(30))
                                            }
                                        }
                                } else {
                                    Text(user.name)
                                }
                            }
                            
                            HStack {
                                Text("Email:")
                                Text(user.email ?? "")
                            }
                            
                            HStack {
                                Text("UID:")
                                Text(user.id)
                            }
                            
                            HStack {
                                Text("Pro:")
                                Text((user.isPro ? "Yes" : "No"))
                            }
                            
                            // Only allow edit/reset for non-social accounts
                            if let firebaseUser = authModel.firebaseUser,
                               !firebaseUser.providerData.contains(where: { $0.providerID == "google.com" || $0.providerID == "apple.com" }) {
                                Button(viewModel.editProfile ? "Save" : "Edit Profile") {
                                    viewModel.manageProfileEditting(user: user)
                                }
                                
                                Button("Password Reset") {
                                    viewModel.passwordReset(user: user)
                                }
                            }
                        } else {
                            Text("User data not available.")
                        }
                    }
                    
                    // Account Management Section
                    Section("Account Management") {
                        
                        Button("Logout") {
                            isSheetPresent = false
                            viewModel.logOut()
                        }
                        .foregroundColor(.red)
                        
                        Button("Delete Account") {
                            viewModel.deleteAccount()
                        }
                        .foregroundColor(.red)
                        
                        .alert(item: $viewModel.activeDeleteAlert) { alertType in
                            switch alertType {
                            case .google:
                                return Alert(
                                    title: Text("Confirm Deletion"),
                                    message: Text("This will permanently delete your account."),
                                    primaryButton: .destructive(Text("Delete")) {
                                        // call Google deletion flow
                                        viewModel.googleReauthAndDelete()
                                    },
                                    secondaryButton: .cancel()
                                )
                                
                            case .apple:
                                return Alert(
                                    title: Text("Confirm Deletion"),
                                    message: Text("This will permanently delete your account."),
                                    primaryButton: .destructive(Text("Delete")) {
                                        viewModel.startAppleReauthAndDelete()
                                    },
                                    secondaryButton: .cancel()
                                )
                                
                            case .email:
                                return Alert(
                                    title: Text("Confirm Deletion"),
                                    message: Text("This will permanently delete your account."),
                                    primaryButton: .destructive(Text("Delete")) {
                                        viewModel.emailReauthAndDelete()
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        }
                    }
                    
                    // Bot Message Section
                    if !viewModel.botMessage.isEmpty {
                        Section("Message") {
                            Text(viewModel.botMessage)
                                .foregroundColor(viewModel.isRed ? .red : .green)
                        }
                    }
                }
                .onAppear {
                    if let user = authModel.userModel {
                        viewModel.name = user.name
                        viewModel.email = user.email ?? ""
                    }
                }
            }
            
            // Reauth Overlay
            if showLoginOverlay {
                ReauthViewOverlay(
                    authModel: authModel, viewManager: viewManager,
                    showLoginOverlay: $showLoginOverlay,
                    isSheetPresent: $isSheetPresent
                )
                .cornerRadius(20)
                .zIndex(1)
            }
        }
    }
}

