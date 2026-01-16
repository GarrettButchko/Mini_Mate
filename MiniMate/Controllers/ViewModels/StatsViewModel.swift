//
//  StatsViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 1/15/26.
//

import SwiftUI
import SwiftData

@MainActor
final class StatsViewModel: ObservableObject {

    // MARK: - UI State
    @Published var pickedSection: String = "Games"
    let pickerSections: [String] = ["Games", "Overview"]

    @Published var searchText: String = ""
    @Published var latest: Bool = true

    @Published var editOn: Bool = false
    @Published var editingGameID: String? = nil

    @Published var isSharePresented: Bool = false
    @Published var shareContent: String = ""

    @Published var isCooldown: Bool = false
    
    @Published var isCooldown2: Bool = false

    // MARK: - Derived / Computed
    @Published private(set) var analyzer: UserStatsAnalyzer? = nil

    // Optional: track loading if you add remote refresh later
    @Published var isRefreshing: Bool = false

    // MARK: - Public API

    func onAppear(user: UserModel?, games: [Game], context: ModelContext) {
        guard let user else { return }
        self.analyzer = UserStatsAnalyzer(user: user, games: games, context: context)
    }

    func toggleSortWithCooldown() {
        guard !isCooldown else { return }

        withAnimation {
            latest.toggle()
        }

        isCooldown = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isCooldown = false
        }
    }

    func presentShareSheet(text: String) {
        shareContent = text
        isSharePresented = true
    }

    
    // MARK: - Optional: add a refresh hook if you later trigger cloud sync from here
    func refreshFromCloudIfNeeded(
        user: UserModel,
        authModel: AuthViewModel? = nil,
        context: ModelContext,
        completion: @escaping () -> Void
    ) {
        guard !isCooldown2 else { return }
        
        guard NetworkChecker.shared.isConnected else {
            coolDown()
            completion()
            return
        }
        
        func coolDown() {
            isCooldown2 = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.isCooldown2 = false
            }
        }
        
        func findGamesToLoadAndLoad() {
            let localRepo = LocalGameRepository(context: context)
            withAnimation(){
                isRefreshing = true
            }

            localRepo.missingLocalGameIDs(from: user.gameIDs) { missingGameIDs in
                // Nothing missing
                guard !missingGameIDs.isEmpty else {
                    DispatchQueue.main.async {
                        withAnimation(){
                            self.isRefreshing = false
                        }
                        coolDown()
                        completion()
                    }
                    return
                }

                FirestoreGameRepository().fetchAll(withIDs: missingGameIDs) { gameDTOs in
                    let games = gameDTOs.map { Game.fromDTO($0) }

                    // SwiftData context safety: save on main
                    DispatchQueue.main.async {
                        localRepo.save(games) { success in
                            if success {
                                print("✅ Refreshed \(games.count) missing games from cloud")
                            } else {
                                print("❌ Failed saving refreshed games locally")
                            }

                            withAnimation(){
                                self.isRefreshing = false
                            }
                            coolDown()
                            completion()
                        }
                    }
                }
            }
        }
        
        if let authModel {
            UserRepository(context: context).loadOrCreateUser(id: user.googleId, authModel: authModel) { _ in
                findGamesToLoadAndLoad()
            }
        } else {
            findGamesToLoadAndLoad()
        }
    }
}
