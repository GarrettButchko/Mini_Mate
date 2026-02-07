import Foundation
import SwiftData

@Model
class Game: Equatable {
    @Attribute(.unique) var id: String
    var hostUserId: String
    var date: Date
    var completed: Bool
    var numberOfHoles: Int
    var started: Bool
    var dismissed: Bool
    var live: Bool
    var lastUpdated: Date
    var courseID: String?
    var locationName: String?
    var startTime: Date
    var endTime: Date

    @Relationship(deleteRule: .cascade, inverse: \Player.game)
    var players: [Player] = []

    init(
        id: String = "",
        hostUserId: String = "",
        date: Date = Date(),
        completed: Bool = false,
        numberOfHoles: Int = 18,
        started: Bool = false,
        dismissed: Bool = false,
        live: Bool = false,
        lastUpdated: Date = Date(),
        courseID: String? = nil,
        players: [Player] = [],
        locationName: String? = nil,
        startTime: Date = Date(),
        endTime: Date = Date(),
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

extension Game {
    enum CodingKeys: String, CodingKey {
        case id
        case hostUserId            // ✅ ADD THIS
        case date
        case completed
        case numberOfHoles
        case started
        case dismissed
        case live
        case lastUpdated
        case players
        case courseID
        case locationName
        case startTime
        case endTime
    }
    
    func toDTO() -> GameDTO {
        GameDTO(
            id: id,
            hostUserId: hostUserId,                 // ✅ PASS THIS
            date: date.timeIntervalSince1970,
            completed: completed,
            numberOfHoles: numberOfHoles,
            started: started,
            dismissed: dismissed,
            live: live,
            lastUpdated: lastUpdated.timeIntervalSince1970,
            courseID: courseID,
            players: players.map { $0.toDTO() },
            locationName: locationName,
            startTime: startTime.timeIntervalSince1970,
            endTime: endTime.timeIntervalSince1970
        )
    }

    static func fromDTO(_ dto: GameDTO) -> Game {
        Game(
            id: dto.id,
            hostUserId: dto.hostUserId,             // ✅ SET THIS
            date: Date(timeIntervalSince1970: dto.date),
            completed: dto.completed,
            numberOfHoles: dto.numberOfHoles,
            started: dto.started,
            dismissed: dto.dismissed,
            live: dto.live,
            lastUpdated: Date(timeIntervalSince1970: dto.lastUpdated),
            courseID: dto.courseID,
            players: dto.players.map { Player.fromDTO($0) },
            locationName: dto.locationName,
            startTime: Date(timeIntervalSince1970: dto.startTime),
            endTime: Date(timeIntervalSince1970: dto.endTime)
        )
    }
    
    
    
    var holeInOneLastHole: Bool {
        for player in players {
            for hole in player.holes where hole.number == 18 && hole.strokes == 1 {
                return true
            }
        }
        return false
    }
}

