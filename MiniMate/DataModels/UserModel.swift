//
//  UserModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/2/25.
//


import SwiftData
import Foundation

@Model
class UserModel: Identifiable, Equatable {
    @Attribute(.unique) var id: String
    var name: String
    var photoURL: URL?
    var email: String?
    var isPro: Bool = false
    var gameIDs: [String] = []
    var lastUpdated: Date
    var accountType: String
    var adminCourses: [String] = []

    enum CodingKeys: String, CodingKey {
        case id, name, photoURL, email, isPro, gameIDs, lastUpdated, accountType, adminCourses
    }

    init(
        id: String,
        name: String,
        photoURL: URL? = nil,
        email: String? = nil,
        isPro: Bool = false,
        gameIDs: [String] = [],
        lastUpdated: Date = Date(),
        accountType: String,
        adminCourses: [String] = []
    ) {
        self.id = id
        self.name = name
        self.photoURL = photoURL
        self.email = email
        self.isPro = isPro
        self.gameIDs = gameIDs
        self.lastUpdated = lastUpdated
        self.accountType = accountType
        self.adminCourses = adminCourses
    }

    func toDTO() -> UserDTO {
        return UserDTO(
            id: id,
            name: name,
            photoURL: photoURL,
            email: email,
            isPro: isPro,
            gameIDs: gameIDs,
            lastUpdated: lastUpdated,
            accountType: accountType,
            adminCourses: adminCourses
        )
    }

    static func fromDTO(_ dto: UserDTO) -> UserModel {
        return UserModel(
            id: dto.id,
            name: dto.name,
            photoURL: dto.photoURL,
            email: dto.email,
            isPro: dto.isPro,
            gameIDs: dto.gameIDs,
            lastUpdated: dto.lastUpdated,
            accountType: dto.accountType,
            adminCourses: dto.adminCourses
        )
    }
}
