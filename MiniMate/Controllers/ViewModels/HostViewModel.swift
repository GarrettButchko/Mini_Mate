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
    
    let gameModel: GameViewModel
    let courseRepo = CourseRepository()
    let handler: LocationHandler
    
    private let ttl: TimeInterval = 5 * 60
    private var lastUpdated = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(gameModel: GameViewModel, handler: LocationHandler) {
        self.gameModel = gameModel
        self.handler = handler
        self.timeRemaining = ttl
    }
    
    func tick(showHost: Binding<Bool>) {
        guard gameModel.isOnline else { return }   // ✅ offline = no timer behavior

        let expire = lastUpdated.addingTimeInterval(ttl)
        timeRemaining = max(0, expire.timeIntervalSinceNow)

        if timeRemaining == 0 {
            showHost.wrappedValue = false
        }
    }

    
    func resetTimer() {
        guard gameModel.isOnline else { return }   // ✅ offline = don't reset timer

        lastUpdated = Date()
        gameModel.setLastUpdated(lastUpdated)
        timeRemaining = ttl
    }
    
    func addPlayer(newPlayerName: Binding<String>, newPlayerEmail: Binding<String>) {
        gameModel.addLocalPlayer(named: newPlayerName.wrappedValue, email: newPlayerEmail.wrappedValue)
        newPlayerName.wrappedValue = ""
        newPlayerEmail.wrappedValue = ""
        resetTimer()
    }
    
    func deletePlayer() {
        if let id = playerToDelete {
            gameModel.removePlayer(userId: id)
            resetTimer()
        }
    }
    
    func startGame(viewManager: ViewManager, showHost: Binding<Bool>) {
        gameModel.startGame(showHost: showHost)
        viewManager.navigateToScoreCard()
    }
    
    func handleLocationChange(_ item: MKMapItem?) {
        guard let name = item?.name else { return }
        
        courseRepo.courseNameExistsAndSupported(name) { exists in
            if !exists { return }
            
            self.courseRepo.fetchCourseByName(name) { course in
                let holes = course?.pars?.count ?? 18
                self.gameModel.setNumberOfHole(holes)
            }
        }
        resetTimer()
    }
    
    func searchNearby(showTxtButtons: Binding<Bool>) {
        gameModel.setHasLoaded(false)
        gameModel.findClosestLocationAndLoadCourse(locationHandler: handler, showTextAndButtons: showTxtButtons)
        resetTimer()
    }
    
    func retry(showTxtButtons: Binding<Bool>, isRotating: Binding<Bool>) {
        isRotating.wrappedValue = true
        searchNearby(showTxtButtons: showTxtButtons)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isRotating.wrappedValue = false
        }
        resetTimer()
    }
    
    func exit(showTxtButtons: Binding<Bool>, email: Binding<String>){
        email.wrappedValue = ""
        handler.selectedItem = nil
        gameModel.setLocation(nil)
        gameModel.resetCourse()
        showTxtButtons.wrappedValue = false
    }
    
    func setUp(showTxtButtons: Binding<Bool>) {
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
