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
    
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    
    @Binding var guestGame: Game?
    
    let keyboardHeight: CGFloat
    
    @State private var errorMessage: (message: String?, type: Bool) = (nil, false)

    typealias Field = SignInView.Field
    var isTextFieldFocused: FocusState<Field?>.Binding

    private let characterLimit = 15
    
    var disabled: Bool {
        if !showSignUp {
            return email.isEmpty || password.isEmpty
        } else {
            return email.isEmpty || password.isEmpty || confirmPassword.isEmpty || password != confirmPassword
        }
    }

    var body: some View {
        ZStack{
            ScrollViewReader { proxy in
                ScrollView {
                    VStack {
                        
                        // Back Button
                        Spacer(minLength: 90)
                        // Title
                        VStack(spacing: 8) {
                            HStack {
                                Text(showSignUp ? "Sign Up" : "Login")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            HStack {
                                Text(showSignUp ? "Enter email and password" : "Enter email and password")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        Spacer(minLength: 50)
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            // Email Field
                            
                            emailSection.id(Field.email)
                            passwordSection.id(Field.password)
                            if showSignUp { confirmSection.id(Field.confirm) }
                            
                            Button {
                                if !showSignUp {
                                    authModel.signInUIManage(email: $email, password: $password, confirmPassword: $confirmPassword, isTextFieldFocused: isTextFieldFocused, authModel: authModel, errorMessage: $errorMessage, showSignUp: $showSignUp, context: context, viewManager: viewManager)
                                } else {
                                    
                                    authModel.createUser(email: email, password: password) { result in
                                        switch result {
                                        case .success(let firebaseUser):
                                            authModel.createOrSignInUserAndNavigateToHome(context: context, authModel: authModel, viewManager: viewManager, user: firebaseUser, errorMessage: $errorMessage, signInMethod: .email, navToHome: false){
                                                Auth.auth().currentUser?.sendEmailVerification { error in
                                                    DispatchQueue.main.async {
                                                        if let error = error {
                                                            errorMessage = (message: "Couldn’t send verification email: \(error.localizedDescription)", type: false)
                                                        } else {
                                                            withAnimation {
                                                                showSignUp = false
                                                                email = ""
                                                                password = ""
                                                                confirmPassword = ""
                                                                isTextFieldFocused.wrappedValue = nil
                                                                errorMessage = (message: "Please Verify Your Email To Continue", type: true)
                                                            }
                                                            authModel.logout() // ✅ AFTER email is sent
                                                        }
                                                    }
                                                }
                                            }
                                        case .failure(let error):
                                            errorMessage = (message: error.localizedDescription, type: false)
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
                            if let errorMessageText = errorMessage.message {
                                Text(errorMessageText)
                                    .foregroundColor(errorMessage.type ? .green : .red)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        ZStack{
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(.ultraThinMaterial)
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(errorMessage.type ? .green.opacity(0.2) : .red.opacity(0.2))
                                        }
                                    )
                            }
                        }
                        Spacer()
                        Spacer()
                    }
                    .padding()
                    .padding(.bottom, keyboardHeight + 20)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: keyboardHeight) { _, newHeight in
                    guard newHeight > 0, let field = isTextFieldFocused.wrappedValue else { return }
                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(field, anchor: .top)
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 35))
        }
        
        VStack{
            HStack {
                Button(action: {
                    isTextFieldFocused.wrappedValue = nil
                    withAnimation {
                        showEmail = false
                        showSignUp = false
                        email = ""
                        password = ""
                        confirmPassword = ""
                        errorMessage.message = nil
                    }
                    
                    #if MANAGER
                    height = 210
                    #endif
                    
                    #if MINIMATE
                    if guestGame != nil {
                        height = 360
                    } else {
                        height = 255
                    }
                    #endif
                    
                }) {
                    Circle()
                        .ifAvailableGlassEffect()
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
        }
        .padding()
    }
    
    var emailSection: some View {
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
                    .focused(isTextFieldFocused, equals: .email)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial))
        }
    }
    
    var passwordSection: some View {
        passwordField(title: "Password", text: $password, equals: .password)
    }
    
    var confirmSection: some View {
        passwordField(title: "Confirm Password", text: $confirmPassword, equals: .confirm)
    }

    // MARK: - Helpers

    private func passwordField(title: String, text: Binding<String>, image: String = "lock", equals: Field) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundColor(.secondary)
            HStack {
                Image(systemName: image)
                    .foregroundColor(.secondary)
                SecureField("••••••", text: text)
                    .focused(isTextFieldFocused, equals: equals)
                    .onChange(of: text.wrappedValue) { _ , newValue in
                        if newValue.count > characterLimit {
                            text.wrappedValue = String(newValue.prefix(characterLimit))
                        }
                    }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial))
        }
    }
}


