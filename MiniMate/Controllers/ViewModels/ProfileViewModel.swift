//
//  ProfileViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/17/25.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import SwiftUI



@MainActor
final class ProfileViewModel: ObservableObject {
    
    // MARK: - Published UI State
    @Published var editProfile = false
    @Published var botMessage = ""
    @Published var isRed = true
    @Published var showAppleDeleteConfirmation: Bool = false
    @Published var name = ""
    @Published var email = ""
    @Published var activeDeleteAlert: DeleteAlertType?
    var oldEmail: String? = nil
    
    // MARK: - Dependencies
    private let authModel: AuthViewModel
    private let userRepo: UserRepository
    private let localGameRepo: LocalGameRepository
    private let remoteGameRepo: FirestoreGameRepository
    private let viewManager: ViewManager
    
    let reauthCoordinator = AppleReauthCoordinator { _ in }
    
    // MARK: - Init
    init(
        authModel: AuthViewModel,
        userRepo: UserRepository,
        localGameRepo: LocalGameRepository,
        remoteGameRepo: FirestoreGameRepository,
        viewManager: ViewManager,
        isSheetPresent: Binding<Bool>
    ) {
        self.authModel = authModel
        self.userRepo = userRepo
        self.localGameRepo = localGameRepo
        self.remoteGameRepo = remoteGameRepo
        self.viewManager = viewManager
    }
    
    func startAppleReauthAndDelete() {
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
                self.botMessage = err.localizedDescription
                self.isRed = true
                self.showAppleDeleteConfirmation = false
                
            case .success(let authorization):
                self.authModel.deleteAppleAccount(using: authorization) { deletionResult in
                    switch deletionResult {
                    case .success():
                        self.viewManager.navigateToWelcome()
                        
                        if let userModel = self.authModel.userModel {
                            let model = UserModel(id: userModel.id, name: userModel.name, photoURL: nil, email: userModel.email, gameIDs: [])
                            self.localGameRepo.deleteAll(ids: userModel.gameIDs) { completed in
                                if completed {
                                    print("Deleted all local games for user")
                                }
                            }
                            
                            self.userRepo.saveRemote(id: self.authModel.currentUserIdentifier!, userModel: model) { _ in
                                self.authModel.setRawAppleId(nil)
                            }
                        }
                    case .failure(let err):
                        self.botMessage = err.localizedDescription
                        self.isRed = true
                    }
                    self.showAppleDeleteConfirmation = false
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
                self.handleDeleteAccount(using: credential)
            case .failure(let error):
                self.botMessage = error.localizedDescription
                self.isRed = true
            }
        }
    }
    
    func emailReauthAndDelete(email: String, password: String) {
        authModel.reauthenticateWithEmail(email: email, password: password){ reauthResult in
            switch reauthResult {
            case .success(let credential):
                self.handleDeleteAccount(using: credential)
            case .failure(let error):
                self.botMessage = error.localizedDescription
                self.isRed = true
            }
        }
    }
    
    private func handleDeleteAccount(using credential: AuthCredential) {
        authModel.deleteAccount(credential: credential) { result in
            switch result {
            case .success:
                self.cleanupLocalDataAndExit()
            case .failure(let error):
                self.botMessage = error.localizedDescription
                self.isRed = true
            }
        }
    }
    
    private func cleanupLocalDataAndExit() {
        guard let userModel = authModel.userModel else { return }

        // ✅ Snapshot ALL value types BEFORE navigation
        let gameIDs = userModel.gameIDs
        let userID  = userModel.id

        // Now it's safe to leave the context
        viewManager.navigateToWelcome()
        
        findGameIdsToDelete(allGameIds: gameIDs) { ids in
            self.remoteGameRepo.deleteAll(ids: ids) { completed in }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.localGameRepo.deleteAll(ids: gameIDs) { completed in
                if completed {
                    print("🗑️ Deleted all local games for user")
                }
            }

            self.userRepo.deleteUnified(id: userID)
        }
    }
    
    private func findGameIdsToDelete(
        allGameIds: [String],
        completion: @escaping ([String]) -> Void
    ) {
        var gameIdsToDelete: [String] = []

        remoteGameRepo.fetchAll(withIDs: allGameIds) { games in
            let group = DispatchGroup()

            for game in games {
                group.enter()
                let playerIds = game.players.map(\.userId)

                self.userRepo.countExistingUsers(ids: playerIds) { count in
                    if count == 1 {
                        gameIdsToDelete.append(game.id)
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion(gameIdsToDelete)
            }
        }
    }
    
    


    
    func managePictureChange(newImage: UIImage?) {
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
    
    func manageProfileEditting(user: UserModel) {
        if editProfile {
            if let oldEmail = oldEmail, oldEmail != name {
                authModel.updateUserName(name)
                userRepo.saveRemote(id: authModel.currentUserIdentifier!, userModel: authModel.userModel!) { _ in }
            }

            editProfile = false
        } else {
            oldEmail = user.name
            name = user.name
            editProfile = true
        }
    }
    
    func passwordReset(user: UserModel) {
        let targetEmail = user.email ?? "No email"
        print("Sent email to: \(targetEmail)")
        Auth.auth().sendPasswordReset(withEmail: targetEmail) { error in
            if let error = error {
                self.botMessage = error.localizedDescription
                self.isRed = true
            } else {
                self.botMessage = "Password reset email sent!"
                self.isRed = false
            }
        }
    }
    
    func logOut() {
        withAnimation {
            viewManager.navigateToWelcome()
        }
        authModel.logout()
    }
    
    func deleteAccount() {
        if authModel.signInMethod == .google {
            activeDeleteAlert = .google
        } else if authModel.signInMethod == .apple {
            activeDeleteAlert = .apple
        } else {
            activeDeleteAlert = .email
        }
    }
}
