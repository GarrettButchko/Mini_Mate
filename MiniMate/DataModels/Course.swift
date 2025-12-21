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
    
    // Analytics
    var emails: [String]?
    var dailyCount: [String : DailyCount]?
    var peakAnalytics: PeakAnalytics?
    var holeAnalytics: HoleAnalytics?
    var roundTimeAnalytics: RoundTimeAnalytics?
    
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
        emails: [String]? = [],
        dailyCount: [String : DailyCount] = [:],
        peakAnalytics: PeakAnalytics = PeakAnalytics(),
        holeAnalytics: HoleAnalytics = HoleAnalytics(),
        roundTimeAnalytics: RoundTimeAnalytics = RoundTimeAnalytics(),
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
            self.emails = emails
            self.dailyCount = dailyCount
            self.peakAnalytics = peakAnalytics
            self.holeAnalytics = holeAnalytics
            self.roundTimeAnalytics = roundTimeAnalytics
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
        lhs.emails == rhs.emails &&
        lhs.dailyCount == rhs.dailyCount &&
        lhs.peakAnalytics == rhs.peakAnalytics &&
        lhs.holeAnalytics == rhs.holeAnalytics &&
        lhs.roundTimeAnalytics == rhs.roundTimeAnalytics &&
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
    var activeUsers: Int {
        newPlayers + returningPlayers
    }        // number of users active that day
    var gamesPlayed: Int = 0        // optional metric
    var newPlayers: Int = 0         // optional metric
    var returningPlayers: Int = 0         // optional metric
}

struct PeakAnalytics: Codable, Equatable {
    // 24 integers (index 0 = 12AM–1AM, ... index 23 = 11PM–12AM)
    var hourlyCounts: [Int] = Array(repeating: 0, count: 24)
    // 7 integers (index 0 = Sunday, 6 = Saturday)
    var dailyCounts: [Int] = Array(repeating: 0, count: 7)
}

struct HoleAnalytics: Codable, Equatable {
    var totalStrokesPerHole: [Int] = Array(repeating: 0, count: 20)    // e.g., [totalHole1, totalHole2, ...]
    var playsPerHole: [Int] = Array(repeating: 0, count: 20)          // e.g., [numPlaysHole1, numPlaysHole2, ...]
    
    /// Returns the average score per hole
    func averagePerHole() -> [Double] {
        zip(totalStrokesPerHole, playsPerHole).map { total, plays in
            plays > 0 ? Double(total) / Double(plays) : 0
        }
    }
}

struct RoundTimeAnalytics: Codable, Equatable {
    var totalRoundSeconds: Int = 0          // cumulative total time of all rounds
    
    /// Returns the average round time in seconds
    func averageRoundTime(for course: Course) -> Double {
        var sumTotalGames: Int = 0
        if let dailyCount = course.dailyCount {
            // Sum gamesPlayed across all DailyCount values in the dictionary
            for value in dailyCount.values {
                sumTotalGames += value.gamesPlayed
            }
        }
        if sumTotalGames > 0 {
            return Double(totalRoundSeconds) / Double(sumTotalGames)
        } else {
            return 0
        }
    }
}


struct CourseLeaderboard: Codable, Identifiable {
    var id: String
    var allPlayers: [PlayerDTO]
    
    enum CodingKeys: String, CodingKey {
        case id
        case allPlayers
    }
    
    init(id: String = "", allPlayers: [PlayerDTO] = []) {
        self.id = id
        self.allPlayers = allPlayers
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        
        // ⭐ The important part:
        allPlayers = (try? container.decode([PlayerDTO].self, forKey: .allPlayers)) ?? []
    }
    
    var leaderBoard: [PlayerDTO] {
        allPlayers.sorted { $0.totalStrokes < $1.totalStrokes }
    }
}

