//
//  LookAroundViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 7/9/25.
//
import SwiftUI
import MapKit


class LookAroundViewModel: ObservableObject {
    @Published var scene: MKLookAroundScene?

    func fetchScene(for mapItem: MKMapItem) {
        let request = MKLookAroundSceneRequest(mapItem: mapItem)

        Task {
            if let result = try? await request.scene {
                await MainActor.run {
                    self.scene = result
                }
            }
        }
    }
}

