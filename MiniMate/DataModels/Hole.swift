// Models.swift
import Foundation
import SwiftData

@Model
class Hole: Equatable, Identifiable {
    @Attribute(.unique) var id: String = UUID().uuidString
    var number: Int
    var strokes: Int
    
    @Relationship(deleteRule: .nullify)
    var player: Player?
    
    init(
        id: String = UUID().uuidString,
        number: Int,
        strokes: Int = 0
    ) {
        self.id      = id
        self.number  = number
        self.strokes = strokes
    }
}

extension Hole {
    
    enum CodingKeys: String, CodingKey {
        case id, number, strokes
    }
    
    static func == (lhs: Hole, rhs: Hole) -> Bool {
        lhs.id == rhs.id &&
        lhs.number == rhs.number &&
        lhs.strokes == rhs.strokes
    }
    
    func toDTO() -> HoleDTO {
        return HoleDTO(
            id: id,
            number: number,
            strokes: strokes
        )
    }

    static func fromDTO(_ dto: HoleDTO) -> Hole {
        return Hole(
            id: dto.id,
            number: dto.number,
            strokes: dto.strokes
        )
    }
}




