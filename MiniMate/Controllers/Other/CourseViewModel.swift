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
    
    private let courseRepo: CourseRepository

    init(courseRepo: CourseRepository = CourseRepository()) {
        self.courseRepo = courseRepo
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
}
