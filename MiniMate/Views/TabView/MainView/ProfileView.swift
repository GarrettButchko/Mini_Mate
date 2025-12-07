// ProfileView.swift
// MiniMate
//
// Updated to use UserModel and AuthViewModel

import SwiftUI
import FirebaseAuth
import AuthenticationServices

enum DeleteAlertType: Identifiable {
    case google
    case apple
    case email
    
    var id: Int {
        switch self {
        case .google: return 0
        case .apple:  return 1
        case .email:  return 2
        }
    }
}


/// Displays and allows editing of the current user's profile
struct ProfileView: View {
    @Environment(\.modelContext) private var context
    
    @ObservedObject var viewManager: ViewManager
    @ObservedObject var authModel: AuthViewModel
    
    @Binding var isSheetPresent: Bool
    @Binding var showLoginOverlay: Bool
    
    @State private var editProfile: Bool = false
    @State private var showGoogleDeleteConfirmation: Bool = false
    @State private var showAppleDeleteConfirmation: Bool = false
    @State private var showingPhotoPicker = false
    @State private var showAdminLogin: Bool = false
    @State private var isRed: Bool = true
    
    @State private var adminCode: String = ""
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var botMessage: String = ""
    @State private var adminSignInMessage: String = ""
    
    @State private var pickedImage: UIImage? = nil
    
    @State private var activeDeleteAlert: DeleteAlertType? = nil
    
    @State private var reauthCoordinator = AppleReauthCoordinator { _ in }
    
    private var localGameRepo: LocalGameRepository { LocalGameRepository(context: context) }
    private var userRepo: UserRepository { UserRepository(context: context) }
    
    let courseRepo = CourseRepository()
    
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
                        .onChange(of: pickedImage) { old ,newImage in
                            guard let img = newImage else { return }
                            
                            userRepo.uploadProfilePhoto(id: authModel.currentUserIdentifier!, img) { result in
                                switch result {
                                case .success(let url):
                                    print("✅ Photo URL:", url)
                                case .failure(let error):
                                    print("❌ Photo upload failed:", error)
                                }
                            }
                        }
                }
                
                List {
                    // User Details Section
                    Section("User Details") {
                        if let user = authModel.userModel {
                            HStack {
                                Text("Name:")
                                if editProfile {
                                    TextField("Name", text: $name)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: name) { _, newValue in
                                            if newValue.count > 30 {
                                                name = String(newValue.prefix(30))
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
                                Button(editProfile ? "Save" : "Edit Profile") {
                                    if editProfile {
                                        authModel.userModel?.name = name
                                        userRepo.saveRemote(id: authModel.currentUserIdentifier!, userModel: authModel.userModel!) { _ in }
                                        editProfile = false
                                    } else {
                                        name = user.name
                                        editProfile = true
                                    }
                                }
                                
                                Button("Password Reset") {
                                    let targetEmail = user.email ?? ""
                                    Auth.auth().sendPasswordReset(withEmail: targetEmail) { error in
                                        if let error = error {
                                            botMessage = error.localizedDescription
                                            isRed = true
                                        } else {
                                            botMessage = "Password reset email sent!"
                                            isRed = false
                                        }
                                    }
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
                            withAnimation {
                                viewManager.navigateToWelcome()
                            }
                            authModel.logout()
                        }
                        .foregroundColor(.red)
                        
                        

                        Button("Delete Account") {
                            guard let firebaseUser = authModel.firebaseUser else {
                                    activeDeleteAlert = .email
                                    return
                                }
                                if firebaseUser.providerData.contains(where: { $0.providerID == "google.com" }) {
                                    activeDeleteAlert = .google
                                } else if firebaseUser.providerData.contains(where: { $0.providerID == "apple.com" }) {
                                    activeDeleteAlert = .apple
                                } else {
                                    activeDeleteAlert = .email
                                }
                        }
                        .foregroundColor(.red)
                        
                        .alert(item: $activeDeleteAlert) { alertType in
                            switch alertType {
                            case .google:
                                return Alert(
                                    title: Text("Confirm Deletion"),
                                    message: Text("This will permanently delete your account."),
                                    primaryButton: .destructive(Text("Delete")) {
                                        // call Google deletion flow
                                        googleReauthAndDelete()
                                    },
                                    secondaryButton: .cancel()
                                )
                                
                            case .apple:
                                return Alert(
                                    title: Text("Confirm Deletion"),
                                    message: Text("This will permanently delete your account."),
                                    primaryButton: .destructive(Text("Delete")) {
                                        startAppleReauthAndDelete()
                                    },
                                    secondaryButton: .cancel()
                                )
                                
                            case .email:
                                return Alert(
                                    title: Text("Confirm Deletion"),
                                    message: Text("This will permanently delete your account."),
                                    primaryButton: .destructive(Text("Delete")) {
                                        emailReauthAndDelete()
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        }
                    }
                    
                    // Bot Message Section
                    if !botMessage.isEmpty {
                        Section("Message") {
                            Text(botMessage)
                                .foregroundColor(isRed ? .red : .green)
                        }
                    }
                }
                .onAppear {
                    if let user = authModel.userModel {
                        name = user.name
                        email = user.email ?? ""
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
    
    /// Starts Sign in with Apple solely to reauthenticate, then deletes the account.
    private func startAppleReauthAndDelete() {
        let provider = ASAuthorizationAppleIDProvider()
        let request  = provider.createRequest()
        request.requestedScopes = []
        
        let nonce = authModel.randomNonceString()
        authModel.currentNonce = nonce
        request.nonce = authModel.sha256(nonce)
        
        // Install handler
        reauthCoordinator.onAuthorize = { result in
            switch result {
            case .failure(let err):
                botMessage = err.localizedDescription
                isRed = true
                showAppleDeleteConfirmation = false
                
            case .success(let authorization):
                authModel.deleteAppleAccount(using: authorization) { deletionResult in
                    switch deletionResult {
                    case .success():
                        viewManager.navigateToWelcome()
                        
                        if let userModel = authModel.userModel {
                            let model = UserModel(id: userModel.id, name: userModel.name, photoURL: nil, email: userModel.email, gameIDs: [])
                            localGameRepo.deleteAll(ids: userModel.gameIDs) { completed in
                                if completed {
                                    print("Deleted all local games for user")
                                }
                            }
                            
                            userRepo.saveRemote(id: authModel.currentUserIdentifier!, userModel: model) { _ in
                                authModel.setRawAppleId(nil)
                            }
                        }
                    case .failure(let err):
                        botMessage = err.localizedDescription
                        isRed = true
                    }
                    showAppleDeleteConfirmation = false
                }
            }
        }
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = reauthCoordinator
        controller.presentationContextProvider = reauthCoordinator
        controller.performRequests()
    }
    
    func googleReauthAndDelete() {
        authModel.reauthenticateWithGoogle { reauthResult in
            switch reauthResult {
            case .success(let credential):
                handleDeleteAccount(using: credential)
            case .failure(let error):
                botMessage = error.localizedDescription
                isRed = true
            }
        }
    }
    
    func emailReauthAndDelete() {
        authModel.reauthenticateWithGoogle { reauthResult in
            switch reauthResult {
            case .success(let credential):
                handleDeleteAccount(using: credential)
            case .failure(let error):
                botMessage = error.localizedDescription
                isRed = true
            }
        }
    }
    
    private func handleDeleteAccount(using credential: AuthCredential) {
        authModel.deleteAccount(credential: credential) { result in
            switch result {
            case .success:
                cleanupLocalDataAndExit()
            case .failure(let error):
                botMessage = error.localizedDescription
                isRed = true
            }
        }
    }
    
    private func cleanupLocalDataAndExit() {
        viewManager.navigateToWelcome()

        if let userModel = authModel.userModel {
            localGameRepo.deleteAll(ids: userModel.gameIDs) { completed in
                if completed {
                    print("🗑️ Deleted all local games for user")
                }
            }
            userRepo.deleteUnified(id: authModel.currentUserIdentifier!) { _, _ in }
        }
    }
}

