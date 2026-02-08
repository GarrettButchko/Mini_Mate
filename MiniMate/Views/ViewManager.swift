//
//  ViewManager.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import SwiftUI
import FirebaseAuth

enum ViewType {
    case main(Int)
    case welcome
    case scoreCard(Bool)
    case ad(Bool)
    case signIn
    case host
}

/// Manages app navigation state based on authentication status
@MainActor
class ViewManager: AppNavigationManaging, ObservableObject{
    
    @Published var currentView: ViewType

    init() {
        if Auth.auth().currentUser != nil && Auth.auth().currentUser!.isEmailVerified {
            self.currentView = .main(1)
        } else {
            try? Auth.auth().signOut()
            self.currentView = .welcome
        }
    }

    func navigateToMain(_ tab: Int) {
        currentView = .main(tab)
    }
    
    func navigateToSignIn() {
        currentView = .signIn
    }

    func navigateToWelcome() {
        currentView = .welcome
    }
    
    func navigateToScoreCard(_ isGuest: Bool = false) {
        currentView = .scoreCard(isGuest)
    }
    
    func navigateToAd(_ isGuest: Bool = false) {
        currentView = .ad(isGuest)
    }
    
    func navigateAfterSignIn() {
        navigateToMain(1)
    }
    
    func navigateToHost() {
        currentView = .host
    }
}

extension ViewType: Equatable {
    static func == (lhs: ViewType, rhs: ViewType) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main),
             (.welcome, .welcome),
            (.scoreCard, .scoreCard),
            (.ad, .ad),
            (.signIn, .signIn),
            (.host, .host):
            return true
        default:
            return false
        }
    }
}
