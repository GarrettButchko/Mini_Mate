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
        authModel: AuthViewModel,
        completion: @escaping () -> Void
    ) {
        let local = fetchLocal(id: id)

        // 1️⃣ Immediate local phase
        if let local {
            DispatchQueue.main.async {
                print("✅ Found local user immediately")
                authModel.setUserModel(local)
                completion()   // ✅ local done, reconcile not done
            }
        }

        // 2️⃣ Background reconcile phase
        fetchRemote(id: id) { remote in
            self.reconcile(
                local: local,
                remote: remote,
                id: id,
                firebaseUser: firebaseUser,
                name: name,
                authModel: authModel
            ) {
                completion() // ✅ reconcile finished
            }
        }
    }

    private func reconcile(
        local: UserModel?,
        remote: UserModel?,
        id: String,
        firebaseUser: User?,
        name: String?,
        authModel: AuthViewModel,
        completion: @escaping() -> Void
    ) {
        switch (local, remote) {

        case let (local?, remote?):
            
            let delta = abs(local.lastUpdated.timeIntervalSince(remote.lastUpdated))
            
            
            if delta < 0.5 {
                print("🔄 Already in sync")
                completion()
            } else if local.lastUpdated > remote.lastUpdated {
                
                print("\(local.lastUpdated) > \(remote.lastUpdated)")
                
                saveRemote(id: id, userModel: local, updateLastUpdated: false) { _ in
                    print("🔄 Local → Remote")
                    completion()
                }
            } else {
                print("\(local.lastUpdated) < \(remote.lastUpdated)")
                
                saveLocal(context: context!, model: remote, updatedLastUpdated: false) { _ in
                    print("🔄 Remote → Local")
                    DispatchQueue.main.async {
                        authModel.setUserModel(remote)
                        completion()
                    }
                }
            }

        case let (local?, nil):
            saveRemote(id: id, userModel: local, updateLastUpdated: false) { _ in
                print("🔄 Local → Remote (no remote)")
                completion()
            }

        case let (nil, remote?):
            saveLocal(context: context!, model: remote, updatedLastUpdated: false) { _ in
                print("🔄 Remote → Local (no local)")
                DispatchQueue.main.async {
                    authModel.setUserModel(remote)
                    completion()
                }
            }

        case (nil, nil):
            createUser(id: id, firebaseUser: firebaseUser, name: name, authModel: authModel) {
                completion()
            }
        }
    }
    
    func createUser(id: String, firebaseUser: User?, name: String?, authModel: AuthViewModel, completion: @escaping () -> Void){
        
        let finalName  = name ?? firebaseUser?.displayName ?? "User#\(String(id.prefix(5)))"
        let finalEmail = firebaseUser?.email ?? "Email"
        
        let newUser = UserModel(id: id, name: finalName, photoURL: firebaseUser?.photoURL, email: finalEmail, gameIDs: [])
        
        saveLocal(context: context!, model: newUser) { _ in }
        saveRemote(id: id, userModel: newUser) { _ in }
        DispatchQueue.main.async {
            authModel.setUserModel(newUser)
            print("✅ Created new user")
            completion()
        }
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

    
    
    func saveRemote(id: String, userModel: UserModel, updateLastUpdated: Bool = true, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let ref = db.collection("users").document(id)
        
        let updatedUser = userModel
        if updateLastUpdated {
            updatedUser.lastUpdated = Date()
        }
        
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
    
    func saveLocal(context: ModelContext, model: UserModel, updatedLastUpdated: Bool = true, completion: @escaping (Bool) -> Void) {
        if updatedLastUpdated {
            model.lastUpdated = Date()
        }
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
        let ref = Firestore.firestore().collection("users").document(id)

        ref.getDocument { snapshot, error in
            guard snapshot?.exists == true else {
                print("⚠️ User doc did not exist")
                completion(true)
                return
            }

            ref.delete { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Firestore delete error:", error)
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }

    
    func deleteUnified(id: String) {
        deleteLocal(id: id) { _ in }
        deleteRemote(id: id) { _ in }
    }

    
    func uploadProfilePhoto(
        id: String,
        _ image: UIImage,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let user = Auth.auth().currentUser else {
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
