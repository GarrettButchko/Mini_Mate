//
//  Course+UI.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/19/25.
//

import SwiftUI

extension Course {
    var scoreCardColor: Color? {
        guard let value = scoreCardColorDT?.lowercased() else { return nil }

        let map: [String: Color] = [
            "red": .red,
            "orange": .orange,
            "yellow": .yellow,
            "green": .green,
            "blue": .blue,
            "indigo": .indigo,
            "purple": .purple,
            "pink": .pink,
            "cyan": .cyan,
            "mint": .mint,
            "teal": .teal,
            "brown": .brown
        ]

        return map[value]?.opacity(0.4)
    }
    
    var courseColors: [Color]? {
        guard let values = courseColorsDT else { return nil }

        let map: [String: Color] = [
            "red": .red,
            "orange": .orange,
            "yellow": .yellow,
            "green": .green,
            "blue": .blue,
            "indigo": .indigo,
            "purple": .purple,
            "pink": .pink,
            "cyan": .cyan,
            "mint": .mint,
            "teal": .teal,
            "brown": .brown
        ]

        let colors = values.compactMap {
            map[$0.lowercased()]
        }

        return colors.isEmpty ? nil : colors
    }
}
