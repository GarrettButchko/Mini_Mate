//
//  MapItemDTO.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/2/25.
//
import Foundation
import SwiftData
import MapKit
import Contacts

struct MapItemDTO: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let name: String?
    let phoneNumber: String?
    let url: String?
    let poiCategory: String?
    let timeZone: String?

    // Address components
    let street: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let country: String?
    
    static func == (lhs: MapItemDTO, rhs: MapItemDTO) -> Bool {
        lhs.latitude             == rhs.latitude &&
        lhs.longitude            == rhs.longitude &&
        lhs.name                 == rhs.name &&
        lhs.phoneNumber          == rhs.phoneNumber &&
        lhs.url                  == rhs.url &&
        lhs.poiCategory          == rhs.poiCategory &&
        lhs.timeZone             == rhs.timeZone &&
        lhs.street               == rhs.street &&
        lhs.city                 == rhs.city &&
        lhs.state                == rhs.state &&
        lhs.postalCode           == rhs.postalCode &&
        lhs.country              == rhs.country
    }
    
    func dtoToMapItem() -> MKMapItem {
        let coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)

        let address = CNMutablePostalAddress()
        address.street = self.street ?? ""
        address.city = self.city ?? ""
        address.state = self.state ?? ""
        address.postalCode = self.postalCode ?? ""
        address.country = self.country ?? ""

        let placemark = MKPlacemark(coordinate: coordinate, postalAddress: address)

        let item = MKMapItem(placemark: placemark)
        item.name = self.name
        item.phoneNumber = self.phoneNumber
        item.url = self.url != nil ? URL(string: self.url!) : nil

        if #available(iOS 13.0, *), let categoryRaw = self.poiCategory {
            item.pointOfInterestCategory = MKPointOfInterestCategory(rawValue: categoryRaw)
        }

        if let timeZoneID = self.timeZone {
            item.timeZone = TimeZone(identifier: timeZoneID)
        }

        return item
    }
}
