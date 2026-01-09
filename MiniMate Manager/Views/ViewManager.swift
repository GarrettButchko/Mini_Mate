//
//  ViewManager.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import SwiftUI
import FirebaseAuth
import Combine

enum ViewType: Equatable {
    static func == (lhs: ViewType, rhs: ViewType) -> Bool {
        switch (lhs, rhs) {
        case (.signIn, .signIn):
            return true
        case (.welcome, .welcome):
            return true
        case (.courseList, .courseList):
            return true
        case let (.courseTab(lhsIndex), .courseTab(rhsIndex)):
            return lhsIndex == rhsIndex
        default:
            return false
        }
    }
    
    case signIn
    case welcome
    case courseList
    case courseTab(Int)
}

/// Manages app navigation state based on authentication status
@MainActor
class ViewManager: AppNavigationManaging, ObservableObject{
    
    @Published var currentView: ViewType

    init() {
        if Auth.auth().currentUser != nil && Auth.auth().currentUser!.isEmailVerified {
            self.currentView = .courseList
        } else {
            try? Auth.auth().signOut()
            self.currentView = .welcome
        }
    }

    func navigateToCourseTab(_ tab: Int) {
        currentView = .courseTab(tab)
    }
    
    func navigateToCourseList() {
        currentView = .courseList
    }
    
    func navigateToSignIn() {
        currentView = .signIn
    }

    func navigateToWelcome() {
        currentView = .welcome
    }
    
    func navigateAfterSignIn() {
        navigateToCourseList()
    }
}
