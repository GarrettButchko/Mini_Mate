import SwiftUI
import _SwiftData_SwiftUI
import StoreKit
import MapKit

struct MainView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var locationHandler: LocationHandler
    
    @Query var allGames: [Game]
    @State private var filteredGames: [Game] = []
    
    var disablePlaying: Bool {
        authModel.userModel?.isPro == false && (authModel.userModel?.gameIDs.count ?? 0) >= 2
    }
    
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject var viewManager: ViewManager
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var gameModel: GameViewModel
    
    @State private var nameIsPresented = false
    @State private var isSheetPresented = false
    @State var isOnlineMode = false
    @State var showHost = false
    @State var showJoin = false
    @State var showFirstStage: Bool = false
    @State var alreadyShown: Bool = false
    @State var editOn: Bool = false
    @State var showDonation: Bool = false
    @State var showInfo: Bool = false
    @State var showTextAndButtons: Bool = false
    @State var isRotating: Bool = false
    @State var gameReview: Game? = nil
    
    private var uniGameRepo: UnifiedGameRepository { UnifiedGameRepository(context: context) }
    
    @State private var analyzer: UserStatsAnalyzer? = nil
    @State private var analyzerTask: Task<Void, Never>? = nil
    @State private var showDeferredContent = false

    private var userGameIDs: [String] {
        authModel.userModel?.gameIDs ?? []
    }
    
    var body: some View {
        let course = gameModel.getCourse()
        
        ZStack {
            VStack(spacing: 24) {
                // MARK: - Top Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Welcome back,")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(authModel.userModel?.name ?? "User")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if let courseLogo = course?.logo {
                            Divider()
                            
                            AsyncImage(url: URL(string: courseLogo)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Text("Error")
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .id(URL(string: courseLogo))
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isSheetPresented = true
                    }) {
                        if let photoURL = authModel.firebaseUser?.photoURL {
                            AsyncImage(url: photoURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image("logoOpp")
                                    .resizable()
                                    .scaledToFill()
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .id(photoURL)
                        } else {
                            Image("logoOpp")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                        }
                    }
                    .sheet(isPresented: $isSheetPresented) {
                        ProfileView(
                            viewManager: viewManager,
                            authModel: authModel,
                            isSheetPresent: $isSheetPresented, context: context
                        )
                    }
                }
                
                ZStack{
                    // MARK: - Under Buttons
                    if authModel.userModel != nil{
                        VStack{
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 175)
                            
                            ScrollView{
                                VStack(spacing: 15){
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(height: 110)
                                    
                                    if NetworkChecker.shared.isConnected {
                                        locationButtons(course: course)
                                    }
                                    
                                    proStopper

                                    if showDeferredContent {
                                        ad
                                        lastGameStats
                                    }
                                }
                            }
                            .scrollIndicators(.hidden)
                        }
                    }
                    
                    VStack(){
                        TitleView(colors: course?.courseColors)
                            .frame(height: 150)
                        
                        // MARK: - Game Action Buttons
                        VStack {
                            HStack {
                                ZStack {
                                    if isOnlineMode {
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.35)) {
                                                isOnlineMode = false
                                            }
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(.primary)
                                                    .frame(width: 30, height: 30)
                                                Image(systemName: "chevron.left")
                                                    .foregroundStyle(.white)
                                                    .frame(width: 20, height: 20)
                                            }
                                        }
                                    } else {
                                        // Keep layout aligned using an invisible spacer
                                        Circle()
                                            .fill(Color.clear)
                                            .frame(width: 30, height: 30)
                                    }
                                }
                                
                                Spacer()
                                
                                ZStack {
                                    if isOnlineMode {
                                        Text("Online Options")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .transition(.opacity.combined(with: .scale))
                                    } else {
                                        Text("Start a Round")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .transition(.opacity.combined(with: .scale))
                                    }
                                }
                                .animation(.easeInOut(duration: 0.35), value: isOnlineMode)
                                
                                Spacer()
                                
                                // Mirror the left spacer for symmetry
                                
                                Button {
                                    showInfo = true
                                } label: {
                                    Image(systemName: "info.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 25, height: 25)
                                        .foregroundStyle(.blue)
                                    
                                }
                                .confirmationDialog("Info", isPresented: $showInfo, titleVisibility: .visible) {
                                    Button("OK", role: .cancel) {}
                                } message: {
                                    Text(isOnlineMode
                                         ? "Host starts a server game. Join connects to an existing one. Multiple devices sync in real time."
                                         : "Quick starts a local game. Online lets you host or join a networked game."
                                    )
                                }
                            }
                            
                            ZStack {
                                if isOnlineMode {
                                    HStack(spacing: 16) {
                                        gameModeButton(title: "Host", icon: "antenna.radiowaves.left.and.right", color: .purple) {
                                            
                                            gameModel.createGame(online: true)
                                            showHost = true
                                        }
                                        .sheet(isPresented: $showHost) {
                                            HostView(showHost: $showHost)
                                                .presentationDetents([.large])
                                        }
                                        
                                        gameModeButton(title: "Join", icon: "person.2.fill", color: .orange) {
                                            
                                            gameModel.resetGame()
                                            showJoin = true
                                            
                                        }
                                        .sheet(isPresented: $showJoin) {
                                            JoinView(authModel: authModel, viewManager: viewManager, gameModel: gameModel, showHost: $showJoin)
                                                .presentationDetents([.large])
                                        }
                                    }
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .trailing).combined(with: .opacity)
                                    ))
                                    .clipped()
                                    
                                } else {
                                    
                                    HStack(spacing: 16) {
                                        gameModeButton(title: "Quick", icon: "person.fill", color: .blue) {
                                            if !disablePlaying {
                                                gameModel.createGame(online: false)
                                                showHost = true
                                                withAnimation {
                                                    isOnlineMode = false
                                                }
                                            } else {
                                                showDonation = true
                                            }
                                        }
                                        .sheet(isPresented: $showHost) {
                                            HostView(showHost: $showHost)
                                                .presentationDetents([.large])
                                        }
                                        
                                        if !NetworkChecker.shared.isConnected {
                                            HStack {
                                                Image(systemName: "globe")
                                                Text("Connect")
                                                    .fontWeight(.semibold)
                                            }
                                            .padding(10)
                                            .frame(maxWidth: .infinity, minHeight: 50)
                                            .background(RoundedRectangle(cornerRadius: 15).fill().foregroundStyle(.green))
                                            .foregroundColor(.white)
                                            .opacity(0.4)
                                        } else {
                                            gameModeButton(title: "Connect", icon: "globe", color: .green) {
                                                if !disablePlaying {
                                                    withAnimation {
                                                        isOnlineMode = true
                                                    }
                                                } else {
                                                    showDonation = true
                                                }
                                            }
                                        }
                                    }
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                                }
                            }
                            .animation(.easeInOut(duration: 0.3), value: isOnlineMode)
                            
                        }
                        .padding()
                        .background(content: {
                            RoundedRectangle(cornerRadius: 25)
                                .ifAvailableGlassEffect(makeColor: course?.scoreCardColor)
                        })
                        
                        
                        Spacer()
                        
                        // Pro Mode Button
                        if let userModel = authModel.userModel, !userModel.isPro && NetworkChecker.shared.isConnected {
                            HStack {
                                Spacer()
                                Button {
                                    if !showFirstStage {
                                        withAnimation {
                                            showFirstStage = true
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                                            if showFirstStage {
                                                withAnimation {
                                                    showFirstStage = false
                                                }
                                            }
                                        }
                                    } else {
                                        showDonation = true
                                    }
                                } label: {
                                    HStack {
                                        if showFirstStage {
                                            Text("Tap to buy Pro!")
                                                .transition(.move(edge: .trailing).combined(with: .opacity))
                                                .foregroundStyle(.white)
                                        }
                                        Text("✨")
                                    }
                                    .padding()
                                    .frame(height: 50)
                                    .background {
                                        RoundedRectangle(cornerRadius: 25)
                                            .ifAvailableGlassEffect(strokeWidth: 0, opacity: 0.7, makeColor: .purple)
                                    }
                                    .shadow(radius: 10)
                                }
                                .sheet(isPresented: $showDonation) {
                                    ProView(showSheet: $showDonation)
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .padding([.top, .horizontal])
        }
        .ignoresSafeArea(.keyboard)
        .task {
            updateFilteredGames()
            if !showDeferredContent {
                try? await Task.sleep(nanoseconds: 500_000_000)
                showDeferredContent = true
            }
            if NetworkChecker.shared.isConnected {
                gameModel.setUp(showTxtButtons: $showTextAndButtons, handler: locationHandler)
            }
            if course != nil {
                showTextAndButtons = true
            }
        }
        .onChange(of: allGames) { _, _ in
            updateFilteredGames()
        }
        .onChange(of: userGameIDs) { _, _ in
            updateFilteredGames()
        }
    }

    private func updateFilteredGames() {
        let ids = Set(userGameIDs)
        let newGames = allGames.filter { ids.contains($0.id) }
        filteredGames = newGames
        refreshAnalyzer(with: newGames)
    }

    private func refreshAnalyzer(with games: [Game]) {
        analyzerTask?.cancel()
        guard let user = authModel.userModel else {
            analyzer = nil
            return
        }
        analyzerTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                self.analyzer = UserStatsAnalyzer(user: user, games: games, context: context)
            }
        }
    }
    
    func locationButtons(course: Course?) -> some View {
        Group {
            if NetworkChecker.shared.isConnected {
                HStack{
                    VStack{
                        HStack{
                            Text("Location:")
                            Spacer()
                        }
                        if showTextAndButtons {
                            if let item = course?.name {
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
                    
                    
                    if !showTextAndButtons {
                        Button {
                            gameModel.searchNearby(showTxtButtons: $showTextAndButtons, handler: locationHandler)
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
                                gameModel.retry(showTxtButtons: $showTextAndButtons, isRotating: $isRotating, handler: locationHandler)
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
                                gameModel.exit(showTxtButtons: $showTextAndButtons, handler: locationHandler)
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
                .padding()
                .ultraThinMaterialVsColor(makeColor: course?.scoreCardColor)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .compositingGroup()
            }
        }
    }
    
    var proStopper: some View {
        Group{
            if !authModel.userModel!.isPro && authModel.userModel!.gameIDs.count >= 2 {
                Text("You’ve reached the free limit. Upgrade to Pro to store more than 2 games.")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .ultraThinMaterialVsColor(makeColor: gameModel.getCourse()?.scoreCardColor)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .compositingGroup()
            }
        }
    }
    
    var ad: some View {
        Group{
            if NetworkChecker.shared.isConnected && !authModel.userModel!.isPro {
                VStack{
                    BannerAdView(adUnitID: "ca-app-pub-8261962597301587/6344452429") // Replace with real one later
                        .frame(height: 50)
                        .padding()
                }
                .ultraThinMaterialVsColor(makeColor: gameModel.getCourse()?.scoreCardColor)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .compositingGroup()
            }
        }
    }
    
    @ViewBuilder
    var lastGameStats: some View {
        if let lastGame = analyzer?.latestGame {
            
            Button {
                gameReview = lastGame
            } label: {
                SectionStatsView(
                    title: "Last Game",
                    spacing: 12,
                    makeColor: gameModel.getCourse()?.scoreCardColor
                ) {
                    let cardHeight: CGFloat = 90
                    
                    HStack(spacing: 12) {
                        // 2. Only show Winner if it's a multiplayer game
                        if lastGame.players.count > 1 {
                            PhotoIconView(
                                photoURL: analyzer?.winnerOfLatestGame?.photoURL,
                                name: (analyzer?.winnerOfLatestGame?.name ?? "N/A") + " 🥇",
                                imageSize: 30,
                                background: .yellow
                            )
                            .padding()
                            .frame(height: cardHeight)
                            .background(colorScheme == .light ? AnyShapeStyle(Color.white) : AnyShapeStyle(.ultraThinMaterial))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        StatCard(
                            title: "Your Strokes",
                            value: "\(analyzer?.usersScoreOfLatestGame ?? 0)",
                            cornerRadius: 12,
                            cardHeight: cardHeight,
                            infoText: "The number of strokes you had last game."
                        )
                    }
                    
                    BarChartView(data: analyzer?.usersHolesOfLatestGame ?? [], title: "Recap of Game")
                        .frame(height: 150)
                }
                .padding(.bottom)
            }
            .buttonStyle(.plain) // Prevents the whole card from dimming like a standard button
            .sheet(item: $gameReview) { game in
                GameReviewView(game: game, showBackToStatsButton: true, gameReview: $gameReview)
                    .presentationDragIndicator(.visible)
            }
            
        } else {
            // 3. Elegant fallback if no games exist
            VStack(spacing: 16) {
                Image("logoOpp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .grayscale(1.0)
                    .opacity(0.5)
                
                Text("No games played yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }
    
    func gameModeButton(title: String, icon: String? = nil, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(RoundedRectangle(cornerRadius: 15).fill().foregroundStyle(color).opacity(disablePlaying ? 0.5 : 1))
            .foregroundColor(.white.opacity(disablePlaying ? 0.5 : 1))
        }
    }
}
