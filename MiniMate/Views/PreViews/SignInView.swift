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
import MarqueeText

struct SignInView: View {
    enum Field: Hashable { case email, password, confirm }
    
    @State var showEmailSignIn: Bool = false
    @State var errorMessage: (message: String?, type: Bool) = (nil, false)
    @State var height: CGFloat = 0
    
    @State var email = ""
    @State var password = ""
    @State var confirmPassword = ""
    
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme)  var colorScheme
    
    @ObservedObject var authModel : AuthViewModel
    @ObservedObject var viewManager : ViewManager
    
    @State var guestGame: Game? = nil

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
                VStack(spacing: 10){
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
                    
                    
                    
                    ZStack{
                        RoundedRectangle(cornerRadius: 35)
                            .foregroundStyle(.ultraThinMaterial)
                            
                        
                        if !showEmailSignIn {
                            
                            VStack{
                                
                                
                                StartButtons(
                                    showEmailSignIn: $showEmailSignIn,
                                    height: $height,
                                    errorMessage: $errorMessage,
                                    guestGame: $guestGame, authModel: authModel,
                                    viewManager: viewManager,
                                    geometry: geometry
                                )
                            }
                            .padding()
                            
                        } else {
                            EmailPasswordView(viewManager: viewManager, authModel: authModel, showEmail: $showEmailSignIn, height: $height, geometry: geometry, email: $email, password: $password, confirmPassword: $confirmPassword, guestGame: $guestGame, keyboardHeight: keyboard.height, isTextFieldFocused: $isTextFieldFocused)
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
                
                authModel.firebaseUser = nil
                
                
            }
        }
    }
}

struct StartButtons: View {
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme) var colorScheme
    #if MINIMATE
    @EnvironmentObject var gameModel: GameViewModel
    #endif
    
    @Binding var showEmailSignIn: Bool
    @Binding var height: CGFloat
    @Binding var errorMessage: (message: String?, type: Bool)
    
    @State var showGuestAlert: Bool = false
    @State var guestName: String = ""
    @State var guestEmail: String = ""
    
    @Binding var guestGame: Game?
    
    var authModel: AuthViewModel
    var viewManager: ViewManager
    
    var geometry: GeometryProxy
    
    var body: some View {
        VStack(){
            // Email / Password Button
            #if MINIMATE
            
            if let guestGame = guestGame {
                
                HStack{
                    VStack(alignment: .leading, spacing: 6) {
                        
                        Text("Save Guest-Play Game?")
                            .font(.headline)
                            .foregroundStyle(.mainOpp)
                        
                        Text("Sign in to save it to your profile.")
                            .font(.subheadline)
                            .foregroundStyle(.mainOpp.opacity(0.6))
                        
                        Text("Game played on: \(guestGame.date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.mainOpp.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 22)
                .background{
                    RoundedRectangle(cornerRadius: 25)
                        .foregroundStyle(.ultraThinMaterial)
                }
            }
            
            
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
                    gameModel.createGame(guestData: GuestData(id: "guest-\(UUID().uuidString.prefix(6))", email: guestEmail == "" ? nil : guestEmail, name: guestName))
                    viewManager.navigateToHost()
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
            .onAppear{
                
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
                        authModel.createOrSignInUserAndNavigateToHome(context: context, authModel: authModel, viewManager: viewManager, user: firebaseUser, errorMessage: $errorMessage, signInMethod: .google, guestGame: $guestGame){}
                    case .failure(let error):
                        errorMessage = (message: error.localizedDescription, type: false)
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
                    errorMessage = (message: err.localizedDescription, type: false)
                case .success(let authorization):
                    authModel.signInWithApple(authorization, context: context) { signInResult, name, appleId in
                        switch signInResult {
                        case .failure(let err):
                            errorMessage = (message: err.localizedDescription, type: false)
                        case .success(let firebaseUser):
                            authModel.createOrSignInUserAndNavigateToHome(context: context, authModel: authModel, viewManager: viewManager, user: firebaseUser, name: name, errorMessage: $errorMessage, signInMethod: .apple, appleId: appleId, guestGame: $guestGame){}
                        }
                    }
                }
            }
            .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
            .frame(height: 50)
            .cornerRadius(25)
        }
        .onAppear(){
            withAnimation{
                #if MANAGER
                height = 210
                #endif
                
                #if MINIMATE
                LocalGameRepository(context: context).fetchGuestGame { game in
                    guestGame = game
                    if guestGame != nil {
                        height = 360
                    } else {
                        height = 255
                    }
                }
                #endif
            }
        }
    }
}


