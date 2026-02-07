//
//  BarChartView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/13/25.
//
import SwiftUI
import Charts

struct BarChartView: View {
    @Environment(\.colorScheme) private var colorScheme
    let data: [Hole]
    let title: String

    var body: some View {
        Chart {
            ForEach(data, id: \.self) { hole in
                if hole.strokes > 0 {
                    BarMark(
                        x: .value("Hole", hole.number),
                        y: .value("Strokes", hole.strokes)
                    )
                    .annotation(position: .top) {
                        Text("\(hole.strokes)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .foregroundStyle(strokeColor(hole.strokes))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    PointMark(
                        x: .value("Hole", hole.number),
                        y: .value("Strokes", 0)
                    )
                    .foregroundStyle(.gray.opacity(0.3))
                }
            }
        }
        .chartXAxis {
            AxisMarks(preset: .aligned, values: .stride(by: 3)) { value in
                AxisValueLabel {
                    if let hole = value.as(Int.self) {
                        Text("H\(hole)") // Shows "H1", "H2", etc.
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .stride(by: 5))
        }
        .chartXAxisLabel(position: .bottom, alignment: .center) {
          Text(title)
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .chartXScale(domain: data.isEmpty ? 0...1 : 1...data.count)
        .chartYScale(domain: 0...12)
        .padding([.horizontal, .top])
        .padding(.trailing, 15)
        .padding([.bottom, .top], 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(colorScheme == .light
                                                            ? AnyShapeStyle(Color.white)
                                                            : AnyShapeStyle(.ultraThinMaterial)))
    }
}

private func strokeColor(_ value: Int) -> Color {
    let cappedMax = max(1, 10)
    let t = Double(value) / Double(cappedMax) // 0..1
    if t <= 0.5 {
        return Color(red: t * 2, green: 1, blue: 0) // green -> yellow
    } else {
        return Color(red: 1, green: 1 - ((t - 0.5) * 2), blue: 0) // yellow -> red
    }
}

