//
//  Course.swift
//  MiniMate
//

import Foundation

struct Course: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var password: String
    var isClaimed: Bool
    
    var supported: Bool
    
    var logo: String?
    var scoreCardColorDT: String?
    var courseColorsDT: [String]? = []
    
    var link: String?
    
    var pars: [Int]?
    
    var tier: Int?
    var adminIDs: [String]?
    
    var customAdActive: Bool
    var adTitle: String?
    var adDescription: String?
    var adLink: String?
    var adImage: String?
    
    // MARK: - Init
    init(
        id: String = "",
        name: String = "",
        supported: Bool = false,
        password: String = PasswordGenerator.generate(.strong()),
        logo: String? = nil,
        scoreCardColorDT: String? = nil,
        link: String? = nil,
        pars: [Int]? = nil,
        adActive: Bool = false,
        adTitle: String? = nil,
        adDescription: String? = nil,
        adLink: String? = nil,
        adImage: String? = nil,
        tier: Int? = 1,
        adminIDs: [String]? = [],
        isClaimed: Bool = false,
        courseColorsDT: [String]? = []
    ) {
            self.id = id
            self.name = name
            self.supported = supported
            self.logo = logo
            self.scoreCardColorDT = scoreCardColorDT
            self.link = link
            self.pars = pars
            self.customAdActive = adActive
            self.adTitle = adTitle
            self.adDescription = adDescription
            self.adLink = adLink
            self.adImage = adImage
            self.tier = tier
            self.password = password
            self.adminIDs = adminIDs
            self.isClaimed = isClaimed
            self.courseColorsDT = courseColorsDT
    }
    
    static func == (lhs: Course, rhs: Course) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.logo == rhs.logo &&
        lhs.scoreCardColorDT == rhs.scoreCardColorDT &&
        lhs.link == rhs.link &&
        lhs.pars == rhs.pars &&
        lhs.adTitle == rhs.adTitle &&
        lhs.adDescription == rhs.adDescription &&
        lhs.adLink == rhs.adLink &&
        lhs.adImage == rhs.adImage &&
        lhs.tier == rhs.tier &&
        lhs.password == rhs.password &&
        lhs.supported == rhs.supported &&
        lhs.adminIDs == rhs.adminIDs &&
        lhs.customAdActive == rhs.customAdActive &&
        lhs.isClaimed == rhs.isClaimed &&
        lhs.courseColorsDT == rhs.courseColorsDT
    }
}

struct DailyCount: Codable, Equatable {
    var dayID: String = ""           // e.g. "2026-01-03"
    var gamesPlayed: Int = 0
    var newPlayers: Int = 0
    var returningPlayers: Int = 0
    var updatedAt: Date? = nil

    var activeUsers: Int { newPlayers + returningPlayers }
}

struct WeeklyAnalytics: Codable, Equatable {
    var weekID: String = ""
    var peakAnalytics: PeakAnalytics = PeakAnalytics()
    var holeAnalytics: HoleAnalytics = HoleAnalytics()
    var roundTimeAnalytics: RoundTimeAnalytics = RoundTimeAnalytics()
    var updatedAt: Date? = nil
}

// For peak times for each 1 value added is one person who started playing at that time and day
struct PeakAnalytics: Codable, Equatable {
    var hourlyCounts: [Int] = Array(repeating: 0, count: 24)
    var dailyCounts: [Int] = Array(repeating: 0, count: 7)
}

// finds the total number of strokes per hole in a given week, as well as the number of times that hole has been played, then it finds the average strokes per hole that week
struct HoleAnalytics: Codable, Equatable {
    var totalStrokesPerHole: [Int] = []
    var playsPerHole: [Int] = []

    mutating func ensureCount(_ n: Int) {
        if totalStrokesPerHole.count != n { totalStrokesPerHole = Array(repeating: 0, count: n) }
        if playsPerHole.count != n { playsPerHole = Array(repeating: 0, count: n) }
    }

    func averagePerHole() -> [Double] {
        zip(totalStrokesPerHole, playsPerHole).map { total, plays in
            plays > 0 ? Double(total) / Double(plays) : 0
        }
    }
}
// finds total round time in seconds
struct RoundTimeAnalytics: Codable, Equatable {
    var totalRoundSeconds: Int = 0          // cumulative total time of all rounds
}

struct EmailDT: Codable, Equatable {
    var email: String
    var addedAt: Date
}

