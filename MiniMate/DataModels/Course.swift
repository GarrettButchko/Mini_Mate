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

struct DailyDoc: Codable, Equatable {
    var dayID: String = ""                 // e.g. "2026-01-03"
    var weekID: String = ""                // e.g  "2026-W01"
    var weekDay: Int = 0                   // e.g  "1 = Sunday, 2 = Monday, etc"
    var totalRoundSeconds: Int64 = 0
    var gamesPlayed: Int = 0
    var newPlayers: Int = 0
    var returningPlayers: Int = 0
    
    var holeAnalytics: HoleAnalytics = HoleAnalytics()
    var hourlyCounts: [String: Int] = [:]
    var updatedAt: Date? = nil
    
    init(dayID: String = "") {
        self.dayID = dayID
        self.weekID = Self.isoWeekID(from: dayID) ?? ""
        self.weekDay = Self.weekday(from: dayID) ?? 0
    }
}

// finds the total number of strokes per hole in a given week, as well as the number of times that hole has been played, then it finds the average strokes per hole that week
struct HoleAnalytics: Codable, Equatable {
    var totalStrokesPerHole: [Int] = []
    var playsPerHole: [Int] = []
}

struct CourseEmail: Codable, Equatable {
    var firstSeen: String?
    var secondSeen: String?
    var lastPlayed: String?
    var playCount: Int = 0
}

extension HoleAnalytics {
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

extension DailyDoc {
    var avgRoundTimeseconds: Double {
        Double(totalRoundSeconds) / Double(gamesPlayed)
    }
    var totalCount: Int { newPlayers + returningPlayers }
    
    // MARK: - Init / dayID update
    

    mutating func setDayID(_ newValue: String) {
        dayID = newValue
        weekID = Self.isoWeekID(from: newValue) ?? ""
    }

    // MARK: - Increment (local / in-memory)
    mutating func incrementHour(_ hour: Int, by amount: Int = 1) {
        guard (0..<24).contains(hour), amount != 0 else { return }
        let key = String(hour)
        hourlyCounts[key, default: 0] += amount
    }

    // MARK: - Convenience for UI (map -> 24 array)
    func hourlyArray() -> [Int] {
        var arr = Array(repeating: 0, count: 24)
        for (k, v) in hourlyCounts {
            if let h = Int(k), (0..<24).contains(h) {
                arr[h] = v
            }
        }
        return arr
    }

    // MARK: - ISO week (cached formatter)
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // ""2021-01-01" → "2020-W53" (Jan 1, 2021 is still in ISO week 53 of 2020)
    private static func isoWeekID(from dayID: String) -> String? {
        guard let date = dayFormatter.date(from: dayID) else { return nil }

        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!

        let week = cal.component(.weekOfYear, from: date)
        let year = cal.component(.yearForWeekOfYear, from: date)

        return String(format: "%04d-W%02d", year, week)
    }
    
    // Sunday = 1, Monday = 2, ... Saturday = 7
    private static func weekday(from dayID: String) -> Int? {
        guard let date = dayFormatter.date(from: dayID) else { return nil }

        var cal = Calendar(identifier: .iso8601)

        
        return cal.component(.weekday, from: date)
    }
}
