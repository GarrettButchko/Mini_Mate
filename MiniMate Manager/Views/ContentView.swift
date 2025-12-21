//
//  ContentView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/6/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) var context
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var viewManager: ViewManager
    @StateObject var viewModel = CourseViewModel()
    
    @State private var selectedTab = 1
    
    var body: some View {
        ZStack {
            Group {
                switch viewManager.currentView {
                case .courseTab(let tab):
                    CourseTabView(selectedTab: tab)
                case .courseList:
                    CourseListView()
                case .welcome:
                    WelcomeView(viewManager: viewManager, welcomeText: "Mini Mate Manager", gradientColors: [.managerBlue, .managerGreen])
                case .signIn:
                    SignInView(authModel: authModel, viewManager: viewManager, gradientColors: [.managerBlue, .managerGreen])
                }
            }
        }
        .animation(.easeInOut(duration: 0.1), value: viewManager.currentView)
        .environmentObject(viewModel)
    }
}

struct CourseTabView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var viewModel: CourseViewModel

    @State var selectedTab: Int
    
    init(selectedTab: Int){
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
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }
}
