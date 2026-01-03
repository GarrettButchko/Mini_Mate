//
//  CourseLeaderboardRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 11/24/25.
//

import Foundation
import SwiftUI
import Foundation
import FirebaseFirestore


/// Handles all Realtime Database operations for CourseLeaderboards
final class CourseLeaderboardRepository {
    
    private let db = Firestore.firestore()
    
    // MARK: - Add / Update CourseLeaderboard
    private func allTimeEntriesRef(courseID: String) -> CollectionReference {
        db.collection("courses").document(courseID)
            .collection("leaderboardsAllTime")
            .document("entriesDoc")              // fixed doc so we can have a subcollection cleanly
            .collection("entries")
    }
    
    private func weeklyEntriesRef(courseID: String, weekID: String) -> CollectionReference {
        db.collection("courses").document(courseID)
            .collection("leaderboardsWeekly")
            .document(weekID)
            .collection("entries")
    }
    
    // MARK: - Fetch Top N (All-time)
    
    func fetchTopAllTime(courseID: String, limit: Int = 25, completion: @escaping ([LeaderboardEntry]) -> Void) {
        allTimeEntriesRef(courseID: courseID)
            .order(by: "totalStrokes", descending: false)
            .limit(to: limit)
            .getDocuments { snap, err in
                guard let docs = snap?.documents, err == nil else {
                    DispatchQueue.main.async { completion([]) }
                    return
                }
                let items: [LeaderboardEntry] = docs.compactMap { try? $0.data(as: LeaderboardEntry.self) }
                DispatchQueue.main.async { completion(items) }
            }
    }
    
    // MARK: - Fetch Top N (Weekly)
    
    func fetchTopWeekly(courseID: String, weekID: String, limit: Int = 25, completion: @escaping ([LeaderboardEntry]) -> Void) {
        weeklyEntriesRef(courseID: courseID, weekID: weekID)
            .order(by: "totalStrokes", descending: false)
            .limit(to: limit)
            .getDocuments { snap, err in
                guard let docs = snap?.documents, err == nil else {
                    DispatchQueue.main.async { completion([]) }
                    return
                }
                let items: [LeaderboardEntry] = docs.compactMap { try? $0.data(as: LeaderboardEntry.self) }
                DispatchQueue.main.async { completion(items) }
            }
    }
    
    // MARK: - Live Listening (All-time)
    
    func listenTopAllTime(courseID: String, limit: Int = 25, listener: inout ListenerRegistration?, onUpdate: @escaping ([LeaderboardEntry]) -> Void) {
        listener?.remove()
        
        listener = allTimeEntriesRef(courseID: courseID)
            .order(by: "totalStrokes", descending: false)
            .limit(to: limit)
            .addSnapshotListener { snap, err in
                guard let docs = snap?.documents, err == nil else {
                    DispatchQueue.main.async { onUpdate([]) }
                    return
                }
                let items: [LeaderboardEntry] = docs.compactMap { try? $0.data(as: LeaderboardEntry.self) }
                DispatchQueue.main.async { onUpdate(items) }
            }
    }
    
    // MARK: - Live Listening (Weekly)
    
    func listenTopWeekly(courseID: String, weekID: String, limit: Int = 25, listener: inout ListenerRegistration?, onUpdate: @escaping ([LeaderboardEntry]) -> Void) {
        listener?.remove()
        
        listener = weeklyEntriesRef(courseID: courseID, weekID: weekID)
            .order(by: "totalStrokes", descending: false)
            .limit(to: limit)
            .addSnapshotListener { snap, err in
                guard let docs = snap?.documents, err == nil else {
                    DispatchQueue.main.async { onUpdate([]) }
                    return
                }
                let items: [LeaderboardEntry] = docs.compactMap { try? $0.data(as: LeaderboardEntry.self) }
                DispatchQueue.main.async { onUpdate(items) }
            }
    }
    
    func stopListening(_ listener: inout ListenerRegistration?) {
        listener?.remove()
        listener = nil
    }
    
    // MARK: - Submit Score (Best Round Wins)
    // This updates ONE user entry doc.
    // If they already have a better score, we keep it.
    
    func submitScoreAllTime(courseID: String, entry: LeaderboardEntry, completion: @escaping (Bool) -> Void) {
        let docRef = allTimeEntriesRef(courseID: courseID).document(entry.userId)
        
        db.runTransaction({ tx, errPtr -> Any? in
            let snap: DocumentSnapshot
            do { snap = try tx.getDocument(docRef) }
            catch let e as NSError { errPtr?.pointee = e; return nil }
            
            let data = snap.data() ?? [:]
            let oldBest = data["totalStrokes"] as? Int ?? Int.max
            
            let newBest = min(oldBest, entry.totalStrokes)
            
            tx.setData([
                "id": entry.id,
                "userId": entry.userId,
                "name": entry.name,
                "photoURL": entry.photoURL as Any,
                "totalStrokes": newBest,
                "email": entry.email
            ], forDocument: docRef, merge: true)
            
            return nil
        }) { _, err in
            DispatchQueue.main.async { completion(err == nil) }
        }
    }
    
    func submitScoreWeekly(courseID: String, entry: LeaderboardEntry, completion: @escaping (Bool) -> Void) {
        
        let weekID = makeWeekID()
        
        let docRef = weeklyEntriesRef(courseID: courseID, weekID: weekID).document(entry.userId)
        
        db.runTransaction({ tx, errPtr -> Any? in
            let snap: DocumentSnapshot
            do { snap = try tx.getDocument(docRef) }
            catch let e as NSError { errPtr?.pointee = e; return nil }
            
            let data = snap.data() ?? [:]
            let oldBest = data["totalStrokes"] as? Int ?? Int.max
            
            let newBest = min(oldBest, entry.totalStrokes)
            
            tx.setData([
                "id": entry.id,
                "userId": entry.userId,
                "name": entry.name,
                "photoURL": entry.photoURL as Any,
                "totalStrokes": newBest,
                "email": entry.email
            ], forDocument: docRef, merge: true)
            
            return nil
        }) { _, err in
            DispatchQueue.main.async { completion(err == nil) }
        }
    }
    
    func sumbitScore(courseID: String, player: Player, completion: @escaping (Bool) -> Void) {
        
        let entry = player.toDTO().convertToLBREP()!
        
        submitScoreAllTime(courseID: courseID, entry: entry) { complete in
            if complete {
                self.submitScoreWeekly(courseID: courseID, entry: entry) { complete2 in
                    completion(complete2)
                }
            } else {
                completion(false)
            }
        }
        
        
    }
}

