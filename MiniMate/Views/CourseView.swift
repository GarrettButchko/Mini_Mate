//
//  GameView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/6/25.
//

import SwiftUI
import MapKit

// MARK: - CourseView

struct CourseView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var locationHandler: LocationHandler
    
    @EnvironmentObject var viewManager: ViewManager
    @EnvironmentObject var authModel: AuthViewModel
    @StateObject var courseViewModel: CourseViewModel
    
    @StateObject var viewModel = LookAroundViewModel()
    
    init() {
        _courseViewModel = StateObject(
            wrappedValue: CourseViewModel()
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            if locationHandler.hasLocationAccess {
                ZStack {
                    // MARK: - Map
                    mapView
                    
                    // MARK: - Overlay UI
                    VStack {
                        // Top Bar
                        HStack {
                            
                            Text("Course Search")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding()
                                .frame(height: 40)
                                .background(content: {
                                    RoundedRectangle(cornerRadius: 25)
                                        .ifAvailableGlassEffect()
                                })
                            
                            Spacer()
                            
                            LocationButton(cameraPosition: $courseViewModel.position, isUpperHalf: $courseViewModel.isUpperHalf, selectedResult: locationHandler.bindingForSelectedItem(), locationHandler: locationHandler)
                                .shadow(color: Color.black.opacity(0.1), radius: 10)
                        }
                        
                        Spacer()
                        
                        // Bottom Panel
                        if !courseViewModel.isUpperHalf {
                            searchButton
                        } else {
                            
                            VStack{
                                if locationHandler.selectedItem != nil {
                                    resultView
                                        .padding([.horizontal, .top])
                                        .background(content: {
                                            RoundedRectangle(cornerRadius: 25)
                                                .ifAvailableGlassEffect()
                                        })
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                        .clipShape(RoundedRectangle(cornerRadius: 25))
                                } else {
                                    searchResultsView
                                        .padding([.horizontal, .top])
                                        .background(content: {
                                            RoundedRectangle(cornerRadius: 25)
                                                .ifAvailableGlassEffect()
                                        })
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                        .clipShape(RoundedRectangle(cornerRadius: 25))
                                }
                            }
                            .frame(height: geometry.size.height * 0.4)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            
                            
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            } else {
                HStack(alignment: .center){
                    Spacer()
                    VStack(alignment: .center){
                        Spacer()
                        Text("Please enable Location Services for this app.\n\nTap 'Open Settings' → Location → Allow While Using the App.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            courseViewModel.onAppearance(locationHandler: locationHandler)
        }
    }
    
    var mapView: some View {
        Map(position: $courseViewModel.position, selection: locationHandler.bindingForSelectedItem()) {
            withAnimation(){
                ForEach(locationHandler.mapItems, id: \.self) { item in
                    let name = item.name ?? "Unknown"
                    let exists = courseViewModel.nameExists[name] ?? false
                    
                    Marker(name, coordinate: item.placemark.coordinate)
                        .tint(exists ? .purple : .green)
                }
                
            }
            UserAnnotation()
        }
        .onChange(of: locationHandler.selectedItem) { oldValue, newValue in
            withAnimation {
                courseViewModel.setPosition(locationHandler.updateCameraPosition(newValue))
            }
        }
        .onAppear {
            courseViewModel.preloadNameChecks(for: locationHandler.mapItems)
        }
        .onChange(of: locationHandler.mapItems) {
            courseViewModel.preloadNameChecks(for: locationHandler.mapItems)
        }
        .mapControls {
            MapCompass()
                .mapControlVisibility(.hidden)
        }
    }
    
    var searchButton: some View {
        Button {
            courseViewModel.searchNearby(locationHandler: locationHandler)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.blue)
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white)
                    Text("Search for Nearby Courses")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 50)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .shadow(radius: 10)
    }
    
    var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Courses")
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(.mainOpp)
                Spacer()
                Button {
                    courseViewModel.cancel(locationHandler: locationHandler)
                } label: {
                    
                    Text("Cancel")
                        .frame(width: 70, height: 30)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                    
                }
            }
            
            ScrollView {
                VStack(alignment: .leading) {
                    if let userCoord = locationHandler.userLocation {
                        ForEach(locationHandler.mapItems, id: \.self) { mapItem in
                            if locationHandler.mapItems.count > 0 && mapItem != locationHandler.mapItems[0]{
                                Divider()
                            }
                            SearchResultRow(item: mapItem, userLocation: userCoord)
                                .onTapGesture {
                                    courseViewModel.updatePosition(mapItem: mapItem, locationHandler: locationHandler)
                                }
                        }
                    } else {
                        Text("Fetching location...")
                    }
                }
                Rectangle()
                    .fill(.clear)
                    .frame(height: 4)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
    }
    
    var resultView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(locationHandler.selectedItem?.name ?? "")
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(.mainOpp)
                Spacer()
                Button {
                    withAnimation {
                        locationHandler.setSelectedItem(nil)
                    }
                } label: {
                    ZStack {
                        
                        Text("Back")
                            .frame(width: 70, height: 30)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                        
                        
                    }
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Button(action: {
                        courseViewModel.getDirections(locationHandler: locationHandler)
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue)
                            VStack {
                                Image(systemName: "arrow.turn.up.right")
                                    .foregroundColor(.white)
                                Text("Get Directions")
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                            .padding()
                        }
                    }
                    .onChange(of: locationHandler.bindingForSelectedItem().wrappedValue) { _ , newItem in
                        courseViewModel.updateSupportedLocation(for: newItem)
                    }
                    
                    if let supported = courseViewModel.isSupportedLocation, supported == true {
                        HStack{
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Image("logoOpp")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                    Text("Supported Location")
                                        .font(.headline)
                                }
                                
                                if let name = locationHandler.bindingForSelectedItem().wrappedValue?.name {
                                    Text("\(name) is a Mini Mate officially supported location, meaning par information and more are available here!")
                                        .font(.callout)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.purple.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    
                    
                    // MARK: - Contact Info
                    
                    
                    Group{
                        switch viewModel.result {
                        case .loading:
                            HStack {
                                Spacer()
                                ProgressView("Loading Look Around...")
                                Spacer()
                            }
                            .frame(height: 100)
                            
                        case .found:
                            LookAroundPreview(scene: $viewModel.scene)
                                .frame(height: 200) // Keep height consistent
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.1), radius: 10)
                            
                        case .error(let message):
                            Text(message)
                                .padding()
                                .background(colorScheme == .light
                                            ? AnyShapeStyle(Color.white)
                                            : AnyShapeStyle(.ultraThinMaterial))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .noSceneFound:
                            EmptyView()
                        case .idle:
                            EmptyView()
                        }
                    }
                    
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "phone.fill")
                                Text("Contact")
                                    .font(.headline)
                            }
                            
                            if let selected = locationHandler.bindingForSelectedItem().wrappedValue {
                                if let phone = selected.phoneNumber,
                                   let phoneURL = URL(string: "tel://\(phone.filter { $0.isNumber })") {
                                    Link(destination: phoneURL) {
                                        HStack{
                                            Spacer()
                                            Label("Call \(phone)", systemImage: "phone")
                                                .font(.callout)
                                                .foregroundColor(.white)
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 6)
                                        .background(Color.green)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                                
                                if let url = selected.url {
                                    Link(destination: url) {
                                        HStack{
                                            Spacer()
                                            Label("Visit Website", systemImage: "safari")
                                                .font(.callout)
                                                .foregroundColor(.white)
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                        .shadow(color: Color.black.opacity(0.1), radius: 10)
                        Spacer()
                    }
                    .padding()
                    .background(colorScheme == .light
                                ? AnyShapeStyle(Color.white)
                                : AnyShapeStyle(.ultraThinMaterial))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    
                    // MARK: - Location Info
                    
                    HStack{
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: "mappin")
                                Text("Location")
                                    .font(.headline)
                            }
                            if let name = locationHandler.bindingForSelectedItem().wrappedValue?.name {
                                Text(name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            if let selectedResult = locationHandler.bindingForSelectedItem().wrappedValue {
                                Text(locationHandler.getPostalAddress(from: selectedResult))
                                    .font(.callout)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(colorScheme == .light
                                ? AnyShapeStyle(Color.white)
                                : AnyShapeStyle(.ultraThinMaterial))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button {
                        // later: open URL
                    } label: {
                        HStack {
                            Image(systemName: "safari.fill")
                            Text("This your Course? Click to Claim!")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.mainOpp)
                    }
                    .background(colorScheme == .light
                                ? AnyShapeStyle(Color.white)
                                : AnyShapeStyle(.ultraThinMaterial))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                }
                .onAppear {
                    if let selected = locationHandler.selectedItem {
                        viewModel.fetchScene(for: selected)
                    }
                }
                .onChange(of: locationHandler.selectedItem) { oldItem, newItem in
                    if let newItem = newItem {
                        viewModel.fetchScene(for: newItem)
                    }
                }
                
                Rectangle()
                    .fill(.clear)
                    .frame(height: 8)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
    }
}

// MARK: - LocationButton

struct LocationButton: View {
    @Binding var cameraPosition: MapCameraPosition
    @Binding var isUpperHalf: Bool
    @Binding var selectedResult: MKMapItem?
    @ObservedObject var locationHandler: LocationHandler
    
    var body: some View {
        Button(action: {
            withAnimation {
                cameraPosition = locationHandler.updateCameraPosition(selectedResult)
            }
        }) {
            ZStack {
                Circle()
                    .ifAvailableGlassEffect()
                    .frame(width: 40, height: 40)
                
                Image(systemName: "location.fill")
                    .resizable()
                    .foregroundColor(.mainOpp)
                    .frame(width: 20, height: 20)
            }
        }
    }
    
    
}

import MarqueeText
// MARK: - SearchResultRow

struct SearchResultRow: View {
    let item: MKMapItem
    let userLocation: CLLocationCoordinate2D
    @State private var isSupported: Bool = false
    let courseRepo = CourseRepository()
    
    var body: some View {
        HStack{
            VStack(alignment: .leading) {
                
                MarqueeText(
                    text: "\(item.name ?? "Unknown Place")",
                    font: UIFont.preferredFont(forTextStyle: .headline),
                    leftFade: 16,
                    rightFade: 16,
                    startDelay: 3 // recommend 1–2 seconds for a subtle Apple-like pause
                )
                
                let offsetLat = userLocation.latitude - 0.015
                let distanceInMiles = CLLocation(latitude: offsetLat, longitude: userLocation.longitude)
                    .distance(from: CLLocation(latitude: item.placemark.coordinate.latitude,
                                               longitude: item.placemark.coordinate.longitude)) / 1609.34
                
                
                MarqueeText(
                    text: "\(String(format: "%.1f", distanceInMiles)) mi - \(getPostalAddress(from: item))",
                    font: UIFont.preferredFont(forTextStyle: .subheadline),
                    leftFade: 16,
                    rightFade: 16,
                    startDelay: 4 // recommend 1–2 seconds for a subtle Apple-like pause
                )
            }
            .frame(height: 50)
            Spacer()
            
            if isSupported{
                Image(systemName: "star.fill")
                    .foregroundStyle(.purple)
            }
        }
        .onAppear(){
            preloadNameChecks()
        }
        .onChange(of: item) { _, _ in
            preloadNameChecks()
        }
    }
    
    func preloadNameChecks() {
        if let name = item.name {
            courseRepo.courseNameExistsAndSupported(name) { exists in
                if exists {
                    DispatchQueue.main.async {
                        isSupported = true
                    }
                }
            }
        }
    }
    
    private func getPostalAddress(from mapItem: MKMapItem) -> String {
        let placemark = mapItem.placemark
        var components: [String] = []
        
        if let subThoroughfare = placemark.subThoroughfare { components.append(subThoroughfare) }
        if let thoroughfare = placemark.thoroughfare { components.append(thoroughfare) }
        if let locality = placemark.locality { components.append(locality) }
        if let administrativeArea = placemark.administrativeArea { components.append(administrativeArea) }
        
        return components.joined(separator: ", ")
    }
}

