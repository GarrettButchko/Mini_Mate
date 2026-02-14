//
//  BarChartView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/13/25.
//
import SwiftUI
import Charts

enum BackgroundType {
    case clear
    case adaptive
    case ultraThin
}

struct BarChartView: View {
    @Environment(\.colorScheme) private var colorScheme
    let data: [Hole]
    let title: String
    let paddingReview: Bool
    let cornerRadius: CGFloat
    let backgroundType: BackgroundType
    
    init(data: [Hole], title: String, paddingReview: Bool = false, cornerRadius: CGFloat = 12, backgroundType: BackgroundType = .adaptive) {
        self.data = data
        self.title = title
        self.paddingReview = paddingReview
        self.cornerRadius = cornerRadius
        self.backgroundType = backgroundType
    }

    var body: some View {
        let nonZeroStrokes = data.map(\.strokes).filter { $0 > 0 }
        let minStroke = nonZeroStrokes.min()
        let maxStroke = nonZeroStrokes.max() ?? 0
        let yMax = maxStroke + 2
        let yAxisLines = yMax / 3
        let xDomain: ClosedRange<Int> = data.isEmpty ? 0...1 : 1...data.count
        let _: AnyShapeStyle = {
            switch backgroundType {
            case .clear:
                return AnyShapeStyle(.clear)
            case .ultraThin:
                return AnyShapeStyle(.ultraThinMaterial)
            case .adaptive:
                return colorScheme == .light
                    ? AnyShapeStyle(Color.white)
                    : AnyShapeStyle(.ultraThinMaterial)
            }
        }()
        return Chart {
            ForEach(data, id: \.self) { hole in
                if hole.strokes > 0 {
                    BarMark(
                        x: .value("Hole", hole.number),
                        y: .value("Strokes", hole.strokes)
                    )
                    .annotation(position: .top) {
                        if hole.strokes == minStroke || hole.strokes == maxStroke {
                            Text("\(hole.strokes)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .opacity(0.7)
                        }
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
        .chartPlotStyle { plot in
            plot.padding(.leading, 8)
        }
        .chartXAxis {
            AxisMarks(preset: .aligned, values: .stride(by: 3)) { value in
                AxisValueLabel {
                    if let hole = value.as(Int.self) {
                        Text("H\(hole)") // Shows "H1", "H2", etc.
                    }
                }
                .foregroundStyle(.mainOpp)
            }
        }
        .chartYAxis {
            let yStep = max(1, yAxisLines)
            let yTicks = Array(stride(from: 0, through: yMax, by: yStep))
            AxisMarks(position: .leading, values: yTicks) { _ in
                AxisGridLine().foregroundStyle(.mainOpp.opacity(0.2))
                AxisValueLabel().foregroundStyle(.mainOpp)
            }
        }

        .chartXAxisLabel(position: .bottom, alignment: .center) {
          Text(title)
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: 0...yMax)
        .padding(.top, 26)
        .padding(.bottom, paddingReview ? 5 : 10)
        .padding(.horizontal, 16)
        .padding(.trailing, paddingReview ? 12 : 15)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.subTwo)
        )
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
