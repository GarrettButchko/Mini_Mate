//
//  UserRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/4/25.
//
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import SwiftData

final class UserRepository {
    
    @Published var firebaseUser: FirebaseAuth.User?
    
    let context: ModelContext?
    
    init(context: ModelContext? = nil) {
        self.context = context
    }
    
    func loadOrCreateUser(
        id: String,
        firebaseUser: User? = nil,
        name: String? = nil,
        completion: @escaping(UserModel) -> Void
    ) {
        // 1️⃣ Fetch Local First
        let local = fetchLocal(id: id)
        
        // 2️⃣ Fetch Remote
        fetchRemote(id: id) { remote in
            
            // CASE A: Remote exists
            if let remote = remote {
                
                // CASE A1: Local exists
                if let local = local {
                    
                    // ⚠️ They differ → update remote with the local version
                    if local.lastUpdated < remote.lastUpdated {
                        // Remote is newer → update local
                        self.saveLocal(context: self.context!, model: remote) { _ in
                            print("🔄 Synced: Remote → Local (remote newer)")
                        }
                        completion(remote)
                        return
                    }

                    if local.lastUpdated > remote.lastUpdated {
                        // Local is newer → update remote
                        self.saveRemote(id: id, userModel: local) { _ in
                            print("🔄 Synced: Local → Remote (local newer)")
                        }
                        completion(local)
                        return
                    }
                    
                    // Local is authoritative; return it
                    completion(local)
                    return
                }
                
                // CASE A2: No local exists → save remote locally
                self.saveLocal(context: self.context!, model: remote) { _ in }
                completion(remote)
                return
            }
            
            
            // CASE B: Remote does not exist
            // CASE B1: Local exists → push it to remote
            if let local = local {
                self.saveRemote(id: id, userModel: local) { _ in
                    print("☁️ Uploaded local → remote (remote didn't exist)")
                }
                completion(local)
                return
            }
            
            
            // CASE B2: No local AND no remote → create new
            let userModel = self.createUser(id: id, firebaseUser: firebaseUser, name: name)
            self.saveLocal(context: self.context!, model: userModel) { _ in }
            self.saveRemote(id: id, userModel: userModel) { _ in }
            completion(userModel)
        }
    }

    
    func createUser(id: String, firebaseUser: User?, name: String?) -> UserModel {
        
        let finalName  = name ?? firebaseUser?.displayName ?? "Error"
        let finalEmail = firebaseUser?.email ?? "Error"
        
        return UserModel(
                            id: id,
                            name: finalName,
                            photoURL: firebaseUser?.photoURL,
                            email: finalEmail,
                            gameIDs: []
                        )
    }
    
    
    func updateDisplayName(to newName: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "Auth", code: -1,
                               userInfo: [NSLocalizedDescriptionKey: "No signed-in user"]))
            return
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = newName
        changeRequest.commitChanges { error in
            if let error = error {
                print("❌ Failed to update displayName:", error)
            } else {
                print("✅ displayName updated to:", newName)
            }
            completion(error)
        }
    }
    
    func saveUnified(id: String, userModel: UserModel, completion: @escaping (Bool, Bool) -> Void) {
        var localSuccess: Bool?
        var remoteSuccess: Bool?
        
        func returnIfDone() {
            if let local = localSuccess, let remote = remoteSuccess {
                completion(local, remote)
            }
        }
        
        saveLocal(context: context!, model: userModel) { success in
            localSuccess = success
            returnIfDone()
        }
        
        saveRemote(id: id, userModel: userModel) { success in
            remoteSuccess = success
            returnIfDone()
        }
    }

    
    
    func saveRemote(id: String, userModel: UserModel, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let ref = db.collection("users").document(id)
        
        let updatedUser = userModel
            updatedUser.lastUpdated = Date()
        
        do {
            // Firestore will merge if document exists
            try ref.setData(from: updatedUser.toDTO(), merge: true) { error in
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
    
    func fetchRemote(id: String, completion: @escaping (UserModel?) -> Void) {
        let db = Firestore.firestore()
        let ref = db.collection("users").document(id)
        
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
            
            do {
                // Decode directly from Firestore document
                let dto = try snapshot.data(as: UserDTO.self)
                let model = UserModel.fromDTO(dto)
                completion(model)
            } catch {
                print("❌ Firestore decoding error: \(error)")
                completion(nil)
            }
        }
    }
    
    func saveLocal(context: ModelContext, model: UserModel, completion: @escaping (Bool) -> Void) {
        model.lastUpdated = Date()
        do {
            context.insert(model)   // insert or update
            try context.save()
            print("📦 Local save successful")
            completion(true)
        } catch {
            print("❌ Local save error: \(error)")
            completion(false)
        }
    }

    
    func fetchLocal(id: String) -> UserModel? {
        let descriptor = FetchDescriptor<UserModel>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            return try context!.fetch(descriptor).first
        } catch {
            print("❌ Local fetch error: \(error)")
            return nil
        }
    }
    
    func deleteLocal(id: String, completion: @escaping (Bool) -> Void) {
        let descriptor = FetchDescriptor<UserModel>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            if let user = try context!.fetch(descriptor).first {
                context!.delete(user)
                try context!.save()
                print("🗑️ Local delete successful for id: \(id)")
                completion(true)
            } else {
                print("⚠️ No local user found with id: \(id)")
                completion(true)
            }
        } catch {
            print("❌ Local delete error: \(error)")
            completion(false)
        }
    }
    
    func deleteRemote(id: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let ref = db.collection("users").document(id)
        
        ref.delete { error in
            if let error = error {
                print("❌ Firestore delete error: \(error.localizedDescription)")
                completion(false)
            } else {
                print("🗑️ Firestore user doc deleted")
                completion(true)
            }
        }
    }
    
    func deleteUnified(id: String, completion: @escaping (Bool, Bool) -> Void) {
        var localSuccess: Bool?
        var remoteSuccess: Bool?
        
        func returnIfDone() {
            if let local = localSuccess, let remote = remoteSuccess {
                completion(local, remote)
            }
        }
        
        deleteLocal(id: id) { success in
            localSuccess = success
            returnIfDone()
        }
        
        deleteRemote(id: id) { success in
            remoteSuccess = success
            returnIfDone()
        }
    }

    
    func uploadProfilePhoto(
        id: String,
        _ image: UIImage,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let user = firebaseUser else {
            return completion(.failure(NSError(
                domain: "AuthViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No signed-in user"]
            )))
        }
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return completion(.failure(NSError(
                domain: "AuthViewModel",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Image conversion failed"]
            )))
        }
        
        let ref = Storage.storage()
            .reference()
            .child("profile_pictures")
            .child("\(id).jpg")
        
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
                    let changeReq = user.createProfileChangeRequest()
                    changeReq.photoURL = url
                    changeReq.commitChanges { err in
                        if let err = err {
                            print("⚠️ Failed to set Auth photoURL:", err)
                            // we'll still proceed to save to DB though
                        }
                        
                        let local = self.fetchLocal(id: id)
                        
                        // 4️⃣ Update your UserModel and Realtime DB
                        DispatchQueue.main.async {
                            // update SwiftData model
                            
                            local?.photoURL = url
                            local?.lastUpdated = Date()
                            
                            if let userModel = local {
                                self.saveUnified(id: id, userModel: userModel) { localOK, remoteOK in
                                    if localOK && remoteOK {
                                        print("Saved Photo Everywhere")
                                    } else if localOK {
                                        print("Saved locally only")
                                    } else if remoteOK {
                                        print("Saved remotely only")
                                    } else {
                                        print("Failed everywhere")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
