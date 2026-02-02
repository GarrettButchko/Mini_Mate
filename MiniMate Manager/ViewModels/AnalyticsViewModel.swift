//
//  AnalyticsViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/1/26.
//

import Foundation
import Combine
import SwiftUI

enum AnalyticsRange: Equatable {
    case last7
    case last30
    case last90
    case custom(start: Date, end: Date)

    var title: String {
        switch self {
        case .last7: return "Last 7 days"
        case .last30: return "Last 30 days"
        case .last90: return "Last 90 days"
        case .custom: return "Custom"
        }
    }

    var isCustom: Bool {
        if case .custom = self { return true }
        return false
    }
    
    /// Returns the concrete date range for this selection.
    /// End date is "today" for last7/30/90.
    func dates(now: Date = Date(), calendar: Calendar = .current) -> (start: Date, end: Date) {
        let end = calendar.startOfDay(for: now)

        switch self {
        case .last7:
            let start = calendar.date(byAdding: .day, value: -6, to: end)! // inclusive 7 days
            return (start, end)

        case .last30:
            let start = calendar.date(byAdding: .day, value: -29, to: end)! // inclusive 30 days
            return (start, end)

        case .last90:
            let start = calendar.date(byAdding: .day, value: -89, to: end)! // inclusive 90 days
            return (start, end)

        case .custom(let start, let end):
            return (calendar.startOfDay(for: start), calendar.startOfDay(for: end))
        }
    }

    var startDate: Date { dates().start }
    var endDate: Date { dates().end }
}

enum AnalyticsSection: String, CaseIterable, Identifiable {
    case growth = "Growth"
    case retention = "Retention"
    case operations = "Operations"
    case experience = "Experience"

    var id: String { rawValue }
}

struct AnalyticsObject{
    var type: AnalyticsSection
    var icon: String
    var color: Color
}

@MainActor
final class AnalyticsViewModel: ObservableObject {
    let analyticsObjects: [String: AnalyticsObject] = [
        AnalyticsSection.growth.rawValue: AnalyticsObject(
            type: .growth,
            icon: "chart.line.uptrend.xyaxis",
            color: .green
        ),

        AnalyticsSection.retention.rawValue: AnalyticsObject(
            type: .retention,
            icon: "arrow.triangle.2.circlepath",
            color: .orange
        ),

        AnalyticsSection.operations.rawValue: AnalyticsObject(
            type: .operations,
            icon: "clock",
            color: .purple
        ),

        AnalyticsSection.experience.rawValue: AnalyticsObject(
            type: .experience,
            icon: "star",
            color: .pink
        )
    ]
    
    func daysBetween(_ range: AnalyticsRange) -> Int {
        let cal = Calendar.current
        let s = cal.startOfDay(for: range.startDate)
        let e = cal.startOfDay(for: range.endDate)
        return cal.dateComponents([.day], from: s, to: e).day ?? 0
    }
    
    func daysBetween(_ start: Date, _ end: Date) -> Int {
        let cal = Calendar.current
        let s = cal.startOfDay(for: start)
        let e = cal.startOfDay(for: end)
        return cal.dateComponents([.day], from: s, to: e).day ?? 0
    }
}


