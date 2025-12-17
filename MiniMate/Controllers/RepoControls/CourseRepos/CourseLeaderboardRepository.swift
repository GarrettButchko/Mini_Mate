//
//  CourseLeaderboardRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 11/24/25.
//

import Foundation
import FirebaseDatabase
import SwiftUI

/// Handles all Realtime Database operations for CourseLeaderboards
final class CourseLeaderboardRepository {
    
    private let dbRef = Database.database().reference().child("course_leaderboards")
    
    // MARK: - Add / Update CourseLeaderboard
    func addOrUpdateCourseLeaderboard(_ course: CourseLeaderboard, completion: @escaping (Bool) -> Void) {
        let ref = dbRef.child(course.id)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try JSONEncoder().encode(course)
                if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    ref.setValue(dict) { error, _ in
                        DispatchQueue.main.async {
                            completion(error == nil)
                        }
                    }
                }
            } catch {
                print("❌ Encoding course error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false) }
            }
        }
    }
    
    // MARK: - Fetch CourseLeaderboard
    func fetchCourseLeaderboard(id: String, completion: @escaping (CourseLeaderboard?) -> Void) {
        let ref = dbRef.child(id)
        ref.observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            do {
                guard let dict = value as? [String: Any] else {
                    print("CourseLeaderboard value is not a dictionary:", value)
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                let data = try JSONSerialization.data(withJSONObject: dict)
                let leaderboard = try JSONDecoder().decode(CourseLeaderboard.self, from: data)
                DispatchQueue.main.async { completion(leaderboard) }
            } catch {
                print("❌ Decoding CourseLeaderboard error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
    
    // MARK: - Add Player to Live Leaderboard
    func addPlayerToLiveLeaderboard(player: Player, courseID: String, email: String, max numberOfPlayers: Int, added: Binding<Bool>, courseRepository: CourseRepository, completion: @escaping (Bool) -> Void) {
        
        fetchCourseLeaderboard(id: courseID) { currentLeaderboard in
            var leaderboard = currentLeaderboard ?? CourseLeaderboard(id: courseID)
            
            // Add player and sort
            leaderboard.allPlayers.append(player.toDTO())
            leaderboard.allPlayers.sort { $0.totalStrokes < $1.totalStrokes }
            
            // Keep top N
            if leaderboard.allPlayers.count > numberOfPlayers {
                leaderboard.allPlayers = Array(leaderboard.allPlayers.prefix(numberOfPlayers))
            }
        }
    }
    
    // MARK: - Realtime Listening
    func listenForCourseUpdates(id: String, listenerHandle: inout DatabaseHandle?, onUpdate: @escaping (CourseLeaderboard?) -> Void) {
        let ref = dbRef.child(id)
        
        listenerHandle = ref.observe(.value) { snapshot in
            guard let value = snapshot.value, !(value is NSNull) else {
                print("⚠️ Snapshot value is nil or NSNull for id: \(id)")
                withAnimation { onUpdate(nil) }
                return
            }
            guard let dict = value as? [String: Any] else {
                print("⚠️ Snapshot value could not be cast to [String: Any]: \(value)")
                return
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: dict)
                let updatedCourse = try JSONDecoder().decode(CourseLeaderboard.self, from: data)
                withAnimation { onUpdate(updatedCourse) }
            } catch {
                print("❌ Failed to decode Course from snapshot: \(error.localizedDescription)")
            }
        }
    }
    
    func stopListening(id: String, listenerHandle: inout DatabaseHandle?) {
        let ref = dbRef.child(id)
        if let handle = listenerHandle {
            ref.removeObserver(withHandle: handle)
            listenerHandle = nil
        }
    }
}
