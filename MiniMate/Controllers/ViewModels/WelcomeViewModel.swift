//
//  WelcomeViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/6/25.
//

import SwiftUI
import Combine

@MainActor
final class WelcomeViewModel: ObservableObject {

    // MARK: - Published UI State
    @Published var displayedText = ""
    @Published var showLoading = false

    // MARK: - Private
    private let fullText = "Welcome to MiniMate"
    private let typingSpeed = 0.05
    private var animationTriggered = false

    private let viewManager: ViewManager

    // MARK: - Init
    init(viewManager: ViewManager) {
        self.viewManager = viewManager
    }

    // MARK: - Lifecycle
    func onAppear() {
        startTypingAnimation()
    }

    // MARK: - Typing Animation
    private func startTypingAnimation() {
        displayedText = ""
        animationTriggered = false

        for (index, character) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + typingSpeed * Double(index)) {
                self.displayedText.append(character)

                if self.displayedText == self.fullText, !self.animationTriggered {
                    self.animationTriggered = true
                    self.handleCompletion()
                }
            }
        }
    }

    // MARK: - Post Animation Logic
    private func handleCompletion() {
        if NetworkChecker.shared.isConnected {
            navigateToSignIn()
        } else {
            showLoading = true
            pollUntilInternet()
        }
    }

    // MARK: - Network Polling
    private func pollUntilInternet() {
        if NetworkChecker.shared.isConnected {
            navigateToSignIn()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.pollUntilInternet()
            }
        }
    }

    // MARK: - Navigation
    private func navigateToSignIn() {
        withAnimation {
            viewManager.navigateToSignIn()
        }
    }
}

