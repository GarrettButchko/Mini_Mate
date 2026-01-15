//
//  HostViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/11/25.
//

import SwiftUI
import MapKit

@MainActor
final class HostViewModel: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var playerToDelete: String?
    
    let courseRepo = CourseRepository()
    
    private let ttl: TimeInterval = 5 * 60
    private var lastUpdated = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init() {
        self.timeRemaining = ttl
    }
    
    func tick(showHost: Binding<Bool>, gameModel: GameViewModel) {
        guard gameModel.isOnline else { return }   // ✅ offline = no timer behavior

        let expire = lastUpdated.addingTimeInterval(ttl)
        timeRemaining = max(0, expire.timeIntervalSinceNow)

        if timeRemaining == 0 {
            showHost.wrappedValue = false
        }
    }

    
    func resetTimer(_ gameModel: GameViewModel) {
        guard gameModel.isOnline else { return }   // ✅ offline = don't reset timer

        lastUpdated = Date()
        gameModel.setLastUpdated(lastUpdated)
        timeRemaining = ttl
    }
    
    func addPlayer(newPlayerName: Binding<String>, newPlayerEmail: Binding<String>, gameModel: GameViewModel) {
        gameModel.addLocalPlayer(named: newPlayerName.wrappedValue, email: newPlayerEmail.wrappedValue)
        newPlayerName.wrappedValue = ""
        newPlayerEmail.wrappedValue = ""
        resetTimer(gameModel)
    }
    
    func deletePlayer(gameModel: GameViewModel) {
        if let id = playerToDelete {
            gameModel.removePlayer(userId: id)
            resetTimer(gameModel)
        }
    }
    
    func startGame(viewManager: ViewManager, showHost: Binding<Bool>, isGuest: Bool = false, gameModel: GameViewModel) {
        gameModel.startGame(showHost: showHost)
        viewManager.navigateToScoreCard(isGuest)
    }
    
    func handleLocationChange(_ item: MKMapItem?, gameModel: GameViewModel) {
        guard let name = item?.name else { return }
        
        courseRepo.courseNameExistsAndSupported(name) { exists in
            if !exists { return }
            
            self.courseRepo.fetchCourseByName(name) { course in
                let holes = course?.pars?.count ?? 18
                gameModel.setNumberOfHole(holes)
            }
        }
        resetTimer(gameModel)
    }
    
    func searchNearby(showTxtButtons: Binding<Bool>, gameModel: GameViewModel, handler: LocationHandler) {
        gameModel.setHasLoaded(false)
        gameModel.findClosestLocationAndLoadCourse(locationHandler: handler, showTextAndButtons: showTxtButtons)
        resetTimer(gameModel)
    }
    
    func retry(showTxtButtons: Binding<Bool>, isRotating: Binding<Bool>, gameModel: GameViewModel, handler: LocationHandler) {
        isRotating.wrappedValue = true
        searchNearby(showTxtButtons: showTxtButtons, gameModel: gameModel, handler: handler)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isRotating.wrappedValue = false
        }
        resetTimer(gameModel)
    }
    
    func exit(showTxtButtons: Binding<Bool>, email: Binding<String>, gameModel: GameViewModel, handler: LocationHandler){
        email.wrappedValue = ""
        handler.selectedItem = nil
        gameModel.setLocation(nil)
        gameModel.resetCourse()
        showTxtButtons.wrappedValue = false
    }
    
    func setUp(showTxtButtons: Binding<Bool>, gameModel: GameViewModel, handler: LocationHandler) {
        if gameModel.getCourse() == nil && !gameModel.getHasLoaded() {
            gameModel.findClosestLocationAndLoadCourse(locationHandler: handler, showTextAndButtons: showTxtButtons)
            gameModel.setHasLoaded(true)
        }
    }
    
    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
