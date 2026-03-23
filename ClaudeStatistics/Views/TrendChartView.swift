import SwiftUI
import Charts

struct TrendChartView: View {
    let dataPoints: [TrendDataPoint]
    let granularity: TrendGranularity

    private var maxTokens: Int {
        dataPoints.map(\.tokens).max() ?? 0
    }
    private var maxCost: Double {
        dataPoints.map(\.cost).max() ?? 0
    }
    /// Scale factor to normalize cost into the token value range
    private var scaleFactor: Double {
        guard maxCost > 0, maxTokens > 0 else { return 1.0 }
        return Double(maxTokens) / maxCost
    }

    var body: some View {
        if dataPoints.isEmpty {
            emptyState
        } else {
            chartContent
                .frame(height: 200)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20))
                    .foregroundStyle(.tertiary)
                Text("No trend data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(height: 100)
    }

    @ViewBuilder
    private var chartContent: some View {
        let useSingleAxis = maxTokens == 0 || maxCost == 0

        Chart {
            ForEach(dataPoints) { point in
                if dataPoints.count == 1 {
                    // Single point: use PointMark
                    if maxTokens > 0 {
                        PointMark(
                            x: .value("Time", point.time),
                            y: .value("Tokens", point.tokens)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(30)
                    }
                    if maxCost > 0 {
                        PointMark(
                            x: .value("Time", point.time),
                            y: .value("Tokens", useSingleAxis ? Int(point.cost * 1000) : Int(point.cost * scaleFactor))
                        )
                        .foregroundStyle(.orange)
                        .symbolSize(30)
                    }
                } else {
                    // Multiple points: use LineMark
                    if maxTokens > 0 {
                        LineMark(
                            x: .value("Time", point.time),
                            y: .value("Tokens", point.tokens),
                            series: .value("Series", "Tokens")
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                    if maxCost > 0 {
                        LineMark(
                            x: .value("Time", point.time),
                            y: .value("Tokens", useSingleAxis ? Int(point.cost * 1000) : Int(point.cost * scaleFactor)),
                            series: .value("Series", "Cost")
                        )
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formatAxisDate(date))
                            .font(.system(size: 9))
                    }
                }
            }
        }
        .chartYAxis {
            // Left axis: tokens
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intVal = value.as(Int.self) {
                        Text(abbreviateNumber(intVal))
                            .font(.system(size: 9))
                            .foregroundStyle(.blue)
                    }
                }
            }
            // Right axis: cost (reverse-mapped from normalized values)
            if !useSingleAxis {
                AxisMarks(position: .trailing) { value in
                    AxisValueLabel {
                        if let intVal = value.as(Int.self) {
                            let realCost = Double(intVal) / scaleFactor
                            Text(abbreviateCost(realCost))
                                .font(.system(size: 9))
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
        .chartLegend(position: .top) {
            HStack(spacing: 12) {
                if maxTokens > 0 {
                    legendItem(color: .blue, label: "Tokens")
                }
                if maxCost > 0 {
                    legendItem(color: .orange, label: "Cost")
                }
            }
            .font(.system(size: 10))
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).foregroundStyle(.secondary)
        }
    }

    private func formatAxisDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = granularity.dateFormatString
        return fmt.string(from: date)
    }

    private func abbreviateNumber(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.0fK", Double(n) / 1_000) }
        return "\(n)"
    }

    private func abbreviateCost(_ cost: Double) -> String {
        if cost >= 1.0 { return String(format: "$%.1f", cost) }
        if cost >= 0.01 { return String(format: "$%.2f", cost) }
        return String(format: "$%.3f", cost)
    }
}
