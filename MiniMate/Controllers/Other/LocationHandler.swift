//
//  LocationSearch.swift
//  MiniMate
//
//  Created by Garrett Butchko on 1/15/25.
//  Updated: Implement CLLocationManagerDelegate methods to capture user location.

import Contacts
import MapKit
import SwiftUI

class LocationHandler: NSObject, ObservableObject, Observable, CLLocationManagerDelegate {
    @Published var mapItems: [MKMapItem] = []
    @Published var selectedItem: MKMapItem?
    @Published var userLocation: CLLocationCoordinate2D?
    private let manager = CLLocationManager()

    var hasLocationAccess: Bool {
        (manager.authorizationStatus == .authorizedAlways
            || manager.authorizationStatus == .authorizedWhenInUse)
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied/restricted")
        default:
            break
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("Location manager failed: \(error.localizedDescription)")
    }

    // MARK: - Bindings
    func bindingForSelectedItem() -> Binding<MKMapItem?> {
        Binding(
            get: { self.selectedItem },
            set: { self.selectedItem = $0 }
        )
    }

    func bindingForSelectedItemID() -> Binding<String?> {
        Binding(
            get: { self.selectedItem?.idString },
            set: { newID in
                self.selectedItem = self.mapItems.first(where: {
                    $0.idString == newID
                })
            }
        )
    }

    func setSelectedItem(_ item: MKMapItem?) {
        selectedItem = item
    }

    // MARK: - Search
    func performSearch(
        in region: MKCoordinateRegion,
        completion: @escaping (Bool) -> Void
    ) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "mini golf"
        request.region = region
        if #available(iOS 18.0, *) {
            request.pointOfInterestFilter = .init(including: [.miniGolf])
        }

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("Error during search: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false) }
                return
            }
            guard let items = response?.mapItems else {
                print("No response or no mapItems.")
                DispatchQueue.main.async { completion(false) }
                return
            }

            let sorted: [MKMapItem]
            if let coord = self.userLocation {
                let userLoc = CLLocation(
                    latitude: coord.latitude,
                    longitude: coord.longitude
                )
                sorted = items.sorted { a, b in
                    let la = CLLocation(
                        latitude: a.placemark.coordinate.latitude,
                        longitude: a.placemark.coordinate.longitude
                    )
                    let lb = CLLocation(
                        latitude: b.placemark.coordinate.latitude,
                        longitude: b.placemark.coordinate.longitude
                    )
                    return la.distance(from: userLoc)
                        < lb.distance(from: userLoc)
                }
            } else {
                sorted = items
            }

            DispatchQueue.main.async {
                withAnimation(){
                    self.mapItems = sorted
                }
                completion(true)
            }
        }
    }
    
    func searchNearbyCourses(
        upwardOffset: CLLocationDegrees = 0.03,
        span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1),
        completion: @escaping (Bool, MapCameraPosition?) -> Void
    ) {
        guard let userLocation else {
            completion(false, nil)
            return
        }

        let adjustedCoordinate = CLLocationCoordinate2D(
            latitude: userLocation.latitude + upwardOffset,
            longitude: userLocation.longitude
        )

        let region = MKCoordinateRegion(
            center: adjustedCoordinate,
            span: span
        )

        performSearch(in: region) { success in
            let newPosition = success ? self.updateCameraPosition(nil) : nil
            completion(success, newPosition)
        }
    }

    func findClosestMiniGolf(completion: @escaping (MKMapItem?) -> Void) {
        guard let userLoc = userLocation else {
            completion(nil)
            return
        }

        let region = makeRegion(centeredOn: userLoc, radiusInMeters: 8046.72)  // 5 miles in meters

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "mini golf"
        request.region = region
        if #available(iOS 18.0, *) {
            request.pointOfInterestFilter = .init(including: [.miniGolf])
        }

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard error == nil, let items = response?.mapItems, !items.isEmpty
            else {
                completion(nil)
                return
            }

            let userLocation = CLLocation(
                latitude: userLoc.latitude,
                longitude: userLoc.longitude
            )
            let sorted = items.sorted {
                let a = CLLocation(
                    latitude: $0.placemark.coordinate.latitude,
                    longitude: $0.placemark.coordinate.longitude
                )
                let b = CLLocation(
                    latitude: $1.placemark.coordinate.latitude,
                    longitude: $1.placemark.coordinate.longitude
                )
                return a.distance(from: userLocation)
                    < b.distance(from: userLocation)
            }

            completion(sorted.first)
        }
    }

    // MARK: - Camera Positioning
    func updateCameraPosition(_ selectedResult: MKMapItem? = nil)
        -> MapCameraPosition
    {
        var cameraPosition: MapCameraPosition = .automatic

        if let selected = selectedResult {
            let original = selected.placemark.coordinate
            let adjustedCoordinate = CLLocationCoordinate2D(
                latitude: original.latitude - 0.00042,
                longitude: original.longitude
            )
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: adjustedCoordinate,
                    distance: 500,
                    heading: 0,
                    pitch: 0
                )
            )
        } else if !mapItems.isEmpty {
            if let region = computeBoundingRegion(
                from: mapItems,
                offsetDownward: true
            ) {
                cameraPosition = .region(region)
            }
        } else if let userLoc = userLocation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: userLoc,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.05,
                        longitudeDelta: 0.05
                    )
                )
            )
        }

        return cameraPosition
    }

    private func computeBoundingRegion(
        from items: [MKMapItem],
        offsetDownward: Bool = false
    ) -> MKCoordinateRegion? {
        let coords = items.map { $0.placemark.coordinate }
        guard !coords.isEmpty else { return nil }

        let minLat = coords.map { $0.latitude }.min() ?? 0
        let maxLat = coords.map { $0.latitude }.max() ?? 0
        let minLon = coords.map { $0.longitude }.min() ?? 0
        let maxLon = coords.map { $0.longitude }.max() ?? 0

        // Padding as a fraction of the points' range
        let latRange = maxLat - minLat
        let lonRange = maxLon - minLon
        let topPaddingFactor: Double = 0.15 // 20% extra padding on top
        let bottomPaddingFactor: Double = 0.1 // 10% padding on bottom

        // The points should fit in the top 2/5 (40%) of the region,
        // so expand the total vertical span by dividing by 0.4
        let paddedLatDelta = latRange / 0.5
        let topPadding = paddedLatDelta * topPaddingFactor
        let bottomPadding = paddedLatDelta * bottomPaddingFactor
        let latitudeDelta = paddedLatDelta + topPadding + bottomPadding
        
        let horizontalPaddingPoints: Double = 50

        // Approximate screen width in points (iPhone portrait ≈ 390, iPad bigger)
        let screenWidthPoints = UIScreen.main.bounds.width

        // Convert points → fraction of screen width
        let horizontalPaddingFraction = horizontalPaddingPoints / screenWidthPoints

        // Apply that fraction to longitude span
        let longitudeDelta = lonRange * (1 + horizontalPaddingFraction * 2)

        // Shift center UPWARD so region places points at top
        let regionTop = maxLat + topPadding
        // center = halfway between regionTop and regionBottom, shifted up
        let centerLat = regionTop - latitudeDelta * 0.5
        let centerLon = (minLon + maxLon) / 2

        let span = MKCoordinateSpan(
            latitudeDelta: latitudeDelta,
            longitudeDelta: longitudeDelta
        )

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: span
        )
    }

    // MARK: - Helpers
    func getPostalAddress(from mapItem: MKMapItem) -> String {
        let placemark = mapItem.placemark
        var components: [String] = []
        if let sub = placemark.subThoroughfare { components.append(sub) }
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        if let locality = placemark.locality { components.append(locality) }
        if let area = placemark.administrativeArea { components.append(area) }
        return components.joined(separator: ", ")
    }

    func makeRegion(
        centeredOn coord: CLLocationCoordinate2D,
        radiusInMeters: CLLocationDistance = 5000
    ) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coord,
            latitudinalMeters: radiusInMeters * 2,
            longitudinalMeters: radiusInMeters * 2
        )
    }
}
