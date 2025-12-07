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
    
    @State var showEmailSignIn: Bool = false
    @State var errorMessage: String? = ""
    @State var height: CGFloat = 0
    
    @State private var email = ""
    @State private var password = ""
    
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme)  var colorScheme
    
    @ObservedObject var authModel : AuthViewModel
    @ObservedObject var viewManager : ViewManager

    @FocusState private var isTextFieldFocused: Bool

    private let characterLimit = 15
    
    
    var body: some View {
        GeometryReader{ geometry in
            ZStack {
                Rectangle()
                    .foregroundStyle(Gradient(colors: [.blue, .green]))
                    .ignoresSafeArea()
                VStack{
                    HStack{
                        VStack(alignment: .leading){
                            Text("Welcome to,")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .colorScheme(.dark)
                                
                            Text("Mini Mate")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .colorScheme(.dark)
                                
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
                            // Ensure EmailPasswordView initializer accepts 'height: Binding<CGFloat>' and 'geometry: GeometryProxy' parameters.
                            EmailPasswordView(viewManager: viewManager, authModel: authModel, showEmail: $showEmailSignIn, height: $height, geometry: geometry)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .clipped()
                    .frame(height: height)
                    .frame(maxWidth: 430)
                    .animation(.bouncy.speed(1.5), value: height)
                    .padding()
                    .padding(.bottom)
                    
                    
                }
            }
            .onAppear {
                //withAnimation{
                    height = 220
                //}
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
    
    var authModel: AuthViewModel
    var viewManager: ViewManager
    
    var geometry: GeometryProxy
    
    var body: some View {
        VStack(){
            // Email / Password Button
            Button {
                withAnimation {
                    showEmailSignIn = true
                    height = geometry.size.height * 0.8
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .foregroundStyle(.green)
                    Text("Email / Password")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .font(.system(size: 18))
                }
            }
            .frame(height: 50)

            Spacer()
            Button {
                authModel.signInWithGoogle(context: context) { result in
                    switch result {
                    case .success(let firebaseUser):
                        authModel.createOrSignInUserAndNavigateToHome(context: context, authModel: authModel, viewManager: viewManager, user: firebaseUser, errorMessage: $errorMessage)
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
                    authModel.signInWithApple(authorization, context: context) { signInResult, name in
                        switch signInResult {
                        case .failure(let err):
                            errorMessage = err.localizedDescription
                        case .success(let firebaseUser):
                            authModel.createOrSignInUserAndNavigateToHome(context: context, authModel: authModel, viewManager: viewManager, user: firebaseUser, errorMessage: $errorMessage)
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


