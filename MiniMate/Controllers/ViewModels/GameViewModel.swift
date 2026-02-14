//
//  GameViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/1/25.
//


import Foundation
import SwiftUI
import FirebaseDatabase
import MapKit
import Combine
import SwiftData

struct GuestData {
    var id: String
    var email: String?
    var name: String
}

@dynamicMemberLookup
final class GameViewModel: ObservableObject, Observable {
    
    // Published Game State
    @Published private var game: Game
    @Published private var course: Course?
    
    // Dependencies & Config
    private var onlineGame: Bool
    private var lastUpdated: Date = Date()
    
    private var hasLoaded: Bool = false
    
    private var liveGameRepo = LiveGameRepository()
    private var courseRepo = CourseRepository()
    private var authModel: AuthViewModel
    private var listenerHandles: [DatabaseHandle] = []
    private var listenerRefs: [DatabaseReference] = []
    
    // Initialization
    init(game: Game,
         authModel: AuthViewModel,
         onlineGame: Bool = true,
         course: Course?
    ){
        self.game = game
        self.authModel = authModel
        self.onlineGame = onlineGame
        self.course = course
    }
    
    /// Read-only access: vm.someField == game.someField
    subscript<T>(dynamicMember keyPath: KeyPath<Game, T>) -> T {
        game[keyPath: keyPath]
    }
    
    /// A two‐way `Binding<Game>` for the entire model.
    func bindingForGame() -> Binding<Game> {
        Binding<Game>(
            get: { self.game },            // read the current game
            set: { newGame in              // when it’s written…
                self.setGame(newGame)        // swap in & re-attach listeners
            }
        )
    }
    
    /// Two-way binding: DatePicker(..., selection: vm.binding(for: \ .date))
    func binding<T>(for keyPath: ReferenceWritableKeyPath<Game, T>) -> Binding<T> {
        Binding(
            get: { self.game[keyPath: keyPath] },
            set: { newValue in
                self.objectWillChange.send()
                self.game[keyPath: keyPath] = newValue
                self.pushUpdate()
            }
        )
    }
    
    /// Expose full model if needed
    var gameValue: Game { game }
    
    var isOnline: Bool { onlineGame }
    
    var isInGame: Bool {
        !gameValue.id.isEmpty
    }
    
    // Public Actions
    func resetGame() {
        setGame(Game())
    }
    
    func setGame(_ newGame: Game) {
        objectWillChange.send()
        // Tear down any existing listener
        stopListening()
        // Always start fresh: remove local players and holes
        game.players.removeAll()
        
        // 1) Merge top-level fields
        game.id            = newGame.id
        game.date          = newGame.date
        game.completed     = newGame.completed
        game.numberOfHoles = newGame.numberOfHoles
        game.started       = newGame.started
        game.dismissed     = newGame.dismissed
        game.live          = newGame.live
        game.lastUpdated   = newGame.lastUpdated
        game.courseID      = newGame.courseID
        game.locationName  = newGame.locationName
        lastUpdated        = newGame.lastUpdated
        
        // 2) Rebuild players and their holes from remote data
        for remotePlayer in newGame.players {
            initializeHoles(for: remotePlayer)
            // remotePlayer.holes already contains correct strokes
            // Append the fully initialized player
            game.players.append(remotePlayer)
        }
        
        // Restart updates if needed
        if onlineGame {
            listenForUpdates()
        }
    }
    
    func setCompletedGame(_ completedGame: Bool) {
        objectWillChange.send() // notify before mutating
        lastUpdated = Date()
        self.game.completed = completedGame
        pushUpdate()
    }
    
    func setNumberOfHole(_ holes: Int) {
        objectWillChange.send() // notify before mutating
        lastUpdated = Date()
        self.game.numberOfHoles = holes
        pushUpdate()
    }
    
    func stopListening() {
        guard !listenerHandles.isEmpty else { return }
        for (ref, handle) in zip(listenerRefs, listenerHandles) {
            ref.removeObserver(withHandle: handle)
        }
        listenerHandles.removeAll()
        listenerRefs.removeAll()
    }
    
    func setLastUpdated(_ date: Date) {
        objectWillChange.send()
        lastUpdated = date
        pushUpdate()
    }
    
    // MARK: - Updating DataBase
    func pushUpdate() {
        guard gameRef() != nil else { return }
        objectWillChange.send() // notify before mutating
        lastUpdated = Date()
        game.lastUpdated = lastUpdated
        if onlineGame {
            liveGameRepo.addOrUpdateGame(game) { _ in }
        }
    }
    
    
    private func gameRef() -> DatabaseReference? {
        guard onlineGame,
              !game.id.isEmpty,
              game.id.rangeOfCharacter(from: CharacterSet(charactersIn: ".#\\$\\[\\]]")) == nil
        else {
            return nil
        }
        return Database.database()
            .reference()
            .child("live_games")
            .child(game.id)
    }
    
    func listenForUpdates() {
        guard onlineGame else { return }
        guard let ref = gameRef() else {
            print("Invalid game.id or not online — skipping Firebase call")
            return
        }
        // Top-level field changes (avoid full snapshot reads)
        let rootHandle = ref.observe(.childChanged) { [weak self] snap in
            guard let self = self else { return }
            if snap.key == "players" { return }
            self.objectWillChange.send()
            switch snap.key {
            case "id":
                self.game.id = snap.value as? String ?? self.game.id
            case "hostUserId":
                self.game.hostUserId = snap.value as? String ?? self.game.hostUserId
            case "date":
                if let ts = snap.value as? TimeInterval { self.game.date = Date(timeIntervalSince1970: ts) }
                else if let num = snap.value as? NSNumber { self.game.date = Date(timeIntervalSince1970: num.doubleValue) }
            case "completed":
                self.game.completed = snap.value as? Bool ?? self.game.completed
            case "numberOfHoles":
                if let num = snap.value as? NSNumber { self.game.numberOfHoles = num.intValue }
            case "started":
                self.game.started = snap.value as? Bool ?? self.game.started
            case "dismissed":
                self.game.dismissed = snap.value as? Bool ?? self.game.dismissed
            case "live":
                self.game.live = snap.value as? Bool ?? self.game.live
            case "lastUpdated":
                if let ts = snap.value as? TimeInterval { self.game.lastUpdated = Date(timeIntervalSince1970: ts) }
                else if let num = snap.value as? NSNumber { self.game.lastUpdated = Date(timeIntervalSince1970: num.doubleValue) }
            case "courseID":
                self.game.courseID = snap.value as? String
            case "startTime":
                if let ts = snap.value as? TimeInterval { self.game.startTime = Date(timeIntervalSince1970: ts) }
                else if let num = snap.value as? NSNumber { self.game.startTime = Date(timeIntervalSince1970: num.doubleValue) }
            case "locationName":
                self.game.locationName = snap.value as? String
            case "endTime":
                if let ts = snap.value as? TimeInterval { self.game.endTime = Date(timeIntervalSince1970: ts) }
                else if let num = snap.value as? NSNumber { self.game.endTime = Date(timeIntervalSince1970: num.doubleValue) }
            default:
                break
            }
        }
        listenerHandles.append(rootHandle)
        listenerRefs.append(ref)
        
        // Player add/update/remove listeners
        let playersRef = ref.child("players")
        
        let addHandle = playersRef.observe(.childAdded) { [weak self] snap in
            guard let self = self,
                  let dto: PlayerDTO = try? snap.data(as: PlayerDTO.self)
            else { return }
            let remote = Player.fromDTO(dto)
            self.attachHoles(to: remote)
            if !self.game.players.contains(where: { $0.id == remote.id }) {
                self.objectWillChange.send()
                self.game.players.append(remote)
            }
        }
        listenerHandles.append(addHandle)
        listenerRefs.append(playersRef)
        
        let changeHandle = playersRef.observe(.childChanged) { [weak self] snap in
            guard let self = self,
                  let dto: PlayerDTO = try? snap.data(as: PlayerDTO.self)
            else { return }
            let remote = Player.fromDTO(dto)
            if let local = self.game.players.first(where: { $0.id == remote.id }) {
                self.objectWillChange.send()
                self.mergePlayer(local: local, remote: remote)
            }
        }
        listenerHandles.append(changeHandle)
        listenerRefs.append(playersRef)
        
        let removeHandle = playersRef.observe(.childRemoved) { [weak self] snap in
            // 1. Decode the snapshot using your DTO, just like you do in childAdded
            guard let self = self,
                  let dto: PlayerDTO = try? snap.data(as: PlayerDTO.self)
            else {
                print("❌ Could not decode removed player data")
                return
            }
            
            // 2. Convert DTO to your local Player model
            let remote = Player.fromDTO(dto)
            
            print("🗑️ Firebase removed player: \(remote.name) with userId: \(remote.userId)")
            
            DispatchQueue.main.async {
                withAnimation {
                    // 3. Notify the UI of the impending change
                    self.objectWillChange.send()
                    
                    // 4. Remove using the userId from the decoded DTO
                    self.game.players.removeAll { $0.id == remote.id }
                    
                    // 5. Explicitly update the published game property to force a refresh
                    self.game = self.game
                }
            }
        }
        listenerHandles.append(removeHandle)
        listenerRefs.append(playersRef)
    }
    
    func deleteFromFirebaseGamesArr(){
        guard onlineGame else { return }
        liveGameRepo.deleteGame(id: game.id) { result in
            if result {
                print("Deleted Game id: " + self.game.id + " From Firebase")
            }
        }
    }
    
    // MARK: - Helpers
    private func initializeHoles(for player: Player) {
        guard player.holes.count != game.numberOfHoles else { return }
        player.holes = []
        player.holes = (0..<game.numberOfHoles).map {
            let hole = Hole(number: $0 + 1)
            hole.player = player
            return hole
        }
    }

    private func attachHoles(to player: Player) {
        // Preserve existing strokes and ensure player linkage.
        for hole in player.holes {
            hole.player = player
        }

        if player.holes.count < game.numberOfHoles {
            let existing = Set(player.holes.map(\.number))
            for n in 1...game.numberOfHoles where !existing.contains(n) {
                let hole = Hole(number: n)
                hole.player = player
                player.holes.append(hole)
            }
        }

        player.holes.sort { $0.number < $1.number }
    }

    private func mergePlayer(local: Player, remote: Player) {
        local.inGame = remote.inGame
        local.name = remote.name
        local.photoURL = remote.photoURL
        local.email = remote.email

        for remoteHole in remote.holes {
            if let localHole = local.holes.first(where: { $0.number == remoteHole.number }) {
                localHole.strokes = remoteHole.strokes
            } else {
                let hole = Hole(number: remoteHole.number, strokes: remoteHole.strokes)
                hole.player = local
                local.holes.append(hole)
            }
        }
        local.holes.sort { $0.number < $1.number }
    }
    
    private func generateGameCode(length: Int = 6) -> String {
        let chars = "ABCDEFGHIJKLMNPQRSTUVWXYZ123456789"
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }
    
    // MARK: Players
    func addLocalPlayer(named name: String, email: String) {
        objectWillChange.send()
        let newPlayer = Player(
            userId: generateGameCode(),
            name: name,
            photoURL: nil,
            inGame: true,
            email: email != "" ? email : nil
        )
        initializeHoles(for: newPlayer)
        withAnimation(){
            game.players.append(newPlayer)
        }
        pushUpdate()
    }
    
    func addUser(guestData: GuestData? = nil) {
        if let guestData = guestData {
            objectWillChange.send()
            let newPlayer = Player(
                userId: guestData.id,
                name: guestData.name,
                photoURL: nil,
                inGame: true,
                email: guestData.email
            )
            initializeHoles(for: newPlayer)
            withAnimation(){
                game.players.append(newPlayer)
            }
            pushUpdate()
        } else {
            guard let user = authModel.userModel else { return }
            // don’t add the same user twice
            guard !game.players.contains(where: { $0.userId == user.googleId }) else { return }
            
            objectWillChange.send()
            let newPlayer = Player(
                userId: user.googleId,
                name: user.name,
                photoURL: user.photoURL,
                inGame: true,
                email: user.email
            )
            initializeHoles(for: newPlayer)
            withAnimation(){
                game.players.append(newPlayer)
            }
            pushUpdate()
        }
    }
    
    
    func removePlayer(userId: String) {
        objectWillChange.send()
        withAnimation(){
            game.players.removeAll { $0.userId == userId }
        }
        pushUpdate()
    }
    
    func joinGame(id: String, userId: String, completion: @escaping (Bool) -> Void) {
        guard onlineGame else { return }
        resetGame()
        resetCourse()
        liveGameRepo.fetchGame(id: id) { game in
            if let game = game,
               !game.dismissed,
               !game.started,
               !game.completed,
               !game.players.contains(where: { $0.userId == userId }) {
                self.setGame(game)
                self.addUser()
                self.listenForUpdates()
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    
    func leaveGame(userId: String) {
        guard onlineGame else { return }
        
        // 1. First, remove the player locally
        objectWillChange.send()
        withAnimation {
            game.players.removeAll { $0.userId == userId }
        }
        
        // 2. Push this change to Firebase so the Host (and others) see it
        // We do this BEFORE stopping the listeners or resetting the game
        pushUpdate()
        
        // 3. Give Firebase a tiny moment to send the packet, then clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.stopListening()
            self.resetGame()
        }
    }
    
    
    // MARK: Game State
    
    func createGame(online: Bool = false, guestData: GuestData? = nil) {
        if let guestData = guestData {
            guard !game.live else { return }
            
            objectWillChange.send()
            resetGame()
            
            game.live = true
            onlineGame = online
            game.id = generateGameCode()
            
            game.hostUserId = guestData.id
            
            if let course = course {
                game.courseID = course.id
                game.locationName = course.name
            } else {
                print("No course set for game")
            }
            
            addUser(guestData: guestData)
            pushUpdate()
        } else {
            guard !game.live else { return }
            
            objectWillChange.send()
            resetGame()
            
            game.live = true
            onlineGame = online
            game.id = generateGameCode()
            
            game.hostUserId = authModel.userModel!.googleId
            
            if let course = course {
                game.courseID = course.id
                game.locationName = course.name
            } else {
                print("No course set for game")
            }
            
            addUser()
            pushUpdate()
            listenForUpdates()
        }
    }
    
    func startGame(showHost: Binding<Bool>) {
        guard !game.started else { return }
        
        objectWillChange.send()
        for player in game.players {
            initializeHoles(for: player)
        }
        game.startTime = Date()
        game.started = true
        pushUpdate()
        
        // Flip the binding to false
        showHost.wrappedValue = false
    }
    
    func dismissGame() {
        guard !game.dismissed else { return }
        objectWillChange.send()
        stopListening()         // tear down any existing listener
        game.dismissed = true
        pushUpdate()            // push the “dismissed” flag
        deleteFromFirebaseGamesArr()
        
        hasLoaded = false
        resetGame()             // now creates a new Game with id == ""
    }
    
    /// Deep-clone the game you just finished, persist it locally & remotely, then reset.
    func finishAndPersistGame(game: Game, in context: ModelContext, isGuest: Bool = false) {
        stopListening()
        game.endTime = Date()
        game.live = false
        
        var finished: Game = Game()
        
        copyGame(into: &finished, from: game)
        
        print(finished)

        let group = DispatchGroup()
        var allOK = true

        // 1) Save game
        if !isGuest {
            group.enter()
            UnifiedGameRepository(context: context).save(finished) { local, remote in
                if local || remote {
                    print("Saved Game Everywhere")
                    self.authModel.userModel?.gameIDs.append(finished.id)

                    if let userModel = self.authModel.userModel,
                       let uid = self.authModel.currentUserIdentifier {
                        UserRepository(context: context).saveRemote(id: uid, userModel: userModel) { _ in
                            print("Updated online user")
                        }
                    }
                } else {
                    print("Error Saving Game")
                    allOK = false
                }
                group.leave()
            }
        } else {
            group.enter()
            LocalGameRepository(context: context).save(finished) { _ in
                print("Saved Guest Game")
                group.leave()
            }
        }

        // 2) Analytics (host only)
        if let currentUserId = authModel.userModel?.googleId,
           currentUserId == finished.hostUserId || isGuest {

            group.enter()
            print("running analytics")
            processAnalytics(finishedGame: finished) { success in
                if !success { allOK = false }
                group.leave()
            }
        }

        // 3) Final reset ONLY after everything finishes
        group.notify(queue: .main) {
            if allOK {
                print("✅ Save + analytics completed")
            } else {
                print("⚠️ Save and/or analytics failed")
            }

            // If you truly need to update the live game state, do it BEFORE this notify,
            // or do a minimal "dismissed/completed" update here.
            self.objectWillChange.send()
            self.hasLoaded = false
            self.resetCourse()
            self.resetGame()
        }
    }
    
    func copyGame(into target: inout Game, from source: Game) {
        target = Game(
            id: source.id,
            hostUserId: source.hostUserId,
            date: source.date,
            completed: source.completed,
            numberOfHoles: source.numberOfHoles,
            started: source.started,
            dismissed: source.dismissed,
            live: source.live,
            lastUpdated: source.lastUpdated,
            courseID: source.courseID,
            players: source.players.map { player in
                Player(
                    id: player.id,
                    userId: player.userId,
                    name: player.name,
                    photoURL: player.photoURL,
                    holes: player.holes.map { Hole(number: $0.number, strokes: $0.strokes) },
                    email: player.email
                )
            },
            locationName: source.locationName,
            startTime: source.startTime,
            endTime: source.endTime
        )
    }


    func processAnalytics(
        finishedGame finished: Game,
        completion: @escaping (Bool) -> Void
    ) {
        guard let courseID = finished.courseID else {
            print("No Course Id No Analytics")
            completion(false)
            return
        }

        let emails = finished.players.compactMap { $0.email }
        courseRepo.updateDayAnalytics(
            emails: emails,
            courseID: courseID,
            game: finished,
            startTime: finished.startTime,
            endTime: finished.endTime
        ) { success in
            completion(success)
        }
    }

    
    
    // MARK: Course

    func findClosestLocationAndLoadCourse(locationHandler: LocationHandler) {
        guard !hasLoaded else { return }

        // Use a Task to move the heavy lifting off the Main Thread
        Task(priority: .userInitiated) {
            // 1. Wait for location without blocking the UI
            while locationHandler.userLocation == nil {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s sleep
            }

            // 2. Perform the heavy MapKit search
            locationHandler.findClosestMiniGolf { closestPlace in
                guard let closestPlace = closestPlace else { return }

                // 3. Switch back to Main for UI and Firebase
                Task { @MainActor in
                    let courseID = CourseIDGenerator.generateCourseID(from: closestPlace.toDTO())
                    
                    // Now fetch the course
                    self.courseRepo.fetchCourse(id: courseID) { course in
                        withAnimation {
                            self.course = course
                        }
                        self.hasLoaded = true
                    }
                }
            }
        }
    }

    
    func setUp(handler: LocationHandler) {
        if getCourse() == nil && !getHasLoaded() {
            findClosestLocationAndLoadCourse(locationHandler: handler)
            setHasLoaded(true)
        }
    }
    
    func searchNearby(handler: LocationHandler) {
        setHasLoaded(false)
        findClosestLocationAndLoadCourse(locationHandler: handler)
    }
    
    func exit(handler: LocationHandler){
        resetCourse()
    }
    
    func retry(isRotating: Binding<Bool>, handler: LocationHandler) {
        isRotating.wrappedValue = true
        searchNearby(handler: handler)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isRotating.wrappedValue = false
        }
    }
    
    func getHasLoaded() -> Bool { hasLoaded }
    func setHasLoaded(_ hasLoaded: Bool) { self.hasLoaded = hasLoaded}
    
    func resetCourse(){ course = nil; game.courseID = nil}
    func getCourse() -> Course? { course }
}
