// AuthViewModel.swift
// MiniMate
//
// Updated to use UserModel and Game from SwiftData models

import Foundation
import FirebaseAuth
import FirebaseDatabase
import GoogleSignIn
import FirebaseCore
import SwiftData
import AuthenticationServices
import CryptoKit
import SwiftUI
import Combine

enum SignInMethod: String {
    case google
    case apple
    case email
}

/// ViewModel that manages Firebase Authentication and app-specific user data
class AuthViewModel: ObservableObject {
    /// The currently authenticated Firebase user
    @Published var firebaseUser: FirebaseAuth.User?
    @Published var userModel: UserModel?
    @Published var authAction: AuthAction?
    
    enum AuthAction {
        case deletionSuccess
        case error(String)
    }

    
    func setUserModel(_ user: UserModel) {
        self.userModel = user
    }
    
    var currentNonce: String?
    
    /// The key we use for all our DB reads/writes.
    var currentUserIdentifier: String? {
        firebaseUser?.uid
    }
    
    private let loc = LocFuncs()
    
    init() {
        self.firebaseUser = Auth.auth().currentUser
    }
    
    // MARK: - Firebase Authentication
    
    func refreshUID() {
        self.firebaseUser = Auth.auth().currentUser
    }
    
    /// Generates a random alphanumeric nonce of the given length.
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            // 16 bytes at a time
            let randoms = (0..<16).map { _ in UInt8.random(in: 0...255) }
            randoms.forEach { byte in
                if remainingLength == 0 { return }
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    func refreshVerificationStatus(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }

        user.reload { error in
            if let error = error {
                print("Reload error:", error.localizedDescription)
                completion(false)
            } else {
                completion(user.isEmailVerified)
            }
        }
    }

    
    /// Hashes input with SHA256 and returns the hex string.
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }
    
    func signInWithApple(_ authorization: ASAuthorization, context: ModelContext, completion: @escaping (Result<User, Error>, String?, String?) -> Void) {
        // 1️⃣ Extract the Apple credential + nonce
        guard
            let cred      = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce     = currentNonce,
            let tokenData = cred.identityToken,
            let idToken   = String(data: tokenData, encoding: .utf8)
        else {
            return completion(.failure(NSError(
                domain: "AuthViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid Apple credential"]
            )), nil, nil)
        }
        
        // 2️⃣ Build the OAuth credential & sign in
        let accessToken = cred.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
        let oauthCred = OAuthProvider.credential(
            providerID: .apple,
            idToken:    idToken,
            rawNonce:   nonce,
            accessToken: accessToken
        )
        
        Auth.auth().signIn(with: oauthCred) { [self] authResult, error in
            if let error = error {
                return completion(.failure(error), nil, nil)
            }
            if let result = authResult {
                DispatchQueue.main.async {
                    self.firebaseUser = result.user     // <-- REQUIRED
                }
                completion(.success(result.user), cred.fullName?.formatted(), cred.user)
            }
        }
    }
    
    /// Signs in the user using Google Sign-In and Firebase
    func signInWithGoogle(context: ModelContext, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Firebase client ID"])))
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.windows.first?.rootViewController })
            .first else {
            completion(.failure(NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to access rootViewController"])))
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { signInResult, error in
            if let error = error {
                completion(.failure(error)); return
            }
            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(.failure(NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google ID token missing"])))
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    return completion(.failure(error))
                }
                if let result = authResult {
                    DispatchQueue.main.async {
                        self.firebaseUser = result.user
                        completion(.success(result.user))
                    }
                }
            }
        }
    }
    
    /// Creates a new user with email and password
    func createUser(email: String, password: String, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error)); return
            }
            if let firebaseUser = result {
                DispatchQueue.main.async {
                    self.firebaseUser = firebaseUser.user
                    completion(.success(firebaseUser.user))
                }
                
            }
        }
    }
    
    /// Signs in an existing user with email and password
    func signIn(email: String, password: String, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error)); return
            }
            if let firebaseUser = result {
                DispatchQueue.main.async {
                    self.firebaseUser = firebaseUser.user
                    completion(.success(firebaseUser.user))
                }
                
            }
        }
    }
    
    /// Signs out the current user
    func logout() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.firebaseUser = nil
            }
        } catch {
            print("❌ Sign-out error: \(error.localizedDescription)")
        }
    }
    
    /// Deletes the user's account after reauthentication
    func deleteAccount(email: String? = nil, password: String? = nil, credential: AuthCredential? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        
        
        if let credential = credential {
            reauthDelete(credential: credential)
        } else {
            if let email = email, let password = password, !email.isEmpty && !password.isEmpty{
                let credential = EmailAuthProvider.credential(withEmail: email, password: password)
                reauthDelete(credential: credential)
            }
            
        }
        
        func reauthDelete(credential: AuthCredential){
            guard let user = Auth.auth().currentUser else {
                completion(.failure(NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No signed-in user"])))
                return
            }
            user.reauthenticate(with: credential) { _, error in
                if let error = error {
                    completion(.failure(error)); return
                }
                user.delete { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        DispatchQueue.main.async { self.firebaseUser = nil }
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    func createOrSignInUserAndNavigateToHome(context: ModelContext, authModel: AuthViewModel, viewManager: AppNavigationManaging, user: User, name: String? = nil, errorMessage: Binding<(message: String?, type: Bool)>, signInMethod: SignInMethod? = nil, appleId: String? = nil, navToHome: Bool = true, guestGame: Binding<Game?>, completion: @escaping(() -> Void)) {
        errorMessage.wrappedValue = (message: nil, type: false)
        let repo = UserRepository(context: context)
        repo.loadOrCreateUser(id: user.uid, firebaseUser: user, name: name, authModel: authModel, signInMethod: signInMethod, guestGame: guestGame.wrappedValue) { done1, done2, creation  in
            if navToHome && done1{
                Task { @MainActor in
                    completion()
                    viewManager.navigateAfterSignIn()
                }
            } else {
                completion()
            }
            if creation {
                guestGame.wrappedValue = nil
            }
        }
    }
    
    
    func signInUIManage(email: Binding<String>, password: Binding<String>, confirmPassword: Binding<String>, isTextFieldFocused: FocusState<SignInView.Field?>.Binding, authModel: AuthViewModel, errorMessage: Binding<(message: String?, type: Bool)>, showSignUp: Binding<Bool>, context: ModelContext, viewManager: ViewManager, guestGame: Binding<Game?>) {
        authModel.signIn(email: email.wrappedValue, password: password.wrappedValue) { result in
            switch result {
            case .failure(_):
                withAnimation(){
                    showSignUp.wrappedValue = true
                }
                errorMessage.wrappedValue = (message: "No User Found Please Sign Up", type: false)
            case .success(let firebaseUser):
                if firebaseUser.isEmailVerified {
                    self.createOrSignInUserAndNavigateToHome(context: context, authModel: authModel, viewManager: viewManager, user: firebaseUser, errorMessage: errorMessage, signInMethod: .email, guestGame: guestGame){}
                } else {
                    Auth.auth().currentUser?.sendEmailVerification { error in
                        DispatchQueue.main.async {
                            if let error = error {
                                errorMessage.wrappedValue = (message: "Couldn’t send verification email: \(error.localizedDescription)", type: false)
                            } else {
                                email.wrappedValue = ""
                                password.wrappedValue  = ""
                                confirmPassword.wrappedValue  = ""
                                isTextFieldFocused.wrappedValue = nil
                                errorMessage.wrappedValue = (message: "Please Verify Your Email To Continue", type: true)
                                authModel.logout() // ✅ AFTER email is sent
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Reauthenticates the current user with Apple credentials, then deletes their account.
    /// - Parameters:
    ///   - authorization: the ASAuthorization returned by your Apple reauth flow
    ///   - completion: called with success or failure once deletion is done
    func deleteAppleAccount(
        using authorization: ASAuthorization,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // 1️⃣ Extract the AppleID credential & your stored nonce
        guard let appleCred = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce     = currentNonce,
              let tokenData = appleCred.identityToken,
              let idToken   = String(data: tokenData, encoding: .utf8)
        else {
            return completion(.failure(NSError(
                domain: "AuthViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid Apple credential"]
            )))
        }
        
        // 2️⃣ Build the OAuthProvider credential (no accessToken needed here)
        let oauthCred = OAuthProvider.credential(
            providerID:   .apple,
            idToken:      idToken,
            rawNonce:     nonce,
            accessToken:  nil
        )
        
        // 3️⃣ Call your existing deleteAccount method
        deleteAccount(credential: oauthCred, completion: completion)
    }
    
    /// Reauthenticate a Google user and hand back the `AuthCredential`
    func reauthenticateWithGoogle(completion: @escaping (Result<AuthCredential, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(NSError(
                domain: "AuthViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Missing Firebase client ID"]
            )))
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.windows.first?.rootViewController })
            .first
        else {
            completion(.failure(NSError(
                domain: "AuthViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to access rootViewController"]
            )))
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { signInResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard
                let user    = signInResult?.user,
                let idToken = user.idToken?.tokenString
            else {
                completion(.failure(NSError(
                    domain: "AuthViewModel",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Google re-authentication failed"]
                )))
                return
            }
            
            // `tokenString` on `accessToken` is non-optional, so just grab it directly:
            let accessToken = user.accessToken.tokenString
            
            let credential = GoogleAuthProvider.credential(
                withIDToken:    idToken,
                accessToken:    accessToken
            )
            completion(.success(credential))
        }
    }
    
    func reauthenticateWithEmail(email: String, password: String, completion: @escaping (Result<AuthCredential, Error>) -> Void) {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)

        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "AuthViewModel", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No signed-in user"
            ])))
            return
        }

        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(credential))
            }
        }
    }
    
    func updateUserName(_ name: String) {
        userModel?.name = name
    }

}

extension String {
    func sanitizedForFirebaseID() -> String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
        return self.unicodeScalars
            .filter { allowed.contains($0) }
            .map(String.init)
            .joined()
    }
}
