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
    
    func deleteCourseItem(courseID: String, dataName: String) {
        Firestore.firestore()
            .collection("courses")
            .document(courseID)
            .updateData([
                dataName: FieldValue.delete()
            ])
    }
    
    func setCourseItem(courseID: String, dataName: String, object: Any) {
        Firestore.firestore()
            .collection("courses")
            .document(courseID)
            .updateData([
                dataName: object
            ])
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
                password: PasswordGenerator.generate(.strong()),
                supported: false,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
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
    func removeEmail(email: String, courseID: String, completion: @escaping (Bool) -> Void) {
        let ref = db.collection(collectionName).document(courseID)
        let key = emailKey(email)

        // No transaction needed with map structure
        ref.updateData([
            "emails.\(key)": FieldValue.delete()
        ]) { error in
            if let error = error {
                print("❌ Failed to remove email: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func emailKey(_ email: String) -> String {
        email
            .lowercased()
            .replacingOccurrences(of: ".", with: ",")
    }

    func emailFromKey(_ key: String) -> String {
        key.replacingOccurrences(of: ",", with: ".")
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

    
    // MARK: - Check if email exists in course - Good for new DailyDoc
    func processPlayerEmailsForGame(
        emails: [String],
        courseID: String,
        completion: @escaping (Bool) -> Void
    ) {
        let courseRef = db.collection(collectionName).document(courseID)

        let uniqueEmails = Array(Set(
            emails
                .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        ))

        guard !uniqueEmails.isEmpty else {
            DispatchQueue.main.async { completion(true) }
            return
        }

        let todayID = makeDayID()
        let dayRef = courseRef.collection("dailyCount").document(todayID)

        db.runTransaction({ tx, errPtr -> Any? in

            // 1) READS
            var snapsByEmail: [(email: String, snap: DocumentSnapshot?)] = []
            snapsByEmail.reserveCapacity(uniqueEmails.count)

            for email in uniqueEmails {
                let emailRef = courseRef.collection("emails").document(self.emailKey(email))
                do {
                    let snap = try tx.getDocument(emailRef)
                    snapsByEmail.append((email: email, snap: snap))
                } catch let e as NSError {
                    errPtr?.pointee = e
                    return nil
                }
            }

            // 2) COMPUTE + WRITES
            var newCount = 0
            var returningCount = 0

            for entry in snapsByEmail {
                let emailRef = courseRef.collection("emails").document(self.emailKey(entry.email))

                if let snap = entry.snap, snap.exists {
                    let lastPlayed = (snap.get("lastPlayed") as? String) ?? ""
                    let firstSeen  = (snap.get("firstSeen") as? String) ?? lastPlayed
                    let playCount  = (snap.get("playCount") as? Int) ?? 0
                    let secondSeen = snap.get("secondSeen") as? String

                    // unique returners for the day
                    if lastPlayed != todayID {
                        returningCount += 1
                    }

                    var updates: [String: Any] = [
                        "firstSeen": firstSeen, // backfill if needed
                        "playCount": playCount + 1
                    ]

                    // update last/previous only if new day (keeps "previousPlayed" meaningful)
                    if lastPlayed != todayID {
                        updates["previousPlayed"] = lastPlayed.isEmpty ? todayID : lastPlayed
                        updates["lastPlayed"] = todayID
                    }

                    // set secondSeen exactly once: on 2nd ever play
                    if playCount == 1 && secondSeen == nil {
                        updates["secondSeen"] = todayID
                    }

                    tx.setData(updates, forDocument: emailRef, merge: true)

                } else {
                    newCount += 1
                    tx.setData([
                        "firstSeen": todayID,
                        "lastPlayed": todayID,
                        "playCount": 1
                    ], forDocument: emailRef, merge: true)
                }
            }

            var dayUpdates: [String: Any] = [
                "dayID": todayID,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            if newCount > 0 { dayUpdates["newPlayers"] = FieldValue.increment(Int64(newCount)) }
            if returningCount > 0 { dayUpdates["returningPlayers"] = FieldValue.increment(Int64(returningCount)) }

            tx.setData(dayUpdates, forDocument: dayRef, merge: true)

            return true
        }) { _, error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    print("❌ processPlayerEmailsForGame failed:",
                          "code=\(error.code)",
                          "domain=\(error.domain)",
                          "msg=\(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }


    // MARK: Daily Counts
    enum DailyMetric: String {
        case activeUsers
        case gamesPlayed
        case newPlayers
        case returningPlayers
    }
    
    
    
    func updateDayAnalytics(
        courseID: String,
        game: Game,
        startTime: Date,
        endTime: Date,
        increment: Int = 1,
        completion: @escaping (Bool) -> Void
    ) {

        // Use YOUR current convention for dailyCounts: Sunday=0..Saturday=6
        let hour = Calendar.current.component(.hour, from: startTime)

        // Weekly doc reference (subcollection under the course)
        let weekRef = db.collection(collectionName)
            .document(courseID)
            .collection("dailyDocs")
            .document(makeDayID(from: startTime))

        let roundLengthSeconds = max(0, Int(endTime.timeIntervalSince(startTime)))

        db.runTransaction({ transaction, errorPointer -> Any? in
            let snap: DocumentSnapshot
            do {
                snap = try transaction.getDocument(weekRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            let data = snap.data() ?? [:]

            // -------------------------
            // 1) Peak analytics
            // -------------------------
            var hourly = peak["hourlyCounts"] as? [Int] ?? Array(repeating: 0, count: 24)

            if hourly.count != 24 { hourly = Array(repeating: 0, count: 24) }
            

            if hour >= 0 && hour < 24 { hourly[hour] += increment }
            if weekday >= 0 && weekday < 7 { daily[weekday] += increment }

            let updatedPeak: [String: Any] = [
                "hourlyCounts": hourly,
                "dailyCounts": daily
            ]
            
            let hourlyCounts: ["hourlyCounts": [String: Int] = [

            // -------------------------
            // 2) Hole analytics
            // -------------------------
            let hole = data["holeAnalytics"] as? [String: Any] ?? [:]

            let holesCount = game.numberOfHoles
            var totalStrokes = hole["totalStrokesPerHole"] as? [Int] ?? Array(repeating: 0, count: holesCount)
            var playsPerHole = hole["playsPerHole"] as? [Int] ?? Array(repeating: 0, count: holesCount)

            if totalStrokes.count != holesCount { totalStrokes = Array(repeating: 0, count: holesCount) }
            if playsPerHole.count != holesCount { playsPerHole = Array(repeating: 0, count: holesCount) }

            for player in game.players {
                for h in player.holes {
                    guard h.strokes != 0 else { continue }
                    let idx = h.number - 1
                    guard idx >= 0 && idx < holesCount else { continue }

                    totalStrokes[idx] += h.strokes
                    playsPerHole[idx] += increment
                }
            }

            let updatedHole: [String: Any] = [
                "totalStrokesPerHole": totalStrokes,
                "playsPerHole": playsPerHole
            ]

            // -------------------------
            // 3) Round time analytics
            // -------------------------
            let roundTime = data["roundTimeAnalytics"] as? [String: Any] ?? [:]
            let existingSeconds = roundTime["totalRoundSeconds"] as? Int ?? 0

            let updatedRoundTime: [String: Any] = [
                "totalRoundSeconds": existingSeconds + roundLengthSeconds
            ]

            // -------------------------
            // 4) Write back to weekly doc
            // -------------------------
            transaction.setData([
                "weekID": weekKey,
                "peakAnalytics": updatedPeak,
                "holeAnalytics": updatedHole,
                "roundTimeAnalytics": updatedRoundTime,
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: weekRef, merge: true)

            return nil
        }) { _, error in
            if let error = error {
                print("❌ updateWeeklyAnalytics failed: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ Weekly analytics updated: \(weekKey)")
                completion(true)
            }
        }
    }
    
    // MARK: - Unified Daily Metric Updater
    func updateDailyMetric(
        courseID: String,
        metric: DailyMetric,
        increment: Int = 1,
        completion: @escaping (Bool) -> Void
    ) {
        let dayKey = makeDayID(from: Date())

        let dayRef = db.collection(collectionName)
            .document(courseID)
            .collection("dailyCount")
            .document(dayKey)

        let key = metric.rawValue

        dayRef.setData(
            [
                "dayID": dayKey,
                "updatedAt": FieldValue.serverTimestamp(),
                key: FieldValue.increment(Int64(increment))
            ],
            merge: true
        ) { error in
            if let error = error {
                print("❌ Daily metric update failed: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ Daily metric updated: \(key)")
                completion(true)
            }
        }
    }


    
    func updateGameCount(courseID: String, increment: Int = 1, completion: @escaping (Bool) -> Void) {
        updateDailyMetric(courseID: courseID, metric: .gamesPlayed, increment: increment){ complete in
            completion(complete)
        }
    }
    
    //func updateNewPlayers(courseID: String, increment: Int = 1) {
      //  updateDailyMetric(courseID: courseID, metric: .newPlayers, increment: increment)
    //}
    
    //func updateReturningPlayers(courseID: String, increment: Int = 1) {
      //  updateDailyMetric(courseID: courseID, metric: .returningPlayers, increment: increment)
    //}
    
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

func makeWeekID(from date: Date = Date()) -> String {
    var calendar = Calendar(identifier: .iso8601)
    calendar.firstWeekday = 2 // Monday
    
    let weekOfYear = calendar.component(.weekOfYear, from: date)
    let yearForWeek = calendar.component(.yearForWeekOfYear, from: date)
    
    return String(format: "%d-W%02d", yearForWeek, weekOfYear)
}

func makeDayID(from date: Date = Date()) -> String {
    var calendar = Calendar(identifier: .iso8601)
    calendar.timeZone = TimeZone.current

    let year  = calendar.component(.year, from: date)
    let month = calendar.component(.month, from: date)
    let day   = calendar.component(.day, from: date)

    return String(format: "%04d-%02d-%02d", year, month, day)
}
