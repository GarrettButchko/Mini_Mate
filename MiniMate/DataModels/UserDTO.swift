//
//  UserDTO.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/19/25.
//
import Foundation

struct UserDTO: Codable {
    var id: String
    var name: String
    var photoURL: URL?
    var email: String?
    var isPro: Bool
    var gameIDs: [String]
    var lastUpdated: Date
    var accountType: String
    var adminCourses: [String]
}
