//
//  RemoteGameRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 11/24/25.
//
import Foundation
import FirebaseFirestore

class FirestoreGameRepository {
    
    private let db = Firestore.firestore()
    
    // Save or update a game in Firestore
    func save(_ game: Game, completion: @escaping (Bool) -> Void) {
        do {
            try db.collection("games").document(game.id).setData(from: game.toDTO(), merge: true) { error in
                if let error = error {
                    print("❌ Firestore save error: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        } catch {
            print("❌ Firestore encoding error: \(error)")
            completion(false)
        }
    }
    
    func save(_ games: [Game], completion: @escaping (Bool) -> Void) {
        guard !games.isEmpty else {
            completion(true)
            return
        }
        
        let group = DispatchGroup()
        var didFail = false
        
        for game in games {
            group.enter()
            do {
                try db.collection("games")
                    .document(game.id)
                    .setData(from: game.toDTO(), merge: true) { error in
                        if let error = error {
                            print("❌ Firestore save error for \(game.id): \(error.localizedDescription)")
                            didFail = true
                        }
                        group.leave()
                    }
            } catch {
                print("❌ Firestore encoding error for \(game.id): \(error)")
                didFail = true
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(!didFail)
        }
    }

    
    // Fetch a single game by ID
    func fetch(id: String, completion: @escaping (GameDTO?) -> Void) {
        let ref = db.collection("games").document(id)
        ref.getDocument { snapshot, error in
            if let error = error {
                print("❌ Firestore fetch error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                completion(nil)
                return
            }
            
            Task{ @MainActor in
                do {
                    let game = try snapshot.data(as: GameDTO.self)
                    completion(game)
                } catch {
                    print("❌ Firestore decoding error: \(error)")
                    completion(nil)
                }
            }
            
        }
    }
    
    func fetchAll(withIDs ids: [String], completion: @escaping ([GameDTO]) -> Void) {
        guard !ids.isEmpty else {
            completion([])
            return
        }

        let chunks = stride(from: 0, to: ids.count, by: 10).map {
            Array(ids[$0..<min($0 + 10, ids.count)])
        }

        let group = DispatchGroup()
        let syncQueue = DispatchQueue(label: "FirestoreGameRepository.fetchAll.sync")

        var allGames: [String: GameDTO] = [:]

        for chunk in chunks {
            group.enter()

            db.collection("games")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("❌ Firestore fetchAll chunk error: \(error.localizedDescription)")
                    }

                    if let docs = snapshot?.documents {
                        for doc in docs {
                            do {
                                let dto = try doc.data(as: GameDTO.self)
                                // write synchronously so it’s definitely in the dict before we leave the group
                                syncQueue.sync {
                                    allGames[dto.id] = dto
                                }
                            } catch {
                                print("❌ Firestore decoding error for id \(doc.documentID): \(error)")
                            }
                        }
                    }

                    group.leave()
                }
        }

        group.notify(queue: .main) {
            // read on sync queue to avoid race
            syncQueue.async {
                let ordered = ids.compactMap { allGames[$0] }
                DispatchQueue.main.async {
                    completion(ordered)
                }
            }
        }
    }




    
    // Delete a game by ID
    func delete(id: String, completion: @escaping (Bool) -> Void) {
        db.collection("games").document(id).delete { error in
            if let error = error {
                print("❌ Firestore delete error: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func deleteAll(
        ids: [String],
        completion: @escaping (Bool) -> Void
    ) {
        guard !ids.isEmpty else {
            completion(true)
            return
        }

        let batch = db.batch()

        for id in ids {
            let ref = db.collection("games").document(id)
            batch.deleteDocument(ref)
        }

        batch.commit { error in
            if let error = error {
                print("❌ Firestore batch delete error: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}

