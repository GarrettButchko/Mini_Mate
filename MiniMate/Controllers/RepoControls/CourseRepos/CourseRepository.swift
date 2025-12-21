//
//  RemoteCourseRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 11/24/25.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import Combine

final class CourseRepository {
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    let collectionName: String = "courses"
    
    
    // MARK: General Course
    func addOrUpdateCourse(_ course: Course, completion: @escaping (Bool) -> Void) {
        let ref = db.collection(collectionName).document(course.id)
        
        do {
            try ref.setData(from: course, merge: true) { error in
                completion(error == nil)
            }
        } catch {
            print("❌ Firestore encoding error: \(error)")
            completion(false)
        }
    }
    
    
    
    func listenToCourse(
        id: String,
        onUpdate: @escaping (Course?) -> Void
    ) {
        stopListening()
        
        listener = db.collection("courses")
            .document(id)
            .addSnapshotListener { snapshot, error in
                
                if let error = error {
                    print("❌ Listener error:", error)
                    onUpdate(nil)
                    return
                }
                
                guard let snapshot, snapshot.exists else {
                    onUpdate(nil)
                    return
                }
                
                do {
                    let course = try snapshot.data(as: Course.self)
                    DispatchQueue.main.async {
                        onUpdate(course)
                    }
                } catch {
                    print("❌ Decode error:", error)
                }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    /// Fetches a Course by ID from Firestore
    func fetchCourse(id: String, completion: @escaping (Course?) -> Void) {
        let ref = db.collection(collectionName).document(id)
        
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
            
            // Decode the document directly into your Course model on the main actor
            Task { @MainActor in
                do {
                    let course = try snapshot.data(as: Course.self)
                    completion(course)
                } catch {
                    print("❌ Firestore decoding error: \(error)")
                    completion(nil)
                }
            }
        }
    }
    
    /// Fetches multiple Courses by their document IDs
    func fetchCourses(ids: [String], completion: @escaping ([Course]) -> Void) {
        guard !ids.isEmpty else {
            completion([])
            return
        }

        let group = DispatchGroup()
        let resultsQueue = DispatchQueue(label: "CourseRepository.fetchCourses.resultsQueue")
        var results: [String: Course] = [:]

        for id in ids {
            group.enter()

            let ref = db.collection(collectionName).document(id)
            ref.getDocument { snapshot, error in
                defer { group.leave() }

                guard
                    error == nil,
                    let snapshot,
                    snapshot.exists
                else {
                    return
                }

                Task { @MainActor in
                    do {
                        let course = try snapshot.data(as: Course.self)
                        resultsQueue.sync {
                            results[id] = course
                        }
                    } catch {
                        // Ignore decoding failures for this document
                    }
                }
            }
        }

        group.notify(queue: .main) {
            // Preserve original order of IDs
            let orderedCourses = ids.compactMap { results[$0] }
            completion(orderedCourses)
        }
    }
    
    func fetchCourseByName(_ name: String, completion: @escaping (Course?) -> Void) {
        db.collection(collectionName)
            .whereField("name", isEqualTo: name)
            .limit(to: 1)   // just in case multiple exist
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Firestore query error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    completion(nil)
                    return
                }
                
                Task { @MainActor in
                    do {
                        let course = try document.data(as: Course.self)
                        completion(course)
                    } catch {
                        print("❌ Firestore decoding error: \(error)")
                        completion(nil)
                    }
                }
            }
    }
    
    func courseNameExistsAndSupported(_ name: String, completion: @escaping (Bool) -> Void) {
        db.collection(collectionName)
            .whereField("name", isEqualTo: name)
            .whereField("supported", isEqualTo: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Firestore query error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                let exists = snapshot?.documents.isEmpty == false
                completion(exists)
            }
    }

    #if MINIMATE
    func createCourseWithMapItem(location: MapItemDTO, completion: @escaping (Bool) -> Void) {
        let courseID = CourseIDGenerator.generateCourseID(from: location)
        let ref = db.collection(collectionName).document(courseID)
        
        ref.getDocument { snapshot, error in
            if let error = error {
                print("❌ Firestore fetch error: \(error)")
                completion(false)
                return
            }
            
            // Create new course
            let newCourse = Course(
                id: courseID,
                name: location.name ?? "N/A",
                supported: false,
                password: PasswordGenerator.generate(.strong())
            )
            
            do {
                try ref.setData(from: newCourse)
                print("Created new course: \(courseID)")
                completion(true)
            } catch {
                print("❌ Firestore write error: \(error)")
                completion(false)
            }
        }
    }
    #endif

    
    func findCourseIDWithPassword(withPassword password: String, completion: @escaping (String?) -> Void) {
        db.collection(collectionName)
            .whereField("password", isEqualTo: password)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Firestore query error: \(error)")
                    completion(nil)
                    return
                }
                
                guard let doc = snapshot?.documents.first else {
                    completion(nil)   // No course has this password
                    return
                }
                
                completion(doc.documentID)
            }
    }
    
    func fetchCourseIDs(prefix: String, completion: @escaping ([SmallCourse]) -> Void) {
        let end = prefix + "\u{f8ff}"
        db.collection(collectionName)
            .whereField(FieldPath.documentID(), isGreaterThanOrEqualTo: prefix)
            .whereField(FieldPath.documentID(), isLessThanOrEqualTo: end)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                
                guard let docs = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let courses: [SmallCourse] = docs.map { doc in
                    let name = doc["name"] as? String ?? "Unnamed"
                    return SmallCourse(id: doc.documentID, name: name)
                }
                
                completion(courses)
            }
    }
    
    // MARK: Email
    func addEmail(newEmail: String, courseID: String, completion: @escaping (Bool) -> Void) {
        let ref = db.collection(collectionName).document(courseID)

        ref.updateData([
            "emails": FieldValue.arrayUnion([newEmail])
        ]) { error in
            if let error = error {
                print("❌ Failed to add email: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func removeEmail(email: String, courseID: String, completion: @escaping (Bool) -> Void) {
        db.collection(collectionName)
            .document(courseID)
            .updateData([
                "emails": FieldValue.arrayRemove([email])
            ]) { error in
                completion(error == nil)
            }
    }
    
    // MARK: Admin Id
    func addAdminIDtoCourse(adminID: String, courseID: String, completion: @escaping (Bool) -> Void) {
        let ref = db.collection(collectionName).document(courseID)

        ref.updateData([
            "adminIDs": FieldValue.arrayUnion([adminID])
        ]) { error in
            if let error = error {
                print("❌ Failed to add email: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    func removAdminIDfromCourse(email: String, courseID: String, completion: @escaping (Bool) -> Void) {
        db.collection(collectionName)
            .document(courseID)
            .updateData([
                "adminIDs": FieldValue.arrayRemove([email])
            ]) { error in
                completion(error == nil)
            }
    }
    
    
    func keepOnlyAdminID(id: String, courseID: String, completion: @escaping (Bool) -> Void) {
        let docRef = db.collection(collectionName).document(courseID)
        
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                completion(false)
                return
            }
            
            // Get current adminIDs array
            let adminIDs = data["adminIDs"] as? [String] ?? []
            
            // Keep only the one you want
            let updatedAdminIDs = adminIDs.contains(id) ? [id] : []
            
            // Update the document
            docRef.updateData([
                "adminIDs": updatedAdminIDs
            ]) { error in
                completion(error == nil)
            }
        }
    }

    
    // MARK: - Check if email exists in course
    func isEmailInCourse(email: String, courseID: String, completion: @escaping (Bool) -> Void) {
        let ref = db.collection(collectionName).document(courseID)
        
        ref.getDocument { snapshot, error in
            if let error = error {
                print("❌ Fetch error: \(error)")
                completion(false)
                return
            }
            
            guard let data = snapshot?.data() else {
                // Document doesn't exist → email not present
                completion(false)
                return
            }
            
            let emails = data["emails"] as? [String] ?? []
            completion(emails.contains(email))
        }
    }

    
    // MARK: Daily Counts
    enum DailyMetric: String {
        case activeUsers
        case gamesPlayed
        case newPlayers
        case returningPlayers
    }
    
    // MARK: - Unified Daily Metric Updater
    func updateDailyMetric(courseID: String, metric: DailyMetric, increment: Int = 1) {
        let ref = db.collection(collectionName).document(courseID)

        // Correct date format (calendar year)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        let todayID = formatter.string(from: Date())

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(ref)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            // Load full data
            var data = snapshot.data() ?? [:]

            // Load nested map
            var dailyCounts = data["dailyCount"] as? [String: [String: Int]] ?? [:]

            // Build today's entry or load existing
            var todayEntry = dailyCounts[todayID] ?? [
                "activeUsers": 0,
                "gamesPlayed": 0,
                "newPlayers": 0,
                "returningPlayers": 0
            ]

            // Increment the metric
            let key = metric.rawValue
            todayEntry[key, default: 0] += increment

            // Store back into main dictionary
            dailyCounts[todayID] = todayEntry
            data["dailyCount"] = dailyCounts

            // Write through transaction
            transaction.updateData(["dailyCount": dailyCounts], forDocument: ref)

            return nil
        }) { (_, error) in
            if let error = error {
                print("❌ Transaction failed: \(error.localizedDescription)")
            } else {
                print("✅ Metric updated safely in transaction: \(metric.rawValue)")
            }
        }
    }
    
    func updateDailyCount(courseID: String, increment: Int = 1) {
        updateDailyMetric(courseID: courseID, metric: .activeUsers, increment: increment)
    }
    
    func updateGameCount(courseID: String, increment: Int = 1) {
        updateDailyMetric(courseID: courseID, metric: .gamesPlayed, increment: increment)
    }
    
    func updateNewPlayers(courseID: String, increment: Int = 1) {
        updateDailyMetric(courseID: courseID, metric: .newPlayers, increment: increment)
    }
    
    func updateReturningPlayers(courseID: String, increment: Int = 1) {
        updateDailyMetric(courseID: courseID, metric: .returningPlayers, increment: increment)
    }
    
    // MARK: Peak Analytics
    func incPeakAnalytics(courseID: String, increment: Int = 1) {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let weekday = Calendar.current.component(.weekday, from: now) - 1 // Sunday = 0

        let docRef = db.collection(collectionName).document(courseID)

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(docRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            // ===============================
            // 1. Load existing data
            // ===============================
            let data = snapshot.data() ?? [:]
            let peak = data["peakAnalytics"] as? [String: Any] ?? [:]

            // Load arrays or initialize
            var hourly = peak["hourlyCounts"] as? [Int] ?? Array(repeating: 0, count: 24)
            var daily  = peak["dailyCounts"]  as? [Int] ?? Array(repeating: 0, count: 7)

            // Ensure correct lengths
            if hourly.count != 24 { hourly = Array(repeating: 0, count: 24) }
            if daily.count  != 7  { daily  = Array(repeating: 0, count: 7) }

            // ===============================
            // 2. Increment values
            // ===============================
            hourly[hour] += increment
            daily[weekday] += increment

            // ===============================
            // 3. Rebuild nested object
            // ===============================
            let updatedPeak: [String: Any] = [
                "hourlyCounts": hourly,
                "dailyCounts": daily
            ]

            // ===============================
            // 4. Write full object back atomically
            // ===============================
            transaction.updateData(
                ["peakAnalytics": updatedPeak],
                forDocument: docRef
            )

            return nil
        }) { (_, error) in
            if let error = error {
                print("❌ PeakAnalytics transaction failed: \(error.localizedDescription)")
            } else {
                print("📈 PeakAnalytics increment successful (hour \(hour), weekday \(weekday))")
            }
        }
    }

    // MARK: Hole Analytics
    func addToHoleAnalytics(courseID: String, game: Game, increment: Int = 1) {
        let docRef = db.collection(collectionName).document(courseID)

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let snap: DocumentSnapshot
            do {
                snap = try transaction.getDocument(docRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            // Load existing analytics or create empty structure
            let data = snap.data() ?? [:]
            let existing = data["holeAnalytics"] as? [String: Any] ?? [:]

            var totalStrokes = existing["totalStrokesPerHole"] as? [Int]
                ?? Array(repeating: 0, count: game.numberOfHoles)

            var playsPerHole = existing["playsPerHole"] as? [Int]
                ?? Array(repeating: 0, count: game.numberOfHoles)

            // Ensure array lengths match the course hole count
            if totalStrokes.count != game.numberOfHoles {
                totalStrokes = Array(repeating: 0, count: game.numberOfHoles)
            }
            if playsPerHole.count != game.numberOfHoles {
                playsPerHole = Array(repeating: 0, count: game.numberOfHoles)
            }

            // ===============================
            // Increment analytics for each hole played
            // ===============================
            for player in game.players {
                for hole in player.holes {
                    guard hole.strokes != 0 else { continue }

                    let index = hole.number - 1
                    guard index >= 0, index < game.numberOfHoles else { continue }

                    totalStrokes[index] += hole.strokes
                    playsPerHole[index] += increment
                }
            }

            let updatedHole: [String: Any] = [
                "totalStrokesPerHole": totalStrokes,
                "playsPerHole": playsPerHole
            ]

            // Atomic write
            transaction.updateData(["holeAnalytics": updatedHole], forDocument: docRef)
            return nil

        }) { (_, error) in
            if let error = error {
                print("❌ HoleAnalytics transaction failed: \(error.localizedDescription)")
            } else {
                print("⛳️ HoleAnalytics updated successfully for game \(game.id)")
            }
        }
    }

    
    func addRoundTime(courseID: String, startTime: Date, endTime: Date) {
        let docRef = db.collection(collectionName).document(courseID)

        let roundLengthSeconds = Int(endTime.timeIntervalSince(startTime))

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let snap: DocumentSnapshot
            do {
                snap = try transaction.getDocument(docRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            let data = snap.data() ?? [:]
            let roundTime = data["roundTimeAnalytics"] as? [String: Any] ?? [:]

            let existingSeconds = roundTime["totalRoundSeconds"] as? Int ?? 0

            let updatedRoundTime: [String: Any] = [
                "totalRoundSeconds": existingSeconds + roundLengthSeconds
            ]

            transaction.updateData(
                ["roundTimeAnalytics": updatedRoundTime],
                forDocument: docRef
            )

            return nil
        }) { (_, error) in
            if let error = error {
                print("❌ roundTime transaction failed: \(error.localizedDescription)")
            } else {
                print("⏱️ Successfully added \(roundLengthSeconds)s to roundTimeAnalytics")
            }
        }
    }
    
    func uploadCourseImages(id: String, _ image: UIImage, key: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let data = image.pngData() else {
            return completion(.failure(NSError(
                domain: "AuthViewModel",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Image conversion failed"]
            )))
        }
        
        let ref = Storage.storage()
            .reference()
            .child(id)
            .child("\(key).png")
        
        // 1️⃣ upload
        ref.putData(data, metadata: nil) { meta, error in
            if let error = error {
                return completion(.failure(error))
            }
            // 2️⃣ get download URL
            ref.downloadURL { result in
                switch result {
                case .failure(let error):
                    return completion(.failure(error))
                case .success(let url):
                    // 3️⃣ update Firebase Auth
                    completion(.success(url))
                }
            }
        }
    }
}

struct SmallCourse: Identifiable {
    let id: String
    let name: String
}
