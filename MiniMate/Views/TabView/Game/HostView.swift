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
    @EnvironmentObject var locationHandler: LocationHandler
    
    @Binding var showHost: Bool
    
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var viewManager: ViewManager
    
    @StateObject var VM: HostViewModel

    var isGuest: Bool
    
    init(
        showHost: Binding<Bool>,
        isGuest: Bool = false
    ) {
        self._showHost = showHost
        self.isGuest = isGuest
        _VM = StateObject(wrappedValue: HostViewModel())
    }
    
    var body: some View {
        mainContent
    }
    
    private var mainContent: some View {
        ZStack{
            
            Form {
                playersSection
                gameInfoSection
            }
            .contentMargins(.top, 100)
            .contentMargins(.bottom, 70)
            
            VStack{
                VStack{
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
                                gameModel.dismissGame()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(.blue)
                                    .frame(width: 20, height: 20)
                            }
                            .padding(.horizontal, 8)
                        }
                        
                        Text(gameModel.isOnline ? "Hosting Game" : "Game Setup")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    .padding(.leading, 20)
                }
                .padding(.bottom, 16)
                .background(.ultraThinMaterial)
                
                Spacer()
                
                startGameSection
                
                if isGuest {
                    Color.clear
                        .frame(width: 20, height: 30)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            VM.resetTimer(gameModel)
        }
        .onChange(of: showHost) { _, newValue in
            if !newValue && !gameModel.started {
                gameModel.dismissGame()
            }
        }
        .alert("Add Local Player?", isPresented: $VM.showAddPlayerAlert) {
            
            TextField("Name", text: $VM.newPlayerName)
                .characterLimit($VM.newPlayerName, maxLength: 18)
            
            if gameModel.getCourse() != nil {
                TextField("Email", text: $VM.newPlayerEmail)
                    .autocapitalization(.none)   // starts lowercase / no auto-cap
                    .keyboardType(.emailAddress)
            }
            
            Button("Add") {
                VM.addPlayer(gameModel: gameModel)
            }
            .disabled(
                gameModel.getCourse() != nil
                ?
                VM.newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                VM.newPlayerEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                ProfanityFilter.containsBlockedWord(VM.newPlayerName) ||
                !VM.newPlayerEmail.isValidEmail
                :
                    VM.newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                ProfanityFilter.containsBlockedWord(VM.newPlayerName)
            )
            .tint(.blue)
            
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Player?", isPresented: $VM.showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let player = VM.playerToDelete {
                    gameModel.removePlayer(userId: player)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onReceive(VM.timer) { _ in
            VM.tick(showHost: $showHost, gameModel: gameModel)
        }
        .environmentObject(VM)
    }
    
    // MARK: - Sections
    private var gameInfoSection: some View {
        let course = gameModel.getCourse()
        return Group {
            Section {
                if gameModel.isOnline {
                    VStack{
                        HStack {
                            Text("Game Code:")
                            Spacer()
                            Text(gameModel.gameValue.id)
                            Image(systemName: "qrcode")
                                .font(.system(size: 20, weight: .medium))
                        }
                        
                        Image(uiImage: VM.qrCodeImage ?? UIImage(systemName: "xmark.circle") ?? UIImage())
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.primary.opacity(0.1))
                            )
                    }
                    
                    
                    HStack {
                        Text("Expires in:")
                        Spacer()
                        Text(VM.timeString())
                            .monospacedDigit()
                    }
                }
                
                if locationHandler.hasLocationAccess{
                    LocationButtons()
                }
                
                if let course {
                    if let pars = course.pars {
                        UserInfoRow(label: "Holes", value: String(pars.count))
                    } else {
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
    
    private var playersSection: some View {
        Section(header: Text("Players: \(gameModel.gameValue.players.count)")) {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(gameModel.gameValue.players) { player in
                        PlayerIconView(player: player, isRemovable: player.userId.count == 6) {
                            VM.playerToDelete = player.userId
                            VM.resetTimer(gameModel)
                            VM.showDeleteAlert = true
                        }
                    }
                    Button(action: {
                        VM.showAddPlayerAlert = true
                        VM.resetTimer(gameModel)
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
            .simultaneousGesture(
                DragGesture().onChanged { _ in
                    VM.resetTimer(gameModel)
                }
            )
            .frame(height: 75)
        }
    }
    
    private var startGameSection: some View {
        Button {
            VM.startGame(viewManager: viewManager, showHost: $showHost, isGuest: isGuest, gameModel: gameModel)
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

struct LocationButtons: View {
    
    @EnvironmentObject var VM: HostViewModel
    @EnvironmentObject var gameModel: GameViewModel
    @EnvironmentObject var locationHandler: LocationHandler
    
    var body: some View {
        Group {
            if NetworkChecker.shared.isConnected {
                HStack{
                    VStack{
                        HStack{
                            Text("Location:")
                            Spacer()
                        }
                        if VM.showTextAndButtons {
                            if let item = gameModel.getCourse()?.name {
                                HStack{
                                    Text(item)
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
                    
                    if VM.showLocationButton {
                        if !VM.showTextAndButtons {
                            searchNearbyButton
                        } else {
                            retryButton
                            exitButton
                        }
                    } else {
                        noButtons
                    }
                }
            }
        }
        .onAppear {
            VM.setUp(gameModel: gameModel, handler: locationHandler)
        }
    }
    
    var noButtons: some View{
        Group{
            if let item = gameModel.getCourse()?.name {
                HStack{
                    Spacer()
                    Text(item)
                        .foregroundStyle(.secondary)
                        .truncationMode(.tail)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            } else {
                HStack{
                    Spacer()
                    Text("No location found")
                        .foregroundStyle(.secondary)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
    
    var searchNearbyButton: some View {
        Button {
            VM.searchNearby(gameModel: gameModel, handler: locationHandler)
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
    }
    
    var retryButton: some View {
        Button(action: {
            withAnimation(){
                VM.retry(gameModel: gameModel, handler: locationHandler)
            }
        }) {
            Image(systemName: "arrow.trianglehead.2.clockwise")
                .rotationEffect(.degrees(VM.isRotating ? 360 : 0))
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.blue)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }
    
    var exitButton: some View {
        Button(action: {
            withAnimation {
                VM.exit(gameModel: gameModel, handler: locationHandler)
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
