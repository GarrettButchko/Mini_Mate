//
//  MiniMate_ManagerApp.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/6/25.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import StoreKit

class AppDelegate: NSObject, UIApplicationDelegate {
    
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct MiniMate_ManagerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Local (non-shared) SwiftData container
    private var modelContainer: ModelContainer = {
        // Use a local file URL inside the app's Documents directory
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let storeURL = documentsURL.appendingPathComponent("MiniMate.sqlite")

        let config = ModelConfiguration(url: storeURL)
        return try! ModelContainer(
            for: UserModel.self,
            configurations: config
        )
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(modelContainer) // inject the ModelContext into the environment
    }
}
