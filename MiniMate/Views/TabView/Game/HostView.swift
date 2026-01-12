// HostView.swift
// MiniMate
//
// Refactored to use new SwiftData models and AuthViewModel

import SwiftUI
import MapKit

struct HostView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var gameModel: GameViewModel
    
    @Binding var showHost: Bool
    @State var showTextAndButtons = false
    @State var showAddPlayerAlert = false
    @State var showDeleteAlert = false
    @State var newPlayerName = ""
    @State var newPlayerEmail = ""
    @State var isRotating = false
    
    @ObservedObject var authModel: AuthViewModel
    @ObservedObject var viewManager: ViewManager
    @ObservedObject var locationHandler: LocationHandler
    @StateObject var viewModel: HostViewModel
    
    var isGuest: Bool
    
    init(
            showHost: Binding<Bool>,
            authModel: AuthViewModel,
            viewManager: ViewManager,
            locationHandler: LocationHandler,
            isGuest: Bool = false
        ) {
            self._showHost = showHost
            self.authModel = authModel
            self.viewManager = viewManager
            self.locationHandler = locationHandler
            self.isGuest = isGuest
            
            // Correct way to initialize a StateObject with dependencies
            _viewModel = StateObject(wrappedValue: HostViewModel(handler: locationHandler))
        }
    
    var body: some View {
        mainContent
    }
    
    private var mainContent: some View {
        VStack {
            if !isGuest {
                Capsule()
                    .frame(width: 38, height: 6)
                    .foregroundColor(.gray)
                    .padding(10)
            }
            
            HStack(spacing: 10){
                
                if isGuest {
                    Button {
                        viewManager.navigateToSignIn()
                    } label: {
                        ZStack{
                            Circle()
                                .fill(.blue)
                            Image(systemName: "chevron.left")
                                .foregroundStyle(.white)
                        }
                        .frame(width: 35, height: 35)
                    }
                }
                
                Text(gameModel.isOnline ? "Hosting Game" : "Game Setup")
                    .font(.title)
                    .fontWeight(.bold)
                    
                Spacer()
            }
            .padding(.leading, 20)
            
            Form {
                gameInfoSection
                playersSection
            }
            startGameSection
            
            if isGuest {
                Color.clear
                    .frame(width: 20, height: 30)
            }
        }
        .onChange(of: showHost) { _, newValue in
            if !newValue && !gameModel.started {
                gameModel.dismissGame()
            }
        }
        .alert("Add Local Player?", isPresented: $showAddPlayerAlert) {
            
            TextField("Name", text: $newPlayerName)
                .characterLimit($newPlayerName, maxLength: 18)
            
            if gameModel.getCourse() != nil {
                TextField("Email", text: $newPlayerEmail)
                    .autocapitalization(.none)   // starts lowercase / no auto-cap
                    .keyboardType(.emailAddress)
            }
                
            Button("Add") {
                viewModel.addPlayer(newPlayerName: $newPlayerName, newPlayerEmail: $newPlayerEmail, gameModel: gameModel)
            }
            .disabled(
                gameModel.getCourse() != nil
                ?
                newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                newPlayerEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                ProfanityFilter.containsBlockedWord(newPlayerName) ||
                !newPlayerEmail.isValidEmail
                :
                newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                ProfanityFilter.containsBlockedWord(newPlayerName)
            )
            .tint(.blue)
            
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Player?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let player = viewModel.playerToDelete {
                    gameModel.removePlayer(userId: player)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onReceive(viewModel.timer) { _ in
            viewModel.tick(showHost: $showHost, gameModel: gameModel)
        }
    }
    
    // MARK: - Sections
    private var gameInfoSection: some View {
        Group {
            Section {
                if gameModel.isOnline {
                    HStack {
                        Text("Game Code:")
                        Spacer()
                        Text(gameModel.gameValue.id)
                    }
                    
                    HStack {
                        Text("Expires in:")
                        Spacer()
                        Text(viewModel.timeString(from: Int(viewModel.timeRemaining)))
                            .monospacedDigit()
                    }
                }
                
                DatePicker("Date & Time", selection: gameModel.binding(for: \.date))
                    .onChange(of: locationHandler.selectedItem) { _, newValue in
                        viewModel.handleLocationChange(newValue, gameModel: gameModel)
                    }

                
                if locationHandler.hasLocationAccess{
                    locationSection
                }
                
                if let course = gameModel.getCourse() {
                    if course.pars == nil {
                        HStack {
                            Text("Holes:")
                            NumberPickerView(
                                selectedNumber: gameModel.binding(for: \.numberOfHoles),
                                minNumber: 9, maxNumber: 21
                            )
                        }
                    }
                } else {
                    // No course → show picker
                    HStack {
                        Text("Holes:")
                        NumberPickerView(
                            selectedNumber: gameModel.binding(for: \.numberOfHoles),
                            minNumber: 9, maxNumber: 21
                        )
                    }
                }
            } header: {
                Text("Game Info")
            }
        }
    }
    
    
    // MARK: – Composed Section
    
    private var locationSection: some View {
        Group {
            if NetworkChecker.shared.isConnected {
                HStack{
                    VStack{
                        HStack{
                            Text("Location:")
                            Spacer()
                        }
                        if showTextAndButtons {
                            if let item = locationHandler.selectedItem {
                                HStack{
                                    Text(item.name ?? "Unnamed")
                                        .foregroundStyle(.secondary)
                                        .truncationMode(.tail)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                    Spacer()
                                }
                            } else {
                                HStack{
                                    Text("No location found")
                                        .foregroundStyle(.secondary)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if !showTextAndButtons {
                        Button {
                            viewModel.searchNearby(showTxtButtons: $showTextAndButtons, gameModel: gameModel)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass")
                                Text("Search Nearby")
                            }
                            .frame(width: 180, height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .buttonStyle(.plain)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        
                        
                        // Retry Button
                        Button(action: {
                            withAnimation(){
                                viewModel.retry(showTxtButtons: $showTextAndButtons, isRotating: $isRotating, gameModel: gameModel)
                            }
                        }) {
                            Image(systemName: "arrow.trianglehead.2.clockwise")
                                .rotationEffect(.degrees(isRotating ? 360 : 0))
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        
                        
                        // Exit Button
                        Button(action: {
                            withAnimation {
                                viewModel.exit(showTxtButtons: $showTextAndButtons, email: $newPlayerEmail, gameModel: gameModel)
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .onAppear {
                    viewModel.setUp(showTxtButtons: $showTextAndButtons, gameModel: gameModel)
                }
            }
        }
    }
    
    private var playersSection: some View {
        Section(header: Text("Players: \(gameModel.gameValue.players.count)")) {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(gameModel.gameValue.players) { player in
                        PlayerIconView(player: player, isRemovable: player.userId.count == 6) {
                            viewModel.playerToDelete = player.userId
                            viewModel.resetTimer(gameModel)
                            showDeleteAlert = true
                        }
                    }
                    Button(action: {
                        showAddPlayerAlert = true
                        viewModel.resetTimer(gameModel)
                    }) {
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "plus")
                            }
                            Text("Add Player").font(.caption)
                        }
                        .padding(.horizontal)
                    }
                    if gameModel.isOnline {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(width: 40, height: 40)
                            Text("Searching...").font(.caption)
                        }.padding(.horizontal)
                    }
                }
            }
            .frame(height: 75)
        }
    }
    
    private var startGameSection: some View {
        Button {
            viewModel.startGame(viewManager: viewManager, showHost: $showHost, isGuest: isGuest, gameModel: gameModel)
            if isGuest{
                LocalGameRepository(context: context).deleteGuestGame(){ _ in}
            }
        } label: {
            HStack{
                Image(systemName: "play.fill")
                Text("Start Game")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.blue)
                    .padding(.horizontal)
            )
        }
    }
}
