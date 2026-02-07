// JoinView.swift
// MiniMate
//
// Refactored to use SwiftData models and AuthViewModel

import SwiftUI

struct JoinView: View {
    @Environment(\.modelContext) private var context
    
    @ObservedObject var viewManager: ViewManager
    
    @Binding var showHost: Bool
    
    @StateObject private var viewModel: JoinViewModel
    
    init(
        authModel: AuthViewModel,
        viewManager: ViewManager,
        gameModel: GameViewModel,
        showHost: Binding<Bool>
    ) {
        self._showHost = showHost
        self.viewManager = viewManager
        _viewModel = StateObject(
            wrappedValue: JoinViewModel(
                gameModel: gameModel,
                authModel: authModel
            )
        )
    }
    
    var body: some View {
        VStack {
            Capsule()
                .frame(width: 38, height: 6)
                .foregroundColor(.gray)
                .padding(10)
            
            HStack {
                Text("Join Game")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.leading, 30)
                Spacer()
            }
            .padding(.bottom, 10)
            
            Form {
                gameInfoSection
                if viewModel.inGame {
                    playersSection
                }
            }
            if viewModel.inGame {
                Button {
                    viewModel.showExitAlert = true
                } label: {
                    Text("Exit Game")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.red)
                                .padding(.horizontal)
                        )
                }
                .foregroundColor(.red)
                .alert("Exit Game?", isPresented: $viewModel.showExitAlert) {
                    Button("Leave", role: .destructive) {
                        viewModel.leaveGame()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } else {
                Button {
                    viewModel.joinGame()
                } label: {
                    HStack(alignment: .center){
                        Image(systemName: "person.2.badge.plus.fill")
                        Text("Join Game")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.blue.opacity(viewModel.gameCode.isEmpty ? 0.5 : 1))
                    )
                    .padding(.horizontal)
                    .opacity(viewModel.gameCode.isEmpty ? 0.5 : 1)
                    
                }
                .disabled(viewModel.gameCode.isEmpty)
            }
        }
        .onChange(of: showHost) { oldValue, newValue in
            viewModel.hostDidDismiss(showHost: showHost)
        }
        .onChange(of: viewModel.gameModel.gameValue.started) {
            viewModel.gameDidStart($1) {
                viewManager.navigateToScoreCard()
            }
        }
        .onChange(of: viewModel.gameModel.gameValue.dismissed) {
            viewModel.gameDidDismiss($1)
        }
    }

    // MARK: - Sections

    private var gameInfoSection: some View {
        Section(header: Text("Game Info")) {
            if !viewModel.inGame {
                HStack {
                    Text("Enter Code:")
                    Spacer()
                    TextField("Game Code", text: $viewModel.gameCode)
                        .frame(width: 150)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                        )
                    if viewModel.message != "" {
                        Text("Error: " + viewModel.message)
                    }
                    
                }
            } else {
                HStack {
                    Text("Code:")
                    Spacer()
                    Text(viewModel.gameModel.gameValue.id)
                }
                HStack {
                    Text("Date:")
                    Spacer()
                    Text(viewModel.gameModel.gameValue.date.formatted(date: .abbreviated, time: .shortened))
                }
                HStack {
                    Text("Holes:")
                    Spacer()
                    Text("\(viewModel.gameModel.gameValue.numberOfHoles)")
                }
            }
        }
    }

    private var playersSection: some View {
        Section(header: Text("Players: \(viewModel.gameModel.gameValue.players.count)")) {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(viewModel.gameModel.gameValue.players) { player in
                        PlayerIconView(player: player, isRemovable: false) {}
                    }
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Waiting...").font(.caption)
                    }
                    .padding(.horizontal)
                }
            }
            .frame(height: 75)
        }
    }
}
