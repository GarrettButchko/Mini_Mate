// JoinView.swift
// MiniMate
//
// Refactored to use SwiftData models and AuthViewModel

import SwiftUI

struct JoinView: View {
    @Environment(\.modelContext) private var context
    
    @EnvironmentObject var viewManager: ViewManager
    
    @Binding var showHost: Bool
    @State private var showScanner = false
    
    @StateObject private var viewModel: JoinViewModel
    
    init(
        authModel: AuthViewModel,
        viewManager: ViewManager,
        gameModel: GameViewModel,
        showHost: Binding<Bool>
    ) {
        self._showHost = showHost
        _viewModel = StateObject(
            wrappedValue: JoinViewModel(
                gameModel: gameModel,
                authModel: authModel
            )
        )
    }
    
    var body: some View {
        ZStack{
            
            mainContent
                .contentMargins(.top, 100)
                .contentMargins(.bottom, 70)
            
            VStack {
                HStack {
                    Spacer()
                    Text("Join Game")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .padding(.top, 20)
                    
                    Spacer()
                }
                .padding(.bottom)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.bg.opacity(1),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .top)
                )
                
                Spacer()
                
                Group{
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
                            .safeAreaPadding(.bottom, 10)
                            
                        }
                        .disabled(viewModel.gameCode.isEmpty)
                    }
                }
                .padding(.top)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.bg.opacity(1),
                            Color.clear
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .ignoresSafeArea(edges: .bottom)
                )
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
        .background(.bg)
    }
    
    // MARK: - Sections
    private var mainContent: some View {
        Group {
            if !viewModel.inGame {
                joinGameCard
            } else {
                activeGameLobby
            }
        }
    }

    // MARK: - Join Game View
    @ViewBuilder
    private var joinGameCard: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Enter Game Code")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("Ask the host for the 6-digit code")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Input & Scanner
                VStack(spacing: 20) {
                    gameCodeTextField
                    actionDivider
                    scanButton
                }
                
                if !viewModel.message.isEmpty {
                    Text(viewModel.message)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.8))
                        .transition(.blurReplace)
                }
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .background {
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(.sub)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
            }
            .padding(.horizontal, 20)
            .padding(.top, 25)
            
            Spacer()
        }
    }

    // MARK: - Sub-Components
    private var gameCodeTextField: some View {
        TextField("000000", text: $viewModel.gameCode)
            .font(.system(size: 34, weight: .bold, design: .monospaced))
            .multilineTextAlignment(.center)
            .keyboardType(.asciiCapable)
            .textInputAutocapitalization(.characters)
            .disableAutocorrection(true)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 1, opacity: 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .frame(width: 240)
            .onChange(of: viewModel.gameCode) { _, newValue in
                let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                viewModel.gameCode = String(filtered.prefix(6))
            }
    }

    private var actionDivider: some View {
        HStack {
            Rectangle().fill(.separator).frame(height: 1)
            Text("OR").font(.caption2).fontWeight(.black).foregroundStyle(.tertiary)
            Rectangle().fill(.separator).frame(height: 1)
        }
        .padding(.horizontal, 40)
    }

    private var scanButton: some View {
        Button {
            showScanner = true
        } label: {
            Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Capsule().fill(.ultraThinMaterial))
        }
        .sheet(isPresented: $showScanner) {
            camView // This contains your ZStack with QRScannerView and the Overlay
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Active Game Lobby
    @ViewBuilder
    private var activeGameLobby: some View {
        Form {
            playersSection
            
            Section(header: Text("Game Info")) {
                infoRow(title: "Code:", value: viewModel.gameModel.gameValue.id)
                infoRow(title: "Date:", value: viewModel.gameModel.gameValue.date.formatted(date: .abbreviated, time: .shortened))
                infoRow(title: "Holes:", value: "\(viewModel.gameModel.gameValue.numberOfHoles)")
                infoRow(title: "Location:", value: viewModel.gameModel.gameValue.locationName ?? "No Location")
            }
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
    
    
    private var camView: some View {
        ZStack {
            QRScannerView { scannedCode in
                let formattedCode = scannedCode
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased()
                
                DispatchQueue.main.async {
                    viewModel.gameCode = formattedCode
                    withAnimation {
                        showScanner = false
                    }
                }
            }
            .ignoresSafeArea()
            
            // 1. The Mask (Centered on screen)
            Color.black.opacity(0.6)
                .mask {
                    // 1. A solid canvas that covers the whole screen
                    Rectangle()
                        .overlay(
                            // 2. The "hole" that gets cut out of that canvas
                            RoundedRectangle(cornerRadius: 30)
                                .frame(width: 260, height: 260)
                                .blendMode(.destinationOut)
                        )
                }
                .overlay{
                    // 2. The Corners (Layered separately to ensure perfect centering)
                    ScannerCornerShape()
                        .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                        .frame(width: 260, height: 260)
                }
                .ignoresSafeArea()
            
            // 3. The UI Text and Buttons (Purely for positioning labels)
            VStack {
                VStack(spacing: 8) {
                    Text("Scan QR Code")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("Center the code inside the frame")
                        .font(.subheadline)
                }
                .padding(.top, 60)
                .foregroundStyle(.white)
                
                Spacer() // Pushes text to top and button to bottom
                
                Button {
                    showScanner = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.bottom, 40)
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
                            .frame(width: 40, height: 40)
                        Text("Waiting...").font(.caption)
                    }.padding(.horizontal)
                }
            }
            .frame(height: 75)
        }
    }
}
