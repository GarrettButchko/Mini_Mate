//
//  GameDTO.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/19/25.
//
import Foundation

struct GameDTO: Codable {
    var id: String
    var location: MapItemDTO?
    var date: Double
    var completed: Bool
    var numberOfHoles: Int
    var started: Bool
    var dismissed: Bool
    var totalTime: Int
    var live: Bool
    var lastUpdated: Double
    var courseID: String? // <-- Added here
    var players: [PlayerDTO]
    var startTime: Double?
    var endTime: Double?

    enum CodingKeys: String, CodingKey {
        case id, location, date, completed,
             numberOfHoles, started, dismissed,
             totalTime, live, lastUpdated,
             courseID, // <-- Added here
             players, endTime, startTime
    }

    // Decode missing fields gracefully
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(String.self,                 forKey: .id)
        location       = try c.decodeIfPresent(MapItemDTO.self,   forKey: .location)
        date           = try c.decodeIfPresent(Double.self,         forKey: .date)          ?? 0
        completed      = try c.decodeIfPresent(Bool.self,         forKey: .completed)     ?? false
        numberOfHoles  = try c.decodeIfPresent(Int.self,          forKey: .numberOfHoles) ?? 0
        started        = try c.decodeIfPresent(Bool.self,         forKey: .started)       ?? false
        dismissed      = try c.decodeIfPresent(Bool.self,         forKey: .dismissed)     ?? false
        totalTime      = try c.decodeIfPresent(Int.self,          forKey: .totalTime)     ?? 0
        live           = try c.decodeIfPresent(Bool.self,         forKey: .live)          ?? false
        lastUpdated    = try c.decodeIfPresent(Double.self,         forKey: .lastUpdated)   ?? 0
        courseID       = try c.decodeIfPresent(String.self,       forKey: .courseID)      ?? nil // <-- Added here
        players        = try c.decodeIfPresent([PlayerDTO].self,  forKey: .players)       ?? []
        startTime    = try c.decodeIfPresent(Double.self,         forKey: .startTime)   ?? 0
        endTime    = try c.decodeIfPresent(Double.self,         forKey: .endTime)   ?? 0
    }

    // Memberwise initializer
    init(
        id: String,
        location: MapItemDTO? = nil,
        date: Double,
        completed: Bool,
        numberOfHoles: Int,
        started: Bool,
        dismissed: Bool,
        totalTime: Int,
        live: Bool,
        lastUpdated: Double,
        courseID: String?, // <-- Added here
        players: [PlayerDTO],
        startTime: Double?,
        endTime: Double?
    ) {
        self.id             = id
        self.location       = location
        self.date           = date
        self.completed      = completed
        self.numberOfHoles  = numberOfHoles
        self.started        = started
        self.dismissed      = dismissed
        self.totalTime      = totalTime
        self.live           = live
        self.lastUpdated    = lastUpdated
        self.courseID       = courseID // <-- Added here
        self.players        = players
        self.startTime      = startTime
        self.endTime        = endTime
    }
}
