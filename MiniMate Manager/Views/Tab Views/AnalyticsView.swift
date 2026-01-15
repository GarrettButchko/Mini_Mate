//
//  AnalyticsView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/18/25.
//

import SwiftUI

enum AnalyticsSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
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

let analyticsObjects: [String: AnalyticsObject] = [
    AnalyticsSection.overview.rawValue: AnalyticsObject(
        type: .overview,
        icon: "square.grid.2x2",
        color: .blue
    ),

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

/*
 Retention
 
 Repeat Rate

 % of active players with playCount >= 2 (for a period, you’ll filter by lastPlayed in range)

 Avg Time to Return

 average of daysBetween(firstSeen, secondSeen) for players where secondSeen != nil

 30-Day Retention

 % of players whose firstSeen is in range AND secondSeen <= firstSeen + 30
 */

struct AnalyticsView: View {

    @EnvironmentObject var viewModel: CourseViewModel

    @State private var selectedSection: AnalyticsSection = .overview

    var body: some View {
        VStack {
            HStack{
                Text("Analytics")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding([.horizontal, .top])

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(AnalyticsSection.allCases) { section in
                            let obj = analyticsObjects[section.rawValue]!
                                Button {
                                    withAnimation(.snappy) {
                                        selectedSection = section
                                        proxy.scrollTo(section, anchor: .leading) // ✅ shove to front
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: obj.icon)
                                        
                                        Text(section.rawValue)
                                            .fontWeight(.bold)
                                            .transition(.move(edge: .leading).combined(with: .opacity))
                                    }
                                }
                                .id(section)
                                .foregroundStyle(obj.color)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 11)
                                .background(
                                    selectedSection == section ? obj.color.opacity(0.3) : .clear
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(obj.color.opacity(0.3), lineWidth: 4)
                                        .opacity(selectedSection != section ? 0.5 : 0)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                            
                        }
                    }
                }
                .contentMargins(.horizontal, 16, for: .scrollContent)
                .onAppear {
                    DispatchQueue.main.async {
                        selectedSection = .overview
                        proxy.scrollTo(AnalyticsSection.overview, anchor: .leading)
                    }
                }
            }

            ScrollView(.vertical) {
                // content for focusedSection goes here
            }
            .padding(.horizontal)
        }
    }
}

struct AnalyticsOverView: View {
    
    @EnvironmentObject var viewModel: CourseViewModel
    
    var body: some View {
        
        
        
    }
}
