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
    func createCourseWithMapItem(courseID: String, location: MapItemDTO, completion: @escaping (Course?) -> Void) {
        let ref = db.collection(collectionName).document(courseID)
        
        ref.getDocument { snapshot, error in
            if let error = error {
                print("❌ Firestore fetch error: \(error)")
                completion(nil)
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
                completion(newCourse)
            } catch {
                print("❌ Firestore write error: \(error)")
                completion(nil)
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

    
    // MARK: - Update Day Analytics
    func updateDayAnalytics(
        emails: [String],
        courseID: String,
        game: Game, // Ensure your Game model has 'players' and 'holes'
        startTime: Date,
        endTime: Date,
        completion: @escaping (Bool) -> Void
    ) {
        
        print("Running updateDayAnalytics")
        let updatedAt = Date()
        let todayID = makeDayID()
        let currentHour = Calendar.current.component(.hour, from: updatedAt)
        
        let courseRef = db.collection(collectionName).document(courseID)
        let dayRef = courseRef.collection("dailyDocs").document(todayID)
        let emailRef = courseRef.collection("emails")
        
        let uniqueEmails = Array(Set(
            emails
                .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        ))
        
        guard !uniqueEmails.isEmpty else {
            print("Empty Emails")
            DispatchQueue.main.async { completion(true) }
            return
        }
        
        db.runTransaction({ tx, errPtr -> Any? in
            // --- 1. READ PHASE ---
            var emailSnapshots: [String: DocumentSnapshot] = [:]
            var resultDay: DailyDoc? = nil
            
            do {
                for email in uniqueEmails {
                    let docRef = emailRef.document(self.emailKey(email))
                    emailSnapshots[email] = try tx.getDocument(docRef)
                }
                let daySnap = try tx.getDocument(dayRef)
                if daySnap.exists {
                    resultDay = try daySnap.data(as: DailyDoc.self)
                }
            } catch let err as NSError {
                errPtr?.pointee = err
                return nil
            }
            
            // --- 2. LOGIC PHASE (No tx calls here) ---
            var newCount = 0
            var returningCount = 0
            var emailUpdates: [(DocumentReference, CourseEmail)] = []
            
            for email in uniqueEmails {
                let docRef = emailRef.document(self.emailKey(email))
                let snap = emailSnapshots[email]
                
                if let snap = snap, snap.exists, let data = try? snap.data(as: CourseEmail.self) {
                    var lastPlayed = data.lastPlayed ?? todayID
                    var secondSeen = data.secondSeen
                    let playCount = data.playCount
                    
                    if lastPlayed != todayID {
                        returningCount += 1
                        lastPlayed = todayID
                    }
                    if playCount == 1 && secondSeen == nil {
                        secondSeen = todayID
                    }
                    
                    let updated = CourseEmail(firstSeen: data.firstSeen ?? todayID, secondSeen: secondSeen, lastPlayed: lastPlayed, playCount: playCount + 1)
                    emailUpdates.append((docRef, updated))
                } else {
                    newCount += 1
                    let updated = CourseEmail(firstSeen: todayID, secondSeen: nil, lastPlayed: todayID, playCount: 1)
                    emailUpdates.append((docRef, updated))
                }
            }
            
            // Analytics calculations
            let roundLengthSeconds = max(0, Int(endTime.timeIntervalSince(startTime)))
            var totalStrokes = resultDay?.holeAnalytics.totalStrokesPerHole ?? [:]
            var playsPerHole = resultDay?.holeAnalytics.playsPerHole ?? [:]
            var hourlyCounts = resultDay?.hourlyCounts ?? [:]
            
            for player in game.players {
                for h in player.holes {
                    guard h.strokes != 0 else { continue }
                    let key = String(h.number)
                    totalStrokes[key, default: 0] += h.strokes
                    playsPerHole[key, default: 0] += 1
                }
            }
            hourlyCounts[String(currentHour), default: 0] += 1
            
            let finalDailyDoc = DailyDoc(
                dayID: todayID,
                totalRoundSeconds: (resultDay?.totalRoundSeconds ?? 0) + Int64(roundLengthSeconds),
                gamesPlayed: (resultDay?.gamesPlayed ?? 0) + 1,
                newPlayers: (resultDay?.newPlayers ?? 0) + newCount,
                returningPlayers: (resultDay?.returningPlayers ?? 0) + returningCount,
                holeAnalytics: HoleAnalytics(totalStrokesPerHole: totalStrokes, playsPerHole: playsPerHole),
                hourlyCounts: hourlyCounts,
                updatedAt: updatedAt
            )
            
            // --- 3. WRITE PHASE (All at the very end) ---
            do {
                for (ref, obj) in emailUpdates {
                    try tx.setData(from: obj, forDocument: ref, merge: true)
                }
                try tx.setData(from: finalDailyDoc, forDocument: dayRef, merge: true)
            } catch let err as NSError {
                errPtr?.pointee = err
                return nil
            }
            
            return true
        }) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ updateDayAnalytics failed: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
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
