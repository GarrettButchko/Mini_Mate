//
//  CourseViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/6/25.
//

import MapKit
import SwiftUI

@MainActor
final class CourseViewModel: ObservableObject {

    @Published var nameExists: [String: Bool] = [:]
    @Published var isSupportedLocation: Bool? = nil
    @Published var position: MapCameraPosition = .automatic
    @Published var isUpperHalf: Bool = false
    @Published var hasAppeared = false
    
    private let courseRepo: CourseRepository
    private let locationHandler: LocationHandler

    init(courseRepo: CourseRepository = CourseRepository(), locationHandler: LocationHandler) {
        self.courseRepo = courseRepo
        self.locationHandler = locationHandler
    }

    // MARK: - Marker Coloring
    func preloadNameChecks(for items: [MKMapItem]) {
        for item in items {
            guard
                let name = item.name,
                nameExists[name] == nil
            else { continue }

            courseRepo.courseNameExistsAndSupported(name) { [weak self] exists in
                self?.nameExists[name] = exists
            }
        }
    }

    // MARK: - Selected Result Support
    func updateSupportedLocation(for item: MKMapItem?) {
        guard let name = item?.name else {
            isSupportedLocation = nil
            return
        }

        courseRepo.courseNameExistsAndSupported(name) { [weak self] exists in
            self?.isSupportedLocation = exists
        }
    }
    
    func onAppearance() {
        if !hasAppeared {
            hasAppeared = true
            isUpperHalf = false
            locationHandler.mapItems = []
            locationHandler.selectedItem = nil
            position = locationHandler.updateCameraPosition()
        }
    }
    
    func setPosition(_ position: MapCameraPosition) {
        self.position = position
    }
    
    func searchNearby(){
        withAnimation {
            isUpperHalf.toggle()
            
            locationHandler.searchNearbyCourses { success, newPosition in
                if let newPosition {
                    withAnimation {
                        self.position = newPosition
                    }
                }
            }
        }
    }
    
    func cancel(){
        withAnimation {
            isUpperHalf = false
            locationHandler.mapItems = []
            position = locationHandler.updateCameraPosition()
        }
    }
    
    func updatePosition(mapItem: MKMapItem) {
        withAnimation(){
            locationHandler.setSelectedItem(mapItem)
            position = locationHandler.updateCameraPosition(locationHandler.bindingForSelectedItem().wrappedValue)
        }
    }
    
    func getDirections(){
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        locationHandler.bindingForSelectedItem().wrappedValue?.openInMaps(launchOptions: launchOptions)
    }
}
