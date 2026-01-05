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
    @Attribute(.unique) var googleId: String
    var appleId: String?
    var name: String
    var photoURL: URL?
    var email: String?
    var isPro: Bool = false
    var gameIDs: [String] = []
    var lastUpdated: Date
    var accountType: String
    var adminCourses: [String] = []

    init(
        googleId: String,
        appleId: String? = nil,
        name: String,
        photoURL: URL? = nil,
        email: String? = nil,
        isPro: Bool = false,
        gameIDs: [String] = [],
        lastUpdated: Date = .now,
        accountType: String,
        adminCourses: [String] = []
    ) {
        self.googleId = googleId
        self.appleId = appleId
        self.name = name
        self.photoURL = photoURL
        self.email = email
        self.isPro = isPro
        self.gameIDs = gameIDs
        self.lastUpdated = lastUpdated
        self.accountType = accountType
        self.adminCourses = adminCourses
    }

    static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        return lhs.googleId == rhs.googleId
    }

    func toDTO() -> UserDTO {
        return UserDTO(
            googleId: googleId,
            appleId: appleId,
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
            googleId: dto.googleId,
            appleId: dto.appleId,
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

