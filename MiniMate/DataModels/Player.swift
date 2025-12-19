//
//  Player.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/2/25.
//

// Models.swift
import Foundation
import SwiftData

@Model
class Player: Identifiable, Equatable {
    @Attribute(.unique) var id: String = UUID().uuidString
    var userId: String
    var inGame: Bool = false
    var name: String
    var photoURL: URL?
    var email: String?
    
    // Computed property: sum of strokes across all holes
    var totalStrokes: Int {
        holes.reduce(0) { $0 + $1.strokes }
    }
    
    var incomplete: Bool {
        for hole in holes {
            if (hole.strokes == 0) {
                return true
            }
        }
        return false
    }

    @Relationship(deleteRule: .nullify)
    var game: Game?

    @Relationship(deleteRule: .cascade, inverse: \Hole.player)
    var holes: [Hole] = []

    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id &&
        lhs.userId == rhs.userId &&
        lhs.name == rhs.name &&
        lhs.photoURL == rhs.photoURL &&
        lhs.inGame == rhs.inGame &&
        lhs.holes == rhs.holes &&
        lhs.email == rhs.email
    }

    enum CodingKeys: String, CodingKey {
        case id, userId, name, photoURL, inGame, holes, email
    }

    init(
        id: String = UUID().uuidString,
        userId: String,
        name: String,
        photoURL: URL? = nil,
        inGame: Bool = false,
        holes: [Hole] = [],
        email: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.photoURL = photoURL
        self.inGame = inGame
        self.holes = holes
        self.email = email

        for hole in self.holes {
            hole.player = self
        }
    }

    func toDTO() -> PlayerDTO {
        return PlayerDTO(
            id: id,
            userId: userId,
            name: name,
            photoURL: photoURL,
            totalStrokes: totalStrokes,
            inGame: inGame,
            holes: holes.map { $0.toDTO() },
            email: email
        )
    }

    static func fromDTO(_ dto: PlayerDTO) -> Player {
        return Player(
            id: dto.id,
            userId: dto.userId,
            name: dto.name,
            photoURL: dto.photoURL,
            inGame: dto.inGame,
            holes: dto.holes.map { Hole.fromDTO($0) },
            email: dto.email
        )
    }
}

