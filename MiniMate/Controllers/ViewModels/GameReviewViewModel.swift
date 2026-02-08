//
//  GameReviewViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/6/25.
//

import Foundation
import Combine

@MainActor
final class GameReviewViewModel: ObservableObject {
    @Published var course: Course?
    
    let game: Game
    
    init(game: Game) {
        self.game = game
    }

    func loadCourse() {
        guard let id = game.courseID else { return }
        CourseRepository().fetchCourse(id: id) { [weak self] course in
            self?.course = course
        }
    }

    var holeCount: Int {
        course?.pars?.count ?? game.numberOfHoles
    }
    
    var shouldShowCustomAd: Bool? {
        return course?.customAdActive
    }

    var shareText: String {
        var lines = ["MiniMate Scorecard",
                     "Date: \(game.date.formatted(.dateTime))",
                     ""]
        
        for player in game.players {
            var holeLine = ""
            
            for hole in player.holes {
                holeLine += "|\(hole.strokes)"
            }
            
            lines.append("\(player.name): \(player.totalStrokes) strokes (\(player.totalStrokes))")
            lines.append("Holes " + holeLine)
            
        }
        lines.append("")
        lines.append("Download MiniMate: https://apps.apple.com/app/id6745438125")
        return lines.joined(separator: "\n")
    }
    
    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    /// Returns one Hole per hole-number, whose `strokes` is the integer average
    /// across all players for that hole.
    func averageStrokes() -> [Hole] {
        let holeCount   = game.numberOfHoles
        let playerCount = game.players.count
        guard playerCount > 0 else { return [] }
        
        // 1) Sum strokes per hole index (0-based)
        var sums = [Int](repeating: 0, count: holeCount)
        for player in game.players {
            for hole in player.holes {
                let idx = hole.number - 1
                sums[idx] += hole.strokes
            }
        }
        
        // 2) Build averaged Hole objects
        return sums.enumerated().map { (idx, total) in
            let avg = total / playerCount
            return Hole(number: idx + 1, strokes: avg)
        }
    }
}
