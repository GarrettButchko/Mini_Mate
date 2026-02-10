import SwiftUI
import MapKit
import FirebaseAuth
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) var context
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var viewManager = ViewManager()
    @StateObject var locationHandler = LocationHandler()
    @StateObject private var authModel: AuthViewModel
    @StateObject private var gameModel: GameViewModel
    
    let locFuncs = LocFuncs()
    
    //@State var ad: Ad? = nil
    
    @State private var selectedTab = 1
    @State private var previousView: ViewType?
    
    // need this for guest host view
    @State private var showHost: Bool = true
    
    init() {
        // 1) create your AuthViewModel first
        let auth = AuthViewModel()
        _authModel = StateObject(wrappedValue: auth)
        
        // 2) Create placeholder Game for GameViewModel (lightweight)
        let placeholderGame = Game(
            id: "",
            date: Date(),
            completed: false,
            numberOfHoles: 18,
            started: false,
            dismissed: false,
            live: false,
            lastUpdated: Date(),
            players: []
        )
        
        // 3) Inject with placeholder - actual game loaded when needed
        _gameModel = StateObject(
            wrappedValue: GameViewModel(
                game: placeholderGame,
                authModel: auth,
                course: nil
            )
        )
    }
    
    var body: some View {
        ZStack {
            Group {
                switch viewManager.currentView {
                case .main(let tab):
                    MainTabView(selectedTab: tab)
                case .welcome:
                    WelcomeView(viewManager: viewManager)
                    
                case .scoreCard(let isGuest):
                    ScoreCardView(isGuest: isGuest)
                    
                case .ad(let isGuest):
                    InterstitialAdView(adUnitID: "ca-app-pub-8261962597301587/3394145015") {
                        if isGuest {
                            viewManager.navigateToSignIn()
                        } else {
                            viewManager.currentView = .main(1)
                        }
                    }
                case .signIn:
                    SignInView()
                case .host:
                    HostView(showHost: $showHost, isGuest: true)
                }
            
                
            }
            .transition(currentTransition)
            
        }
        .environmentObject(gameModel)
        .environmentObject(authModel)
        .environmentObject(viewManager)
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
        .environment(gameModel)
        .environment(locationHandler)
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
    @EnvironmentObject var viewManager: ViewManager
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var gameModel: GameViewModel
    //let ad: Ad?
    
    @StateObject var iapManager = IAPManager()
    
    private var userRepo: UserRepository { UserRepository(context: context)}
    
    @State var selectedTab: Int
    @State private var loadedTabs: Set<Int> = [1] // Home tab loaded by default
    @State private var initialLoadComplete = false
    
    init(selectedTab: Int){
        self.selectedTab = selectedTab
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Lazy load Stats tab
                Group {
                    if loadedTabs.contains(0) {
                        StatsView()
                    } else {
                        Color.clear.onAppear {
                            loadedTabs.insert(0)
                        }
                    }
                }
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
                .tag(0)
                
                // Home tab - always loaded
                MainView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(1)
                
                // Lazy load Course tab
                if NetworkChecker.shared.isConnected {
                    Group {
                        if loadedTabs.contains(2) {
                            CourseView()
                        } else {
                            Color.clear.onAppear {
                                loadedTabs.insert(2)
                            }
                        }
                    }
                    .tabItem { Label("Courses", systemImage: "figure.golf") }
                    .tag(2)
                }
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                // Preload tab content when user switches
                loadedTabs.insert(newValue)
            }
            
            // Subtle loading overlay - only shows briefly during initial load
            if authModel.isLoadingUser && !initialLoadComplete && authModel.userModel == nil {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    )
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Launch background tasks that don't block UI
            // Using Task (not detached) to stay on main actor for ModelContext
            Task(priority: .userInitiated) {
                
                guard let id = authModel.currentUserIdentifier else { return }
                
                // Initialize IAP manager first
                await iapManager.initialize()
                
                // Load user data
                let userRepo = UserRepository(context: context)
                _ = await userRepo.loadOrCreateUserAsync(id: id, authModel: authModel)
                
                print("Runnnign after user data loaded - userModel is now: \(String(describing: authModel.userModel))")
                
                // Mark initial load complete
                initialLoadComplete = true
                
                // Defer non-critical operations - yield to let UI update
                await Task.yield()
                
                // Run these after initial load
                await iapManager.isPurchasedPro(authModel: authModel)
                
                if let userModel = authModel.userModel {
                    LocalGameRepository(context: context).deleteAllUnusedGames { _ in }
                    StatsViewModel().refreshFromCloudIfNeeded(user: userModel, context: context) {}
                }
            }
        }
    }
}
