
//
//  GameDTO.swift
//  MiniMate
//

import Foundation

struct GameDTO: Codable {
    var id: String
    var hostUserId: String          // ✅ NEW (optional for backward compatibility
    var date: Double
    var completed: Bool
    var numberOfHoles: Int
    var started: Bool
    var dismissed: Bool
    var live: Bool
    var lastUpdated: Double
    var courseID: String?
    var players: [PlayerDTO]
    var locationName: String?
    var startTime: Double
    var endTime: Double

    enum CodingKeys: String, CodingKey {
        case id
        case hostUserId              // ✅ NEW
        case date
        case completed
        case numberOfHoles
        case started
        case dismissed
        case live
        case lastUpdated
        case courseID
        case players
        case locationName
        case startTime
        case endTime
    }

    // MARK: - Decoder (backward safe)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id            = try c.decode(String.self, forKey: .id)
        hostUserId    = try c.decode(String.self, forKey: .hostUserId) // ✅
        date          = try c.decodeIfPresent(Double.self, forKey: .date) ?? 0
        completed     = try c.decodeIfPresent(Bool.self, forKey: .completed) ?? false
        numberOfHoles = try c.decodeIfPresent(Int.self, forKey: .numberOfHoles) ?? 0
        started       = try c.decodeIfPresent(Bool.self, forKey: .started) ?? false
        dismissed     = try c.decodeIfPresent(Bool.self, forKey: .dismissed) ?? false
        live          = try c.decodeIfPresent(Bool.self, forKey: .live) ?? false
        lastUpdated   = try c.decodeIfPresent(Double.self, forKey: .lastUpdated) ?? 0
        courseID      = try c.decodeIfPresent(String.self, forKey: .courseID)
        players       = try c.decodeIfPresent([PlayerDTO].self, forKey: .players) ?? []
        locationName = try c.decodeIfPresent(String.self, forKey: .locationName)
        startTime     = try c.decodeIfPresent(Double.self, forKey: .startTime) ?? Date().timeIntervalSince1970
        endTime       = try c.decodeIfPresent(Double.self, forKey: .endTime) ?? Date().timeIntervalSince1970
    }

    // MARK: - Memberwise init
    init(
        id: String,
        hostUserId: String,         // ✅ NEW
        date: Double,
        completed: Bool,
        numberOfHoles: Int,
        started: Bool,
        dismissed: Bool,
        live: Bool,
        lastUpdated: Double,
        courseID: String?,
        players: [PlayerDTO],
        locationName: String? = nil,
        startTime: Double,
        endTime: Double
    ) {
        self.id = id
        self.hostUserId = hostUserId
        self.date = date
        self.completed = completed
        self.numberOfHoles = numberOfHoles
        self.started = started
        self.dismissed = dismissed
        self.live = live
        self.lastUpdated = lastUpdated
        self.courseID = courseID
        self.players = players
        self.locationName = locationName
        self.startTime = startTime
        self.endTime = endTime
    }
}
