//
//  MapItemDTO+MapKit.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/19/25.
//

import MapKit
import Contacts

extension MapItemDTO {
    func dtoToMapItem() -> MKMapItem {
        
        if #available(iOS 26.0, *) {
            
            let location = CLLocation(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude)
            
            var address: MKAddress? = nil
            
            if let fullAddress = self.address?.fullAddress {
                address = MKAddress(fullAddress: fullAddress, shortAddress: self.address?.shortAddress)
            }
            
            let item = MKMapItem(location: location, address: address)
            item.name = self.name
            item.phoneNumber = self.phoneNumber
            item.url = self.url != nil ? URL(string: self.url!) : nil
            
            if let categoryRaw = self.poiCategory {
                item.pointOfInterestCategory = MKPointOfInterestCategory(rawValue: categoryRaw)
            }
            
            if let timeZoneID = self.timeZone {
                item.timeZone = TimeZone(identifier: timeZoneID)
            }
            
            return item
        } else {
            
            let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude))
            
            let item = MKMapItem(placemark: placemark)
            item.name = self.name
            item.phoneNumber = self.phoneNumber
            item.url = self.url != nil ? URL(string: self.url!) : nil
            
            if let categoryRaw = self.poiCategory {
                item.pointOfInterestCategory = MKPointOfInterestCategory(rawValue: categoryRaw)
            }
            
            if let timeZoneID = self.timeZone {
                item.timeZone = TimeZone(identifier: timeZoneID)
            }
            
            return item
        }
    }
}

extension MKMapItem {
    
    
    var idString: String {
        if #available(iOS 26.0, *) {
            "\(location.coordinate.latitude)-\(location.coordinate.longitude)-\(name ?? "")"
        } else {
            "\(placemark.coordinate.latitude)-\(placemark.coordinate.longitude)-\(name ?? "")"
        }
    }
    
    
    
    var newAddress: AddressDTO? {
        if #available(iOS 26.0, *), let address = self.address {
            return AddressDTO(fullAddress: address.fullAddress, shortAddress: address.shortAddress)
        } else if #unavailable(iOS 26.0) {
            if let postalAddress = placemark.postalAddress {
                let street: String = postalAddress.street
                let city: String = postalAddress.city
                let state: String = postalAddress.state
                let postalCode: String = postalAddress.postalCode
                let country: String = postalAddress.country
                
                
                let longAddress: String =
                """
                \(street)
                \(city), \(state) \(postalCode)
                \(country)
                """
                
                let shortAddress: String = "\(street), \(city)"
                
                return AddressDTO(fullAddress: longAddress, shortAddress: shortAddress)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func toDTO() -> MapItemDTO {
        
        if #available(iOS 26.0, *) {
            return MapItemDTO(
                name: self.name,
                poiCategory: self.pointOfInterestCategory?.rawValue,
                phoneNumber: self.phoneNumber,
                timeZone: self.timeZone?.identifier,
                url: self.url?.absoluteString,
                address: newAddress,
                coordinate: CoordinateDTO(latitude: self.location.coordinate.latitude, longitude: self.location.coordinate.latitude)
            )
        } else {
            return MapItemDTO(
                name: self.name,
                poiCategory: self.pointOfInterestCategory?.rawValue,
                phoneNumber: self.phoneNumber,
                timeZone: self.timeZone?.identifier,
                url: self.url?.absoluteString,
                address: newAddress,
                coordinate: CoordinateDTO(latitude: self.placemark.coordinate.latitude, longitude: self.placemark.coordinate.latitude)
            )
        }
    }
}
