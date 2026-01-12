import SwiftUI
import _SwiftData_SwiftUI
import StoreKit
import MapKit

struct MainView: View {
    @Environment(\.modelContext) private var context
    
    @Query var allGames: [Game]
    
    var games: [Game] {
        allGames.filter { authModel.userModel?.gameIDs.contains($0.id) == true }
    }
    
    var disablePlaying: Bool {
        authModel.userModel?.isPro == false && (authModel.userModel?.gameIDs.count ?? 0) >= 2
    }
    
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var viewManager: ViewManager
    @ObservedObject var authModel: AuthViewModel
    @ObservedObject var locationHandler: LocationHandler
    @ObservedObject var gameModel: GameViewModel

    @State private var nameIsPresented = false
    @State private var isSheetPresented = false
    @State var isOnlineMode = false
    @State var showHost = false
    @State var showJoin = false
    @State var showFirstStage: Bool = false
    @State var alreadyShown: Bool = false
    @State var editOn: Bool = false
    @State var showDonation: Bool = false
    
    private var uniGameRepo: UnifiedGameRepository { UnifiedGameRepository(context: context) }
    
    @State private var analyzer: UserStatsAnalyzer? = nil
    
    var body: some View {
        
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
                
                // MARK: - Game Action Buttons
                
                ZStack{
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
                                    
                                    if !authModel.userModel!.isPro && games.count >= 2 {
                                        Text("You’ve reached the free limit. Upgrade to Pro to store more than 2 games.")
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(.ultraThinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 25))
                                    }
                                    
                                    if NetworkChecker.shared.isConnected && !authModel.userModel!.isPro {
                                        VStack{
                                            BannerAdView(adUnitID: "ca-app-pub-8261962597301587/6344452429") // Replace with real one later
                                                .frame(height: 50)
                                                .padding()
                                        }
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 25))
                                    }
                                    
                                    if games.count != 0{
                                        Button {
                                            viewManager.navigateToGameReview(games.sorted(by: { $0.date > $1.date }).first!)
                                        } label: {
                                            SectionStatsView(title: "Last Game") {
                                                HStack{
                                                    HStack{
                                                        VStack(alignment: .leading, spacing: 8) {
                                                            Text("Winner")
                                                                .font(.caption)
                                                                .foregroundStyle(.secondary)
                                                                .foregroundStyle(.mainOpp)
                                                            PhotoIconView(photoURL: analyzer?.winnerOfLatestGame?.photoURL, name: (analyzer?.winnerOfLatestGame?.name ?? "N/A") + "🥇", imageSize: 30, background: Color.yellow)
                                                            Spacer()
                                                        }
                                                        Spacer()
                                                    }
                                                    .padding()
                                                    .frame(height: 120)
                                                    .background(colorScheme == .light
                                                                ? AnyShapeStyle(Color.white)
                                                                : AnyShapeStyle(.ultraThinMaterial))
                                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                                                    StatCard(title: "Your Strokes", value: "\(analyzer?.usersScoreOfLatestGame ?? 0)", color: .green)
                                                }
                                                
                                                BarChartView(data: analyzer?.usersHolesOfLatestGame ?? [], title: "Recap of Game")
                                                
                                            }
                                            .padding(.bottom)
                                        }
                                        
                                    } else {
                                        Image("logoOpp")
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                        Spacer()
                                    }
                                }
                            }
                            .scrollIndicators(.hidden)
                        }
                    }
                    
                    VStack(){
                        
                        TitleView()
                            .frame(height: 150)
                        
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
                                        Text("Start a Game")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .transition(.opacity.combined(with: .scale))
                                    }
                                }
                                .animation(.easeInOut(duration: 0.35), value: isOnlineMode)
                                
                                Spacer()
                                
                                // Mirror the left spacer for symmetry
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 30, height: 30)
                            }
                            
                            ZStack {
                                if isOnlineMode {
                                    HStack(spacing: 16) {
                                        gameModeButton(title: "Host", icon: "antenna.radiowaves.left.and.right", color: .purple) {
                                            
                                                gameModel.createGame(online: true)
                                                showHost = true
                                            
                                        }
                                        .sheet(isPresented: $showHost) {
                                            HostView(showHost: $showHost, authModel: authModel, viewManager: viewManager, locationHandler: locationHandler)
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
                                            HostView(showHost: $showHost, authModel: authModel, viewManager: viewManager, locationHandler: locationHandler)
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
                                .ifAvailableGlassEffect()
                        })
                        
                        
                        Spacer()
                        
                        // Donation Button
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
                                    .background(Color.purple)
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                                    .shadow(radius: 10)
                                }
                                .sheet(isPresented: $showDonation) {
                                    ProView(showSheet: $showDonation, authModel: authModel)
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
        .onAppear(){
            if let user = authModel.userModel {
                self.analyzer = UserStatsAnalyzer(user: user, games: games, context: context)
            }
        }
        .onChange(of: games) { old, newGames in
            if let user = authModel.userModel {
                self.analyzer = UserStatsAnalyzer(user: user, games: newGames, context: context)
            }
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



