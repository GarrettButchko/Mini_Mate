import Foundation
import SwiftData

@Model
class Game: Equatable {
    @Attribute(.unique) var id: String
    var location: MapItemDTO?
    var date: Date
    var completed: Bool
    var numberOfHoles: Int
    var started: Bool
    var dismissed: Bool
    var totalTime: Int
    var live: Bool
    var lastUpdated: Date
    var courseID: String?  // <-- Added courseID
    var startTime: Date?
    var endTime: Date?
    
    var holeInOneLastHole: Bool {
        var temp = false
        for player in players {
            for hole in player.holes {
                if hole.number == 18 && hole.strokes == 1 {
                    temp = true
                }
            }
        }
        return temp
    }

    @Relationship(deleteRule: .cascade, inverse: \Player.game)
    var players: [Player] = []

    enum CodingKeys: String, CodingKey {
        case id, location, date, completed,
             numberOfHoles, started, dismissed,
             totalTime, live, lastUpdated,
             players, courseID, editOn, startTime, endTime  // <-- added courseID
    }

    init(
        id: String = "",
        location: MapItemDTO? = nil,
        date: Date = Date(),
        completed: Bool = false,
        numberOfHoles: Int = 18,
        started: Bool = false,
        dismissed: Bool = false,
        totalTime: Int = 0,
        live: Bool = false,
        lastUpdated: Date = Date(),
        courseID: String? = nil,  // <-- added courseID to init
        players: [Player] = [],
        startTime: Date? = nil,
        endTime: Date? = nil
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
        self.courseID       = courseID  // <-- assign courseID
        self.players        = players
        self.startTime      = startTime
        self.endTime        = endTime
    }

    func toDTO() -> GameDTO {
        return GameDTO(
            id: id,
            location: location,
            date: date.timeIntervalSince1970,
            completed: completed,
            numberOfHoles: numberOfHoles,
            started: started,
            dismissed: dismissed,
            totalTime: totalTime,
            live: live,
            lastUpdated: lastUpdated.timeIntervalSince1970,
            courseID: courseID,  // <-- include courseID
            players: players.map { $0.toDTO() },
            startTime: startTime?.timeIntervalSince1970,
            endTime: endTime?.timeIntervalSince1970
        )
    }

    static func fromDTO(_ dto: GameDTO) -> Game {
        return Game(
            id: dto.id,
            location: dto.location,
            date: Date(timeIntervalSince1970: dto.date),
            completed: dto.completed,
            numberOfHoles: dto.numberOfHoles,
            started: dto.started,
            dismissed: dto.dismissed,
            totalTime: dto.totalTime,
            live: dto.live,
            lastUpdated: Date(timeIntervalSince1970: dto.lastUpdated),
            courseID: dto.courseID,  // <-- include courseID
            players: dto.players.map { Player.fromDTO($0) },
            startTime: Date(timeIntervalSince1970: dto.startTime ?? 0),
            endTime: Date(timeIntervalSince1970: dto.endTime ?? 0)
        )
    }
}
