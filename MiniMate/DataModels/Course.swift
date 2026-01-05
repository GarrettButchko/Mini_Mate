//
//  Course.swift
//  MiniMate
//

import Foundation

struct Course: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var password: String
    var isClaimed: Bool = false

    var supported: Bool = false

    var logo: String?
    var scoreCardColorDT: String?
    var courseColorsDT: [String]? = []
    
    var pars: [Int]?
    
    var socialLinks: [String: String]?
    var link: String?
    
    // location & context
    var latitude: Double
    var longitude: Double
    var isSeasonal: Bool?
    var indoor: Bool?

    // admin stuff
    var tier: Int = 1
    var adminIDs: [String] = []

    //custom ad
    var customAdActive: Bool = false
    var adTitle: String?
    var adDescription: String?
    var adLink: String?
    var adImage: String?
    var adClicks: Int?
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

