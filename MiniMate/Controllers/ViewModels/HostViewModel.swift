//
//  HostViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/11/25.
//

import SwiftUI
import MapKit
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

@MainActor
final class HostViewModel: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var playerToDelete: String?
    
    @Published var showTextAndButtons = false
    @Published var showAddPlayerAlert = false
    @Published var showDeleteAlert = false
    @Published var newPlayerName = ""
    @Published var newPlayerEmail = ""
    @Published var isRotating = false
    @Published var showLocationButton: Bool = false
    @Published var showQRCode: Bool = false
    
    @Published var qrCodeImage: UIImage? = nil
    
    let courseRepo = CourseRepository()
    
    private let ttl: TimeInterval = 5 * 60
    private var lastUpdated = Date()
    private var lastResetTime: Date?
    private let resetCooldown: TimeInterval = 2.0 // Minimum 1 second between resets
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Custom binding for showTextAndButtons
    var showTextAndButtonsBinding: Binding<Bool> {
        Binding(
            get: { self.showTextAndButtons },
            set: { self.showTextAndButtons = $0 }
        )
    }
    
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
        
        // Prevent spam by enforcing cooldown
        if let lastReset = lastResetTime,
           Date().timeIntervalSince(lastReset) < resetCooldown {
            return
        }
        
        lastUpdated = Date()
        lastResetTime = Date()
        gameModel.setLastUpdated(lastUpdated)
        timeRemaining = ttl
    }
    
    func addPlayer(gameModel: GameViewModel) {
        gameModel.addLocalPlayer(named: newPlayerName, email: newPlayerEmail)
        newPlayerName = ""
        newPlayerEmail = ""
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
    
    func searchNearby(gameModel: GameViewModel, handler: LocationHandler) {
        gameModel.setHasLoaded(false)
        gameModel.findClosestLocationAndLoadCourse(locationHandler: handler)
        resetTimer(gameModel)
    }
    
    func retry(gameModel: GameViewModel, handler: LocationHandler) {
        isRotating = true
        searchNearby(gameModel: gameModel, handler: handler)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isRotating = false
        }
        resetTimer(gameModel)
    }
    
    func exit(gameModel: GameViewModel, handler: LocationHandler){
        newPlayerEmail = ""
        gameModel.resetCourse()
        showTextAndButtons = false
    }
    
    func setUp(gameModel: GameViewModel, handler: LocationHandler) {
        generateQRCode(from: gameModel.gameValue.id)
        courseFind(gameModel: gameModel, handler: handler)
    }
    
    func courseFind(gameModel: GameViewModel, handler: LocationHandler ) {
        guard showLocationButton else { return }
        
        if gameModel.getCourse() == nil && !gameModel.getHasLoaded() {
            gameModel.findClosestLocationAndLoadCourse(locationHandler: handler)
            gameModel.setHasLoaded(true)
        }
    }
    
    func timeString() -> String {
        let seconds = Int(timeRemaining)
        
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    func generateQRCode(from string: String) {
        // Offload heavy CoreImage work to avoid blocking first render.
        Task.detached(priority: .utility) {
            let image = Self.makeQRCodeImage(from: string)
            await MainActor.run {
                self.qrCodeImage = image
            }
        }
    }

    nonisolated private static func makeQRCodeImage(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
