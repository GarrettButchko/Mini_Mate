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

@dynamicMemberLookup
final class GameViewModel: ObservableObject {
    
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
    private var listenerHandle: DatabaseHandle?
    
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
        game.location      = newGame.location
        game.date          = newGame.date
        game.completed     = newGame.completed
        game.numberOfHoles = newGame.numberOfHoles
        game.started       = newGame.started
        game.dismissed     = newGame.dismissed
        game.live          = newGame.live
        game.lastUpdated   = newGame.lastUpdated
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
    
    func setLocation(_ location: MapItemDTO?) {
        objectWillChange.send() // notify before mutating
        lastUpdated = Date()
        self.game.location = location
        if let location = location{
            game.courseID = CourseIDGenerator.generateCourseID(from: location)
        }
        pushUpdate()
    }
    
    func setNumberOfHole(_ holes: Int) {
        objectWillChange.send() // notify before mutating
        lastUpdated = Date()
        self.game.numberOfHoles = holes
        pushUpdate()
    }
    
    func stopListening() {
        guard let ref = gameRef(), let handle = listenerHandle else { return }
        ref.removeObserver(withHandle: handle)
        listenerHandle = nil
    }
    
    // MARK: - Updating DataBase
    func pushUpdate() {
        guard gameRef() != nil else { return }
        objectWillChange.send() // notify before mutating
        lastUpdated = Date()
        game.lastUpdated = lastUpdated
        if onlineGame && authModel.userModel?.id != "IDGuest" {
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
            print("⚠️ Invalid game.id “\(game.id)” — skipping Firebase call")
            return
        }
        
        listenerHandle = ref.observe(.value) { [weak self] snap in
            guard let self = self,
                  snap.exists(),
                  let dto: GameDTO = try? snap.data(as: GameDTO.self)
            else { return }
            let incoming = Game.fromDTO(dto)
            
            // ignore echoes
            guard incoming.lastUpdated > self.game.lastUpdated else { return }
            
            self.objectWillChange.send()
            self.game.lastUpdated = incoming.lastUpdated
            
            // 1) merge top‐level fields…
            self.game.id          = incoming.id
            self.game.location          = incoming.location
            self.game.date          = incoming.date
            self.game.completed     = incoming.completed
            self.game.numberOfHoles = incoming.numberOfHoles
            self.game.started       = incoming.started
            self.game.dismissed     = incoming.dismissed
            self.game.live    = incoming.live
            
            // 2) build a lookup of remote players by ID
            let remoteByID = Dictionary(uniqueKeysWithValues:
                                            incoming.players.map { ($0.id, $0) }
            )
            
            // 3) update or remove existing local players
            self.game.players.removeAll { local in
                guard let remote = remoteByID[local.id] else {
                    // local player no longer in remote list → drop them
                    return true
                }
                // still present → update their fields
                local.inGame       = remote.inGame
                
                // merge holes
                for (hIdx, holeDTO) in remote.holes.enumerated() where hIdx < local.holes.count {
                    local.holes[hIdx].strokes = holeDTO.strokes
                }
                
                return false
            }
            
            // 4) append any brand‐new players
            for remote in incoming.players where !self.game.players.contains(where: { $0.id == remote.id }) {
                
                initializeHoles(for: remote)
                self.game.players.append(remote)
            }
        }
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
    
    func addUser() {
        guard let user = authModel.userModel else { return }
        // don’t add the same user twice
        guard !game.players.contains(where: { $0.userId == user.id }) else { return }
        
        objectWillChange.send()
        let newPlayer = Player(
            userId: user.id,
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
    
    
    func removePlayer(userId: String) {
        objectWillChange.send()
        withAnimation(){
            game.players.removeAll { $0.userId == userId }
        }
        pushUpdate()
    }
    
    func joinGame(id: String, completion: @escaping (Bool) -> Void) {
        guard onlineGame else { return }
        resetGame()
        liveGameRepo.fetchGame(id: id) { game in
            if let game = game, !game.dismissed, !game.started, !game.completed {
                self.setGame(game)
                self.addUser()
                self.listenForUpdates()
                completion(true)
            } else {
                completion (false)
            }
            completion(false)
        }
    }
    
    func leaveGame(userId: String) {
        guard onlineGame else { return }
        objectWillChange.send()
        stopListening()
        self.removePlayer(userId: userId)
        pushUpdate()
        resetGame()
    }
    
    
    // MARK: Game State
    
    func createGame(online: Bool ,startingLoc: MKMapItem?) {
        guard !game.live else { return }
        objectWillChange.send()
        resetGame()
        game.live = true
        onlineGame = online
        game.id = generateGameCode()
        addUser()
        pushUpdate()
        listenForUpdates()
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
        
        if let courseID = course?.id {
            self.courseRepo.incPeakAnalytics(courseID: courseID)
        }
        
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
        resetCourse()
        resetGame()             // now creates a new Game with id == ""
    }
    
    /// Deep-clone the game you just finished, persist it locally & remotely, then reset.
    func finishAndPersistGame(in context: ModelContext) {
        stopListening()
        game.endTime = Date()
        
        
        // Clone all fields into a fresh Game instance
        let finished = Game(
            id:           game.id,
            location:     game.location,
            date:         game.date,
            completed:    game.completed,
            numberOfHoles: game.numberOfHoles,
            started:      game.started,
            dismissed:    game.dismissed,
            totalTime:    game.totalTime,
            live:         game.live,
            lastUpdated:  game.lastUpdated,
            courseID:     game.courseID,
            players:      game.players.map { player in
                Player(
                    id:       player.id,
                    userId:   player.userId,
                    name:     player.name,
                    photoURL: player.photoURL,
                    holes:    player.holes.map {
                        Hole(number: $0.number, strokes: $0.strokes)
                    },
                    email: player.email
                )
            },
            startTime:    game.startTime,
            endTime:      game.endTime,
        )
        
        
        // Analytics for course
        if let courseID = finished.courseID {
            // Add 1 Game to Course Analytics
            courseRepo.updateGameCount(courseID: courseID)
            
            for player in finished.players {
                // Add 1 Player to Course Analytics
                courseRepo.updateDailyCount(courseID: courseID)
                if let email = player.email {
                    courseRepo.isEmailInCourse(email: email, courseID: courseID) { isInCourse in
                        if isInCourse {
                            // if email already in courserepo then update new players
                            self.courseRepo.updateReturningPlayers(courseID: courseID)
                        } else {
                            // if email not already in courserepo then update returning players
                            self.courseRepo.updateNewPlayers(courseID: courseID)
                            self.courseRepo.addEmail(newEmail: email, courseID: courseID) { complete in }
                        }
                        // Add email once this is done
                    }
                }
            }
            courseRepo.addToHoleAnalytics(courseID: courseID, game: finished)
            if let startTime = finished.startTime, let endTime = finished.endTime {
                courseRepo.addRoundTime(courseID: courseID, startTime: startTime, endTime: endTime)
            }
        }
        
        UnifiedGameRepository(context: context).save(finished) { local, remote in
            if local || remote {
                print("Saved Game Everywhere")
                self.authModel.userModel?.gameIDs.append(finished.id)
                
                if let userModel = self.authModel.userModel {
                    UserRepository(context: context).saveRemote(id: self.authModel.currentUserIdentifier!, userModel: userModel) { completed in
                        print("Updated online user")
                    }
                }
            } else {
                print("Error Saving Game")
            }
        }
        
        pushUpdate()
        objectWillChange.send()
        hasLoaded = false
        resetCourse()
        resetGame()
    }
    
    
    // MARK: Course
    func findClosestLocationAndLoadCourse(locationHandler: LocationHandler, showTextAndButtons: Binding<Bool>) {
        
        guard !hasLoaded else {
                print("⛔️ Already loaded closest course — skipping")
                return
            }
        // Guard to prevent multiple calls
        print("🚀 Starting findClosestLocationAndLoadCourse()")
        
        locationHandler.findClosestMiniGolf { closestPlace in
            guard let closestPlace = closestPlace else {
                print("⚠️ No closest mini golf location found")
                return
            }
            
            print("📍 Closest mini golf found: \(closestPlace.name ?? "Unknown")")
            
            DispatchQueue.main.async {
                withAnimation {
                    locationHandler.selectedItem = closestPlace
                    showTextAndButtons.wrappedValue = true
                }
                
                self.setLocation(closestPlace.toDTO())
                print("🎯 Game model location set: \(closestPlace.toDTO())")
                
                let courseID = CourseIDGenerator.generateCourseID(from: closestPlace.toDTO())
                
                
                self.courseRepo.fetchCourse(id: courseID) { course in
                    if let course = course {
                        self.course = course
                        print("✅ Course loaded: \(course.name)")
                        self.hasLoaded = true
                    } else {
                        print("⚠️ Course not found for ID: \(courseID) creating new course")
                        if let location = self.game.location {
                            self.courseRepo.createCourseWithMapItem(location: location) { complete in }
                        }
                    }
                }
            }
        }
    }
    
    func getHasLoaded() -> Bool { hasLoaded }
    func setHasLoaded(_ hasLoaded: Bool) { self.hasLoaded = hasLoaded}
    
    func resetCourse(){ course = nil; game.courseID = nil}
    func getCourse() -> Course? { course }
}
