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
        
        // 3) now inject both into your GameViewModel
        _gameModel = StateObject(
            wrappedValue: GameViewModel(
                game: Game(),
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
                    HostView(showHost: $showHost, isGuest: true, showLocationButton: true)
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
    
    init(selectedTab: Int){
        self.selectedTab = selectedTab
    }
    
    var body: some View {
        
        TabView(selection: $selectedTab) {
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
                .tag(0)
            
            MainView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(1)
            if NetworkChecker.shared.isConnected {
                CourseView()
                    .tabItem { Label("Courses", systemImage: "figure.golf") }
                    .tag(2)
            }
        }
        .onAppear {
            if let id = authModel.currentUserIdentifier{
                userRepo.loadOrCreateUser(id: id, authModel: authModel) { done1, done2, creation in
                    Task { await iapManager.isPurchasedPro(authModel: authModel)
                        if done2{
                            LocalGameRepository(context: context).deleteAllUnusedGames { _ in }
                            StatsViewModel().refreshFromCloudIfNeeded(user: authModel.userModel!, context: context) {}
                        }
                    }
                }
            }
        }
    }
}
