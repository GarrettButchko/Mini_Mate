//
//  ContentView.swift
//  Sacred Truth
//
//  Created by Garrett Butchko on 5/28/25.
//

import SwiftUI
import _AuthenticationServices_SwiftUI
import FirebaseAuth
import SwiftData

struct SignInView: View {
    enum Field: Hashable { case email, password, confirm }
    
    @State var showEmailSignIn: Bool = false
    @State var errorMessage: String? = ""
    @State var height: CGFloat = 0
    
    @State var email = ""
    @State var password = ""
    @State var confirmPassword = ""
    
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme)  var colorScheme
    
    @ObservedObject var authModel : AuthViewModel
    @ObservedObject var viewManager : ViewManager

    @StateObject private var keyboard = KeyboardObserver()
    @FocusState private var isTextFieldFocused: Field?
    
    var gradientColors: [Color] = [.blue, .green]

    private let characterLimit = 15
    
    var body: some View {
        GeometryReader{ geometry in
            ZStack {
                Rectangle()
                    .foregroundStyle(Gradient(colors: gradientColors))
                    .ignoresSafeArea()
                VStack{
                    HStack(alignment: .top){
                        VStack(alignment: .leading){
                            Text("Welcome to,")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .colorScheme(.dark)
                                
                            Text("Mini Mate")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .colorScheme(.dark)
                            
                            #if MANAGER
                            Text("Manager")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .colorScheme(.dark)
                            #endif
                        }
                        
                        Spacer()
                        
                        Image("logoOpp")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .colorScheme(.dark)
                    }
                    .padding(.horizontal)
                    
                    
                    Spacer()
                    
                   // Text(errorMessage ?? "")
                    
                    Spacer()
                    
                    ZStack{
                        RoundedRectangle(cornerRadius: 35)
                            .foregroundStyle(.ultraThinMaterial)
                            
                        
                        if !showEmailSignIn {
                            StartButtons(
                                showEmailSignIn: $showEmailSignIn,
                                height: $height,
                                errorMessage: $errorMessage,
                                authModel: authModel,
                                viewManager: viewManager,
                                geometry: geometry
                            )
                            .padding()
                            
                        } else {
                            EmailPasswordView(viewManager: viewManager, authModel: authModel, showEmail: $showEmailSignIn, height: $height, geometry: geometry, email: $email, password: $password, confirmPassword: $confirmPassword, keyboardHeight: keyboard.height, isTextFieldFocused: $isTextFieldFocused)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 35))
                    .frame(height: height)
                    .frame(maxWidth: 430)
                    .animation(.bouncy.speed(1.5), value: height)
                    .padding()
                    .padding(.bottom)
                }
            }
            .onAppear {
                withAnimation{
                    height = 220
                }
                authModel.firebaseUser = nil
            }
        }
    }
}

struct StartButtons: View {
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var showEmailSignIn: Bool
    @Binding var height: CGFloat
    @Binding var errorMessage: String?
    
    @State var showGuestAlert: Bool = false
    @State var guestName: String = ""
    @State var guestEmail: String = ""
    
    var authModel: AuthViewModel
    var viewManager: ViewManager
    
    var geometry: GeometryProxy
    
    var body: some View {
        VStack(){
            // Email / Password Button
            #if MINIMATE
            Button {
                withAnimation {
                    showGuestAlert = true
                }
            } label: {
                HStack{
                    Image(systemName: "play.fill")
                    Text("Guest Play")
                }
                .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.ultraThinMaterial)
                )
            
            }
            .buttonStyle(.plain)
            .alert("Welcome To MiniMate!", isPresented: $showGuestAlert) {
                
                TextField("Name", text: $guestName)
                    .characterLimit($guestName, maxLength: 18)
                
                
                TextField("Email (Optional)", text: $guestEmail)
                    .autocapitalization(.none)   // starts lowercase / no auto-cap
                    .keyboardType(.emailAddress)
                
                    
                Button("Play") {
                    let gameView = GameViewModel(game: Game(), authModel: authModel, course: nil)
                    
                    gameView.createGame(guestData: GuestData(id: "guest-\(UUID().uuidString.prefix(6))", email: guestEmail == "" ? nil : guestEmail, name: guestName))
                    
                    viewManager.navigateToHost(gameViewModel: gameView)
                }
                .disabled(
                    guestName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    ProfanityFilter.containsBlockedWord(guestName) ||
                    (
                        !guestEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                        !guestEmail.isValidEmail
                    )
                )
                .tint(.blue)
                
                Button("Cancel", role: .cancel) {
                    guestName = ""
                    guestEmail = ""
                }
            } message: {
                Text("Name is required. Email is optional — used only for course analytics.")
            }
            #endif
            
            Button {
                withAnimation {
                    showEmailSignIn = true
                    height = geometry.size.height * 0.8
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .foregroundStyle(.green)
                    
                    HStack{
                        Image(systemName: "envelope.fill")
                        Text("Sign in with Email")
                    }
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                }
            }
            .frame(height: 50)

            Spacer()
            Button {
                authModel.signInWithGoogle(context: context) { result in
                    switch result {
                    case .success(let firebaseUser):
                        authModel.createOrSignInUserAndNavigateToHome(context: context, authModel: authModel, viewManager: viewManager, user: firebaseUser, errorMessage: $errorMessage, signInMethod: .google){}
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                  }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .frame(height: 50)
                        .foregroundStyle(.blue)
                    HStack{
                        Image("google")
                            .resizable()
                            .frame(width: 23, height: 22)
                            .background(Color.white)
                            .clipShape(Circle())
                        Text("Sign in with Google")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            Spacer()
            SignInWithAppleButton { request in
                authModel.handleSignInWithAppleRequest(request)
            } onCompletion: { result in
                switch result {
                case .failure(let err):
                    errorMessage = err.localizedDescription
                case .success(let authorization):
                    authModel.signInWithApple(authorization, context: context) { signInResult, name, appleId in
                        switch signInResult {
                        case .failure(let err):
                            errorMessage = err.localizedDescription
                        case .success(let firebaseUser):
                            authModel.createOrSignInUserAndNavigateToHome(context: context, authModel: authModel, viewManager: viewManager, user: firebaseUser, name: name, errorMessage: $errorMessage, signInMethod: .apple, appleId: appleId){}
                        }
                    }
                }
            }
            .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
            .frame(height: 50)
            .cornerRadius(25)
        }
    }
}


