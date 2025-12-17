//
//  JoinViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/17/25.
//

import SwiftUI
import Combine

@MainActor
final class JoinViewModel: ObservableObject {

    // MARK: - Published UI State
    @Published var gameCode: String = ""
    @Published var inGame: Bool = false
    @Published var showExitAlert: Bool = false
    @Published var message: String = ""

    // MARK: - Dependencies
    let gameModel: GameViewModel
    let authModel: AuthViewModel

    // MARK: - Init
    init(
        gameModel: GameViewModel,
        authModel: AuthViewModel
    ) {
        self.gameModel = gameModel
        self.authModel = authModel
    }

    // MARK: - Actions

    func joinGame() {
        guard !gameCode.isEmpty else { return }

        gameModel.joinGame(id: gameCode) { [weak self] success in
            guard let self else { return }

            if success {
                withAnimation {
                    self.inGame = true
                }
            } else {
                self.message = "Invalid game code"
            }
        }
    }

    func leaveGame() {
        guard let userID = authModel.userModel?.id else { return }

        gameModel.leaveGame(userId: userID)
        gameCode = ""
        withAnimation {
            inGame = false
        }
    }

    // MARK: - External State Reactions

    func hostDidDismiss(showHost: Bool) {
        guard
            !showHost,
            !gameModel.gameValue.id.isEmpty,
            !gameModel.gameValue.started
        else { return }

        gameModel.leaveGame(userId: gameModel.gameValue.id)
        withAnimation {
            inGame = false
        }
    }

    func gameDidStart(_ started: Bool, onNavigate: () -> Void) {
        if started {
            onNavigate()
        }
    }

    func gameDidDismiss(_ dismissed: Bool) {
        if dismissed {
            gameCode = ""
            withAnimation {
                inGame = false
            }
        }
    }
}
