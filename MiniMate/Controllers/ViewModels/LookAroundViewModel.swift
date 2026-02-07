//
//  LookAroundViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 7/9/25.
//
import SwiftUI
import MapKit

enum LookAroundResponse: Equatable {
    case idle
    case loading
    case found
    case noSceneFound
    case error(String) // Store the message directly for easy comparison

    static func == (lhs: LookAroundResponse, rhs: LookAroundResponse) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.found, .found), (.noSceneFound, .noSceneFound):
            return true
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

@MainActor
class LookAroundViewModel: ObservableObject {
    @Published var scene: MKLookAroundScene?
    @Published var result: LookAroundResponse = .idle

    func fetchScene(for mapItem: MKMapItem) {
        self.result = .loading
        self.scene = nil
        
        let request = MKLookAroundSceneRequest(mapItem: mapItem)

        Task {
            do {
                let sceneResult = try await request.scene
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if let sceneResult {
                        self.scene = sceneResult
                        self.result = .found
                    } else {
                        self.result = .noSceneFound
                    }
                }
            } catch {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.result = .error(error.localizedDescription)
                }
            }
        }
    }
}

