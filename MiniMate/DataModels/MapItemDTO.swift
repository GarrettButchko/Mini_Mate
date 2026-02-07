//
//  MapItemDTO.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/2/25.
//
import Foundation

struct MapItemDTO: Codable, Equatable {
    let name: String?
    let phoneNumber: String?
    let url: String?
    let address: AddressDTO?
    let coordinate: CoordinateDTO
}

struct AddressDTO: Codable, Equatable {
    let fullAddress: String
    let shortAddress: String?
}

struct CoordinateDTO: Codable, Equatable {
    let latitude: Double
    let longitude: Double
}
