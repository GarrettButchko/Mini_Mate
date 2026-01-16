//
//  LocalGameRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 11/24/25.
//

import SwiftData
import Foundation

class LocalGameRepository {
    let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func save(_ game: Game, completion: @escaping (Bool) -> Void) {
        context.insert(game)
        do {
            try context.save()
            completion(true)
        } catch {
            print("❌ Failed to save locally:", error)
            completion(false)
        }
    }
    
    func save(_ games: [Game], completion: @escaping (Bool) -> Void) {
        games.forEach { context.insert($0) }
        
        do {
            try context.save()
            completion(true)
        } catch {
            print("❌ Failed to save games locally:", error)
            completion(false)
        }
    }

    
    func fetch(id: String, completion: @escaping (Game?) -> Void) {
        do {
            let descriptor = FetchDescriptor<Game>(predicate: #Predicate { $0.id == id })
            let results = try context.fetch(descriptor)
            completion(results.first)
        } catch {
            print("❌ Failed to fetch locally by id:", error)
            completion(nil)
        }
    }
    
    func fetchGuestGame(completion: @escaping (Game?) -> Void) {
        do {
            // 1) Fetch guest game
            let gameDescriptor = FetchDescriptor<Game>(
                predicate: #Predicate { $0.hostUserId.contains("guest") }
            )
            let games = try context.fetch(gameDescriptor)
            guard let guestGame = games.first else {
                completion(nil)
                return
            }

            let guestGameID = guestGame.id

            // 2) Fetch all players
            let playerDescriptor = FetchDescriptor<UserModel>()
            let users = try context.fetch(playerDescriptor)

            // 3) Check if any player already references this game
            let isReferenced = users.contains(where: { user in
                user.gameIDs.contains(guestGameID)
            })

            // 4) Only return if truly orphaned
            completion(isReferenced ? nil : guestGame)

        } catch {
            print("❌ Failed to fetch guest game safely:", error)
            completion(nil)
        }
    }

    
    func deleteGuestGame(completion: @escaping (Bool) -> Void) {
        do {
            let descriptor = FetchDescriptor<Game>(predicate: #Predicate { $0.hostUserId.contains("guest")  })
            if let game = try context.fetch(descriptor).first {
                context.delete(game)
                try context.save()
                completion(true)
            } else {
                completion(false)
            }
        } catch {
            print("❌ Failed to delete locally:", error)
            completion(false)
        }
    }
    
    func fetchAll(ids: [String], completion: @escaping ([Game]) -> Void) {
        do {
            let allGames = try context.fetch(FetchDescriptor<Game>())
            let filtered = allGames.filter { ids.contains($0.id) }
            completion(filtered)
        } catch {
            print("❌ Failed to fetch games:", error)
            completion([])
        }
    }

    
    func delete(id: String, completion: @escaping (Bool) -> Void) {
        do {
            let descriptor = FetchDescriptor<Game>(predicate: #Predicate { $0.id == id })
            if let game = try context.fetch(descriptor).first {
                context.delete(game)
                try context.save()
                completion(true)
            } else {
                completion(false)
            }
        } catch {
            print("❌ Failed to delete locally:", error)
            completion(false)
        }
    }
    
    func deleteAll(ids: [String], completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var success = true

        for id in ids {
            group.enter()
            self.delete(id: id) { didDelete in
                if !didDelete { success = false }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(success)
        }
    }
}
