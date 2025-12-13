//
//  LocFuncs.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/16/25.
//

import SwiftUI
import SwiftData
import Foundation

/// A utility struct for managing local SwiftData operations
struct LocFuncs {
    
    /// Fetches a UserModel from SwiftData using its unique string ID
    /// - Parameters:
    ///   - id: The user ID (usually matches Firebase UID)
    ///   - context: The SwiftData `ModelContext` used to query the store
    /// - Returns: The matching `UserModel` if found, otherwise `nil`
    func fetchUser(by id: String, context: ModelContext) -> UserModel? {
        let predicate = #Predicate<UserModel> { $0.id == id } // ✅ uses stored id
        let descriptor = FetchDescriptor<UserModel>(predicate: predicate)

        do {
            return try context.fetch(descriptor).first
        } catch {
            print("❌ Fetch failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Deletes the local SwiftData SQLite store (dev use only)
    /// Deletes everything in the SwiftData store (SQLite + wal/shm files) and clears UserDefaults.
    func clearSwiftDataStore() {
        let fm = FileManager.default

        // 1. Locate Application Support/<YourBundleID> directory
        guard let appSupport = fm.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
              ).first else {
            print("❌ Couldn't find Application Support directory")
            return
        }
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let storeFolder = appSupport.appendingPathComponent(bundleID)

        // 2. Remove the three SQLite files
        ["default.store", "default.store-wal", "default.store-shm"].forEach { filename in
            let fileURL = storeFolder.appendingPathComponent(filename)
            if fm.fileExists(atPath: fileURL.path) {
                do {
                    try fm.removeItem(at: fileURL)
                    print("🗑️ Deleted \(filename)")
                } catch {
                    print("❌ Failed to delete \(filename): \(error)")
                }
            }
        }

        // 3. (Optional) Wipe UserDefaults so you don’t pick up any orphaned settings
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            print("🗑️ Cleared UserDefaults for \(domain)")
        }
    }
}
