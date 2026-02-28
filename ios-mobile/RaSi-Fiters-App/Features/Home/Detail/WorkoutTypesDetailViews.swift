import SwiftUI
import Charts

// MARK: - Workout Types summary card
struct WorkoutTypesSummaryCard: View {
    let types: [APIClient.WorkoutTypeDTO]

    private var topSixWithOthers: [APIClient.WorkoutTypeDTO] {
        let sorted = types.sorted { $0.sessions > $1.sessions }
        let topFive = Array(sorted.prefix(5))
        let others = Array(sorted.dropFirst(5))
        var list = topFive
        if !others.isEmpty {
            let totalSessions = others.reduce(0) { $0 + $1.sessions }
            let totalDuration = others.reduce(0) { $0 + $1.total_duration }
            let avg = totalSessions > 0 ? Int(round(Double(totalDuration) / Double(totalSessions))) : 0
            list.append(APIClient.WorkoutTypeDTO(workout_name: "Others", sessions: totalSessions, total_duration: totalDuration, avg_duration_minutes: avg))
        } else if sorted.count > 5 {
            // If no others but we still want up to 6 rows, append the 6th item if exists
            let sixth = sorted.dropFirst(5).first
            if let s = sixth {
                list.append(s)
            }
        }
        return Array(list.prefix(6))
    }

    var body: some View {
        CardShell(
            background: Color(.systemBackground).opacity(0.95),
            strokeColor: Color(.systemGray4).opacity(0.6),
            height: 200
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Top Workout Types")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color(.label))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                if topSixWithOthers.isEmpty {
                    Text("No workouts logged yet.")
                        .font(.footnote)
                        .foregroundColor(Color(.secondaryLabel))
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(topSixWithOthers) { t in
                            HStack {
                                Circle()
                                    .fill(typeColor(for: t.workout_name))
                                    .frame(width: 8, height: 8)
                                Text(t.workout_name)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                Spacer()
                                Text("\(t.sessions)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(Color(.label))
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Workout Types detail
struct WorkoutTypesDetailView: View {
    let types: [APIClient.WorkoutTypeDTO]
    @State private var selected: APIClient.WorkoutTypeDTO?

    private var sortedTypes: [APIClient.WorkoutTypeDTO] {
        types.sorted { $0.sessions > $1.sessions }
    }

    private var totalSessions: Double {
        max(Double(sortedTypes.reduce(0) { $0 + $1.sessions }), 1)
    }

    private var chartTypes: [APIClient.WorkoutTypeDTO] {
        var arr: [APIClient.WorkoutTypeDTO] = []
        let topFive = Array(sortedTypes.prefix(5))
        let others = Array(sortedTypes.dropFirst(5))
        arr.append(contentsOf: topFive)
        if !others.isEmpty {
            let totalSessions = others.reduce(0) { $0 + $1.sessions }
            let totalDuration = others.reduce(0) { $0 + $1.total_duration }
            let avg = totalSessions > 0 ? Int(round(Double(totalDuration) / Double(totalSessions))) : 0
            arr.append(APIClient.WorkoutTypeDTO(workout_name: "Others", sessions: totalSessions, total_duration: totalDuration, avg_duration_minutes: avg))
        }
        return arr
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Types")
                .font(.title3.weight(.semibold))
            if sortedTypes.isEmpty {
                VStack(alignment: .center, spacing: 8) {
                    Text("No workouts logged yet.")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Text("Workouts (Program to date)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(.secondaryLabel))

                Chart {
                    ForEach(chartTypes) { t in
                        let percent = Double(t.sessions) / totalSessions
                        BarMark(
                            x: .value("Percent", percent),
                            y: .value("Type", t.workout_name)
                        )
                        .foregroundStyle(barColor(for: t))
                        .cornerRadius(8)
                        .annotation(position: .trailing, alignment: .leading) {
                            Text("\(Int(round(percent * 100)))%")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(Color(.label))
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks() { _ in
                        AxisValueLabel()
                    }
                }
                .chartXAxis(.hidden)
                .chartXScale(domain: 0...1)
                .frame(height: min(200, CGFloat(chartTypes.count) * 32))

                Divider()
                    .padding(.vertical, 4)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        Text("Breakdown")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color(.secondaryLabel))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        let total = max(sortedTypes.reduce(0) { $0 + $1.sessions }, 1)
                        ForEach(sortedTypes) { t in
                            WorkoutTypeRow(type: t, total: total, isOthers: false)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

struct WorkoutTypeRow: View {
    let type: APIClient.WorkoutTypeDTO
    let total: Int
    var isOthers: Bool = false

    private var share: Double {
        total > 0 ? Double(type.sessions) / Double(total) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Circle()
                    .fill(isOthers ? Color(.systemGray3) : typeColor(for: type.workout_name))
                    .frame(width: 10, height: 10)
                Text(type.workout_name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(type.sessions)")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color(.label))
                    Text("\(type.avg_duration_minutes) min avg")
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            ProgressView(value: share)
                .progressViewStyle(.linear)
                .tint(isOthers ? Color(.systemGray3) : typeColor(for: type.workout_name))
        }
    }
}

struct ScrollableBarChart<Content: View>: View {
    let barCount: Int
    let minBarWidth: CGFloat
    let barGap: CGFloat
    @ViewBuilder let chart: () -> Content

    init(
        barCount: Int,
        minBarWidth: CGFloat = 12,
        barGap: CGFloat = 6,
        @ViewBuilder chart: @escaping () -> Content
    ) {
        self.barCount = barCount
        self.minBarWidth = minBarWidth
        self.barGap = barGap
        self.chart = chart
    }

    var body: some View {
        GeometryReader { geo in
            let count = max(barCount, 1)
            let contentWidth = max(geo.size.width, CGFloat(count) * (minBarWidth + barGap))
            ScrollView(.horizontal, showsIndicators: false) {
                chart()
                    .frame(width: contentWidth)
            }
        }
    }
}
