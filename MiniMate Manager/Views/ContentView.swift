//
//  ContentView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/6/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) var context
    @StateObject private var viewManager = ViewManager()
    @StateObject private var authModel = AuthViewModel()
    
    @State private var selectedTab = 1
    
    var body: some View {
        ZStack {
            Group {
                switch viewManager.currentView {
                case .courseTab(let tab):
                    CourseTabView(viewManager: viewManager, authModel: authModel, selectedTab: tab)
                case .courseList:
                    CourseListView()
                case .welcome:
                    WelcomeView(viewManager: viewManager)
                case .signIn:
                    SignInView(authModel: authModel, viewManager: viewManager)
                }
            }
        }
    }
}

struct CourseTabView: View {
    @Environment(\.modelContext) private var context
    @ObservedObject var viewManager: ViewManager
    @ObservedObject var authModel: AuthViewModel
    
    private var userRepo: UserRepository { UserRepository(context: context)}
    
    @State var selectedTab: Int
    
    init(viewManager: ViewManager, authModel: AuthViewModel, selectedTab: Int){
        self.viewManager = viewManager
        self.authModel = authModel
        self.selectedTab = selectedTab
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AnalyticsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
                .tag(0)
            
            MainView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(1)
            
            CourseSettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(2)
        }
        .onAppear {
            userRepo.loadOrCreateUser(id: authModel.currentUserIdentifier!, authModel: authModel) {}
        }
    }
}
