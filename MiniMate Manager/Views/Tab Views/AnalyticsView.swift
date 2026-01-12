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
    var
}




struct AnalyticsView: View {

    @EnvironmentObject var viewModel: CourseViewModel

    @FocusState private var focusedSection: AnalyticsSection?
    
    let analyticsSections: [AnalyticsObject] = []

    var body: some View {
        VStack {
            HStack{
                Text("Analytics")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(AnalyticsSection.allCases) { section in
                        Button(section.rawValue) {
                            focusedSection = section
                        }
                        .focused($focusedSection, equals: section)
                        .padding()
                        .background(
                            focusedSection == section ? .blue.opacity(0.5) : .clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            ScrollView(.vertical) {
                // content for focusedSection goes here
            }
        }
        .padding()
        .onAppear {
            focusedSection = .overview   // ✅ default focus
        }
    }
}
