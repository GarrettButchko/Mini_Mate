import Foundation
import SwiftData

@Model
class Game: Equatable {
    @Attribute(.unique) var id: String
    var hostUserId: String               // ✅ non-optional
    var location: MapItemDTO?
    var date: Date
    var completed: Bool
    var numberOfHoles: Int
    var started: Bool
    var dismissed: Bool
    var totalTime: Int
    var live: Bool
    var lastUpdated: Date
    var courseID: String?
    var startTime: Date?
    var endTime: Date?

    var holeInOneLastHole: Bool {
        for player in players {
            for hole in player.holes where hole.number == 18 && hole.strokes == 1 {
                return true
            }
        }
        return false
    }

    @Relationship(deleteRule: .cascade, inverse: \Player.game)
    var players: [Player] = []

    enum CodingKeys: String, CodingKey {
        case id
        case hostUserId            // ✅ ADD THIS
        case location
        case date
        case completed
        case numberOfHoles
        case started
        case dismissed
        case totalTime
        case live
        case lastUpdated
        case players
        case courseID
        case startTime
        case endTime
    }

    init(
        id: String = "",
        hostUserId: String = "",        // ✅ required
        location: MapItemDTO? = nil,
        date: Date = Date(),
        completed: Bool = false,
        numberOfHoles: Int = 18,
        started: Bool = false,
        dismissed: Bool = false,
        totalTime: Int = 0,
        live: Bool = false,
        lastUpdated: Date = Date(),
        courseID: String? = nil,
        players: [Player] = [],
        startTime: Date? = nil,
        endTime: Date? = nil
    ) {
        self.id = id
        self.hostUserId = hostUserId
        self.location = location
        self.date = date
        self.completed = completed
        self.numberOfHoles = numberOfHoles
        self.started = started
        self.dismissed = dismissed
        self.totalTime = totalTime
        self.live = live
        self.lastUpdated = lastUpdated
        self.courseID = courseID
        self.players = players
        self.startTime = startTime
        self.endTime = endTime
    }

    func toDTO() -> GameDTO {
        GameDTO(
            id: id,
            hostUserId: hostUserId,                 // ✅ PASS THIS
            location: location,
            date: date.timeIntervalSince1970,
            completed: completed,
            numberOfHoles: numberOfHoles,
            started: started,
            dismissed: dismissed,
            totalTime: totalTime,
            live: live,
            lastUpdated: lastUpdated.timeIntervalSince1970,
            courseID: courseID,
            players: players.map { $0.toDTO() },
            startTime: startTime?.timeIntervalSince1970,
            endTime: endTime?.timeIntervalSince1970
        )
    }

    static func fromDTO(_ dto: GameDTO) -> Game {
        Game(
            id: dto.id,
            hostUserId: dto.hostUserId,             // ✅ SET THIS
            location: dto.location,
            date: Date(timeIntervalSince1970: dto.date),
            completed: dto.completed,
            numberOfHoles: dto.numberOfHoles,
            started: dto.started,
            dismissed: dto.dismissed,
            totalTime: dto.totalTime,
            live: dto.live,
            lastUpdated: Date(timeIntervalSince1970: dto.lastUpdated),
            courseID: dto.courseID,
            players: dto.players.map { Player.fromDTO($0) },
            startTime: dto.startTime.map { Date(timeIntervalSince1970: $0) },
            endTime: dto.endTime.map { Date(timeIntervalSince1970: $0) }
        )
    }
}

