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
        
        let location = CLLocation(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude)
        
        var address: MKAddress? = nil
        
        if let fullAddress = self.address?.fullAddress {
            address = MKAddress(fullAddress: fullAddress, shortAddress: self.address?.shortAddress)
        }
        
        let item = MKMapItem(location: location, address: address)
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

extension MKMapItem {
    
    var idString: String {
        "\(location.coordinate.latitude)-\(location.coordinate.longitude)-\(name ?? "")"
    }
    
    var newAddress: AddressDTO? {
        if let address = self.address {
            return AddressDTO(fullAddress: address.fullAddress, shortAddress: address.shortAddress)
        } else {
            return nil
        }
    }
    
    func toDTO() -> MapItemDTO {
        return MapItemDTO(
            name: self.name,
            poiCategory: self.pointOfInterestCategory?.rawValue,
            phoneNumber: self.phoneNumber,
            timeZone: self.timeZone?.identifier,
            url: self.url?.absoluteString,
            address: newAddress,
            coordinate: CoordinateDTO(latitude: self.location.coordinate.latitude, longitude: self.location.coordinate.latitude)
        )
    }
}
