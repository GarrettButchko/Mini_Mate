//
//  ViewManager.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import SwiftUI
import FirebaseAuth
import Combine

enum ViewType {
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
        if Auth.auth().currentUser != nil {
            self.currentView = .courseList
        } else {
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
