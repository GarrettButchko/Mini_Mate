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
    case scoreCard
    case gameReview(Game)
    case ad
    case signIn
    case host(GameViewModel)
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
    
    func navigateToScoreCard() {
        currentView = .scoreCard
    }
    
    func navigateToAd() {
        currentView = .ad
    }
    
    func navigateToGameReview(_ gameModel: Game) {
        currentView = .gameReview(gameModel)
    }
    
    func navigateAfterSignIn() {
        navigateToMain(1)
    }
    
    func navigateToHost(gameViewModel: GameViewModel) {
        currentView = .host(gameViewModel)
    }
}

extension ViewType: Equatable {
    static func == (lhs: ViewType, rhs: ViewType) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main),
             (.welcome, .welcome),
            (.scoreCard, .scoreCard),
            (.gameReview, .gameReview),
            (.ad, .ad),
            (.signIn, .signIn),
            (.host, .host):
            return true
        default:
            return false
        }
    }
}
