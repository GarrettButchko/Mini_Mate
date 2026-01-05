import SwiftUI
import MapKit
import FirebaseAuth
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) var context
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var viewManager = ViewManager()
    @StateObject private var authModel: AuthViewModel
    @StateObject private var gameModel: GameViewModel
    
    let locFuncs = LocFuncs()
    
    //@State var ad: Ad? = nil
    
    @State private var selectedTab = 1
    @State private var previousView: ViewType?
    
    init() {
        // 1) create your AuthViewModel first
        let auth = AuthViewModel()
        _authModel = StateObject(wrappedValue: auth)
        
        // 2) create an initial Game (or fetch one from your context)
        let initialGame =  Game(id: "", date: Date(), completed: false, numberOfHoles: 18, started: false, dismissed: false, live: false, lastUpdated: Date(), players: [])
        
        // 3) now inject both into your GameViewModel
        _gameModel = StateObject(
            wrappedValue: GameViewModel(
                game: initialGame,
                authModel: auth,
                onlineGame: true,
                course: nil
            )
        )
    }
    
    var body: some View {
        ZStack {
            Group {
                switch viewManager.currentView {
                case .main(let tab):
                    MainTabView(viewManager: viewManager, authModel: authModel, gameModel: gameModel, selectedTab: tab)
                case .welcome:
                    WelcomeView(viewManager: viewManager)
                    
                case .scoreCard:
                    ScoreCardView(viewManager: viewManager, authModel: authModel, gameModel: gameModel)
                    
                case .gameReview(let gameModel):
                    GameReviewView(viewManager: viewManager, game: gameModel, showBackToStatsButton: true)
                case .ad:
                    InterstitialAdView(adUnitID: "ca-app-pub-8261962597301587/3394145015") {
                        viewManager.currentView = .main(1)
                    }
                case .signIn:
                    SignInView(authModel: authModel, viewManager: viewManager)
                }
                
            }
            .transition(currentTransition)
            
        }
        .animation(.easeInOut(duration: 0.4), value: viewManager.currentView)
        .onChange(of: viewManager.currentView, { oldValue, newValue in
            previousView = viewManager.currentView
        })
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                print("App is active")
                try? context.save()
            case .inactive:
                print("App is inactive")
                try? context.save()
            case .background:
                print("App moved to background")
                try? context.save()
            @unknown default:
                break
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    // MARK: - Custom transition based on view switch
    private var currentTransition: AnyTransition {
        switch (previousView, viewManager.currentView) {
        case (_, .main):
            return .opacity.combined(with: .scale)
        case (_, .welcome):
            return .opacity
        default:
            return .opacity
        }
    }
    
    
}

struct MainTabView: View {
    @Environment(\.modelContext) private var context
    @ObservedObject var viewManager: ViewManager
    @ObservedObject var authModel: AuthViewModel
    @ObservedObject var gameModel: GameViewModel
    //let ad: Ad?
    @StateObject var locationHandler = LocationHandler()
    @StateObject var iapManager = IAPManager()
    
    private var userRepo: UserRepository { UserRepository(context: context)}
    
    @State var selectedTab: Int
    
    init(viewManager: ViewManager, authModel: AuthViewModel, gameModel: GameViewModel, selectedTab: Int){
        self.viewManager = viewManager
        self.authModel = authModel
        self.gameModel = gameModel
        self.selectedTab = selectedTab
    }
    
    var body: some View {
        
        TabView(selection: $selectedTab) {
            StatsView(viewManager: viewManager, authModel: authModel)
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
                .tag(0)
            
            MainView(viewManager: viewManager, authModel: authModel, locationHandler: locationHandler, gameModel: gameModel)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(1)
            if NetworkChecker.shared.isConnected {
                CourseView(viewManager: viewManager, authModel: authModel, locationHandler: locationHandler)
                    .tabItem { Label("Courses", systemImage: "figure.golf") }
                    .tag(2)
            }
        }
        .onAppear {
            guard authModel.userModel == nil else { return }   // already loaded
            guard let id = authModel.currentUserIdentifier else { return }

            userRepo.loadOrCreateUser(id: id, authModel: authModel) {
                Task { await iapManager.isPurchasedPro(authModel: authModel) }
            }
        }
    }
}
