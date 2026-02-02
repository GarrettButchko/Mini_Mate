//
//  AnalyticsView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/18/25.
//

import SwiftUI
import Combine
import Foundation

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

    @EnvironmentObject var courseVM: CourseViewModel
    @StateObject var VM = AnalyticsViewModel()

    @State private var selectedSection: AnalyticsSection = .growth
    
    @State var range: AnalyticsRange = .last30

    var body: some View {
        VStack {
            HStack{
                Text("Analytics")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding([.horizontal, .top])
            ZStack (alignment: .top){
                
                // Content
                ScrollView(.vertical) {
                    VStack(spacing: 16){
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 115)

                        HStack{
                            Spacer()
                            Text("ADD STUFF HERE")
                            Spacer()
                        }
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(.ultraThinMaterial)
                        }
                    }
                }
                .padding(.horizontal)
                
                
                // Top Bar
                VStack (spacing: 16){
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(AnalyticsSection.allCases) { section in
                                    let obj = VM.analyticsObjects[section.rawValue]!
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
                    }
                    .contentMargins([.horizontal, .top],16, for: .scrollContent)
                    
                    AnalyticsRangeBar(range: $range)
                        .padding([.horizontal, .bottom], 16)
                    
                }
                .background(content: {
                    RoundedRectangle(cornerRadius: 25)
                        .ifAvailableGlassEffect()
                })
                .padding(.horizontal)
            }
        }
        .environmentObject(VM)
    }
}

struct AnalyticsRangeBar: View {
    @Binding var range: AnalyticsRange
    @EnvironmentObject var VM: AnalyticsViewModel
    @State private var showCustomSheet = false

    var body: some View {
        HStack(spacing: 10) {

            // Dropdown
            Menu {
                Button("Last 7 days") { range = .last7 }
                Button("Last 30 days") { range = .last30 }
                Button("Last 90 days") { range = .last90 }
            } label: {
                HStack {
                    Text(range.isCustom ? range.title + " - \(VM.daysBetween(range)) days" : range.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.ultraThinMaterial)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 25)
                        .strokeBorder(.blue.opacity(0.3), lineWidth: 2)
                }
            }

            // Custom
            Button {
                showCustomSheet = true
            } label: {
                Text("Custom Range")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.blue.opacity(0.9))
                    )
                    .foregroundStyle(.white)
            }
        }
        .sheet(isPresented: $showCustomSheet) {
            CustomRangeSheet(range: $range)
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
        }
    }
    
    
    struct CustomRangeSheet: View {
        @EnvironmentObject var VM: AnalyticsViewModel
        @Environment(\.dismiss) private var dismiss
        @Binding var range: AnalyticsRange

        @State private var startDate: Date
        @State private var endDate: Date

        init(range: Binding<AnalyticsRange>) {
            self._range = range

            // sensible defaults
            let today = Date()
            let defaultStart = Calendar.current.date(byAdding: .day, value: -30, to: today) ?? today

            if case let .custom(s, e) = range.wrappedValue {
                _startDate = State(initialValue: s)
                _endDate = State(initialValue: e)
            } else {
                _startDate = State(initialValue: defaultStart)
                _endDate = State(initialValue: today)
            }
        }

        var body: some View {
            VStack(spacing: 14) {

                HStack {
                    Text("Custom Range - \(VM.daysBetween(startDate, endDate)) days")
                        .font(.headline)
                    Spacer()
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    Text("From")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack{
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                        Spacer()
                        Image(systemName: "calendar")
                            .foregroundStyle(.subThree)
                    }
                    
                    Divider()
                    
                    Text("To")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack{
                        DatePicker("", selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                            .labelsHidden()
                        Spacer()
                        Image(systemName: "calendar")
                            .foregroundStyle(.subThree)
                    }
                }
                Spacer()
                
                HStack(spacing: 10) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay {
                                RoundedRectangle(cornerRadius: 25)
                                    .strokeBorder(.blue.opacity(0.3), lineWidth: 2)
                            }
                    }

                    Button {
                        // normalize just in case
                        let s = min(startDate, endDate)
                        let e = max(startDate, endDate)
                        range = .custom(start: s, end: e)
                        dismiss()
                    } label: {
                        Text("Apply")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.blue.opacity(0.9))
                            )
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding([.top, .horizontal], 30)
            .presentationDetents([.fraction(0.2)])
            .presentationDragIndicator(.visible)
        }
    }
}

