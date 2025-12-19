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
}
