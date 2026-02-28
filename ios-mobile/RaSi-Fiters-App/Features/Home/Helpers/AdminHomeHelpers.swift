import SwiftUI
import Charts

// MARK: - Section Helpers

func sectionHeader(title: String, icon: String, color: Color) -> some View {
    HStack(spacing: 10) {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(color)
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundColor(Color(.label))
    }
}

func settingsRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
    HStack(spacing: 14) {
        ZStack {
            Circle()
                .fill(color.opacity(0.14))
                .frame(width: 42, height: 42)
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
        }
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color(.label))
            Text(subtitle)
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
        }
        Spacer()
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Color(.tertiaryLabel))
    }
    .padding(14)
    .background(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(.systemBackground))
    )
    .overlay(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
    )
}

// MARK: - Shared building blocks

struct SummaryHeader: View {
    let title: String
    let subtitle: String
    let status: String
    let initials: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(Color(.label))
                Text("\(subtitle)")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color(.secondaryLabel))
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appOrange, Color.appOrangeGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                Text(initials)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.black)
            }
        }
    }
}

struct WorkoutTypesHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(Color(.label))
                Text("\(subtitle)")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color(.secondaryLabel))
            }

            Spacer()

            NavigationLink {
                ViewWorkoutTypesListView()
            } label: {
                GlassButton(icon: "dumbbell")
            }
        }
    }
}

struct PeriodSelector: View {
    @Binding var period: AdminHomeView.Period

    var body: some View {
        HStack(spacing: 10) {
            ForEach(AdminHomeView.Period.allCases, id: \.self) { item in
                Button {
                    period = item
                } label: {
                    Text(item.label)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(item == period ? Color(.systemGray5) : Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(item == period ? Color.appOrangeStrong : Color(.systemGray4), lineWidth: 1)
                        )
                        .foregroundColor(Color(.label))
                }
            }
        }
        .padding(.horizontal, 2)
    }
}

struct ProgramProgressCard: View {
    let progress: Int
    let elapsedDays: Int
    let totalDays: Int
    let remainingDays: Int
    let status: String

    var body: some View {
        CardShell(
            background: Color(.systemBackground).opacity(0.9),
            strokeColor: Color(.systemGray4).opacity(0.6)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Program Progress")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color(.label))
                    Spacer()
                    Text(status.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.appOrange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.appOrangeLight))
                }

                Spacer(minLength: 0)

                HStack {
                    Spacer()
                    ZStack {
                        CompletionRing(progress: progress)
                            .frame(width: 140, height: 140)
                        VStack(spacing: 6) {
                            Text("\(progress)%")
                                .font(.title.weight(.bold))
                                .foregroundColor(Color(.label))
                            Text("\(elapsedDays)/\(totalDays) days")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                    }
                    Spacer()
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

struct CompletionRing: View {
    let progress: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.5), lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(max(min(Double(progress), 100), 0)) / 100.0)
                .stroke(
                    LinearGradient(
                        colors: [Color.appOrange, Color.appOrangeGradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

struct MTDParticipationCard: View {
    let active: Int
    let total: Int
    let pct: Double
    let change: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MTD Participation")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(.label))
                Spacer()
            }

            Spacer(minLength: 6)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(Int(pct))%")
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color(.label))

                Text("\(active)/\(total) members active")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Color(.secondaryLabel))
            }

            Spacer(minLength: 10)

            changeBadge

            Text("vs prior MTD")
                .font(.footnote)
                .foregroundColor(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.appBackgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
        .frame(height: 240, alignment: .topLeading)
    }

    private var changeBadge: some View {
        let isUp = change >= 0
        let color: Color = isUp ? .green : .red
        let symbol = isUp ? "arrow.up" : "arrow.down"
        return HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(String(format: "%.1f%%", abs(change)))
        }
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .cornerRadius(10)
    }
}

struct TotalWorkoutsCard: View {
    let total: Int
    let change: Double

    var body: some View {
        CardShell(
            background: Color(.systemBackground).opacity(0.9),
            strokeColor: Color(.systemGray4).opacity(0.6)
        ) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("Total workouts")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(.label))

                Spacer()

                // Value
                Text("\(total)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color(.label))

                Spacer()

                // Footer group (badge + label)
                VStack(alignment: .leading, spacing: 6) {
                    changeBadge
                    Text("vs prior MTD")
                        .font(.footnote)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var changeBadge: some View {
        let isUp = change >= 0
        let color: Color = isUp ? .green : .red
        let symbol = isUp ? "arrow.up" : "arrow.down"
        return HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(String(format: "%.1f%%", abs(change)))
        }
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .cornerRadius(10)
    }
}

struct TotalDurationCard: View {
    let hours: Double
    let change: Double

    var body: some View {
        CardShell(
            background: Color(.systemBackground).opacity(0.9),
            strokeColor: Color(.systemGray4).opacity(0.6)
        ) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("Total duration")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(.label))

                Spacer()

                // Value
                Text("\(formattedHours) hrs")
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color(.label))

                Spacer()

                // Footer group (badge + label)
                VStack(alignment: .leading, spacing: 6) {
                    changeBadge
                    Text("vs prior MTD")
                        .font(.footnote)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var changeBadge: some View {
        let isUp = change >= 0
        let color: Color = isUp ? .green : .red
        let symbol = isUp ? "arrow.up" : "arrow.down"
        return HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(String(format: "%.1f%%", abs(change)))
        }
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .cornerRadius(10)
    }

    private var formattedHours: String {
        let whole = Int(hours)
        if abs(hours - Double(whole)) < 0.05 {
            return "\(whole)"
        }
        return String(format: "%.1f", hours)
    }
}

struct AvgDurationCard: View {
    let minutes: Int
    let change: Double

    var body: some View {
        CardShell(
            background: Color(.systemBackground).opacity(0.9),
            strokeColor: Color(.systemGray4).opacity(0.6)
        ) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Avg duration")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(.label))

                Spacer()

                Text("\(minutes) mins")
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color(.label))

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    changeBadge
                    Text("vs prior MTD")
                        .font(.footnote)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var changeBadge: some View {
        let isUp = change >= 0
        let color: Color = isUp ? .green : .red
        let symbol = isUp ? "arrow.up" : "arrow.down"
        return HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(String(format: "%.1f%%", abs(change)))
        }
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .cornerRadius(10)
    }
}

struct WorkoutTypesTotalCard: View {
    let total: Int
    private let accent: Color = .orange

    var body: some View {
        CardShell(
            background: Color(.systemBackground).opacity(0.9),
            strokeColor: Color(.systemGray4).opacity(0.6)
        ) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Total workout types")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(.label))

                AccentChip(label: "Program to date", accent: accent)
                    .padding(.top, 6)

                Spacer()

                Text("\(total)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(accent)

                Spacer()

                Text("different exercises")
                    .font(.footnote)
                    .foregroundColor(Color(.secondaryLabel))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct WorkoutTypeMostPopularCard: View {
    let name: String?
    let sessions: Int
    private let accent: Color = .purple

    var body: some View {
        CardShell(
            background: Color(.systemBackground).opacity(0.9),
            strokeColor: Color(.systemGray4).opacity(0.6)
        ) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Most popular")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(.label))

                AccentChip(label: "Program to date", accent: accent)
                    .padding(.top, 6)

                Spacer()

                Text(name ?? "N/A")
                    .font(.title3.weight(.bold))
                    .foregroundColor(accent)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer()

                Text(name == nil ? "No data" : "\(sessions) workouts")
                    .font(.footnote)
                    .foregroundColor(Color(.secondaryLabel))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct WorkoutTypeLongestDurationCard: View {
    let name: String?
    let avgMinutes: Int
    private let accent: Color = .red

    var body: some View {
        CardShell(
            background: Color(.systemBackground).opacity(0.9),
            strokeColor: Color(.systemGray4).opacity(0.6)
        ) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Longest duration")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(.label))

                AccentChip(label: "Program to date", accent: accent)
                    .padding(.top, 6)

                Spacer()

                Text(name ?? "N/A")
                    .font(.title3.weight(.bold))
                    .foregroundColor(accent)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer()

                Text(name == nil ? "No data" : "\(avgMinutes) mins avg")
                    .font(.footnote)
                    .foregroundColor(Color(.secondaryLabel))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct WorkoutTypeHighestParticipationCard: View {
    let name: String?
    let participationPct: Double
    private let accent: Color = .green

    var body: some View {
        CardShell(
            background: Color(.systemBackground).opacity(0.9),
            strokeColor: Color(.systemGray4).opacity(0.6)
        ) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Highest participation")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(.label))

                AccentChip(label: "Program to date", accent: accent)
                    .padding(.top, 6)

                Spacer()

                Text(name ?? "N/A")
                    .font(.title3.weight(.bold))
                    .foregroundColor(accent)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer()

                Text(name == nil ? "No data" : String(format: "%.1f%% of members", participationPct))
                    .font(.footnote)
                    .foregroundColor(Color(.secondaryLabel))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct WorkoutTypePopularityCard: View {
    let types: [APIClient.WorkoutTypeDTO]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var metric: WorkoutPopularityMetric = .count
    @State private var showAll = false

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    private var sortedTypes: [APIClient.WorkoutTypeDTO] {
        workoutPopularitySorted(types: types, metric: metric)
    }

    private var displayTypes: [APIClient.WorkoutTypeDTO] {
        if isCompact && !showAll {
            return Array(sortedTypes.prefix(6))
        }
        return sortedTypes
    }

    private var maxValue: Double {
        displayTypes.map { metric.value(for: $0) }.max() ?? 0
    }

    private var rows: [RankedBarList.RowItem] {
        displayTypes.map {
            RankedBarList.RowItem(
                id: $0.id.uuidString,
                name: $0.workout_name,
                value: metric.value(for: $0),
                displayValue: metric.formattedValue(for: $0),
                color: workoutTypePaletteColor(for: $0.workout_name)
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Type Popularity")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color(.label))

            if rows.isEmpty {
                Text("No workouts logged yet.")
                    .font(.footnote)
                    .foregroundColor(Color(.secondaryLabel))
            } else {
                SegmentedMetricPicker(metrics: WorkoutPopularityMetric.allCases, selection: $metric)

                Text(metric.axisLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(.secondaryLabel))

                RankedBarList(rows: rows, maxValue: maxValue)

                if isCompact && sortedTypes.count > 6 {
                    Button(showAll ? "Show top 6" : "Show all") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAll.toggle()
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.appOrange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color(.black).opacity(0.06), radius: 10, x: 0, y: 6)
        .animation(.easeInOut(duration: 0.2), value: metric)
        .animation(.easeInOut(duration: 0.2), value: showAll)
    }
}

struct AccentChip: View {
    let label: String
    let accent: Color

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(accent.opacity(0.12))
            .foregroundColor(accent)
            .clipShape(Capsule())
    }
}

struct ActivityTimelineCardSummary: View {
    let points: [APIClient.ActivityTimelinePoint]
    var showActive: Bool = true

    private var trimmedPoints: [APIClient.ActivityTimelinePoint] {
        Array(points.suffix(10))
    }

    private var yMax: Double {
        if showActive {
            return max(Double(points.map { max($0.workouts, $0.active_members) }.max() ?? 1), 1)
        }
        return max(Double(points.map { $0.workouts }.max() ?? 1), 1)
    }

    var body: some View {
        CardShell(
            background: Color(.systemBackground).opacity(0.95),
            strokeColor: Color(.systemGray4).opacity(0.5),
            height: 280
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Workout Activity Timeline")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(Color(.label))
                        Text(showActive ? "Workouts · Active members" : "Workouts")
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color(.tertiaryLabel))
                }

                if points.isEmpty {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("No data yet")
                            .font(.footnote)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    let barWidth: CGFloat = 10
                    ScrollableBarChart(barCount: trimmedPoints.count, minBarWidth: barWidth) {
                        Chart {
                            ForEach(trimmedPoints) { point in
                                BarMark(
                                    x: .value("Label", point.label),
                                    y: .value("Workouts", point.workouts),
                                    width: .fixed(barWidth)
                                )
                                .foregroundStyle(.orange.opacity(0.9))
                                .cornerRadius(6)

                                if showActive {
                                    LineMark(
                                        x: .value("Label", point.label),
                                        y: .value("Active Members", point.active_members)
                                    )
                                    .lineStyle(.init(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                    .foregroundStyle(.purple)
                                    .interpolationMethod(.catmullRom)
                                    PointMark(
                                        x: .value("Label", point.label),
                                        y: .value("Active Members", point.active_members)
                                    )
                                    .symbolSize(22)
                                    .foregroundStyle(.purple)
                                }
                            }

                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                AxisGridLine()
                                AxisValueLabel()
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: .automatic(desiredCount: 4))
                        }
                        .chartYScale(domain: 0...(yMax * 1.1))
                        .frame(height: 200)
                        .drawingGroup()
                    }
                    .frame(height: 200)
                }
            }
        }
    }
}

struct LifestyleTimelineCardSummary: View {
    let points: [APIClient.HealthTimelinePoint]

    private var trimmedPoints: [APIClient.HealthTimelinePoint] {
        Array(points.suffix(10))
    }

    private var yMax: Double {
        max(Double(trimmedPoints.map { max($0.sleep_hours, $0.food_quality) }.max() ?? 1), 1)
    }

    var body: some View {
        CardShell(
            background: Color(.systemBackground).opacity(0.95),
            strokeColor: Color(.systemGray4).opacity(0.5),
            height: 280
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lifestyle Timeline")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(Color(.label))
                        Text("Sleep · Diet quality")
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color(.tertiaryLabel))
                }

                if points.isEmpty {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("No data yet")
                            .font(.footnote)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    let barWidth: CGFloat = 10
                    ScrollableBarChart(barCount: trimmedPoints.count, minBarWidth: barWidth) {
                        Chart {
                            ForEach(trimmedPoints) { point in
                                BarMark(
                                    x: .value("Label", point.label),
                                    y: .value("Sleep Hours", point.sleep_hours),
                                    width: .fixed(barWidth)
                                )
                                .foregroundStyle(Color.appBlue.opacity(0.9))
                                .cornerRadius(6)

                                LineMark(
                                    x: .value("Label", point.label),
                                    y: .value("Diet Quality", point.food_quality)
                                )
                                .lineStyle(.init(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                .foregroundStyle(Color.appGreen)
                                .interpolationMethod(.catmullRom)
                                PointMark(
                                    x: .value("Label", point.label),
                                    y: .value("Diet Quality", point.food_quality)
                                )
                                .symbolSize(22)
                                .foregroundStyle(Color.appGreen)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                AxisGridLine()
                                AxisValueLabel()
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: .automatic(desiredCount: 4))
                        }
                        .chartYScale(domain: 0...(yMax * 1.1))
                        .frame(height: 200)
                        .drawingGroup()
                    }
                    .frame(height: 200)
                }
            }
        }
    }
}

struct ActivityTimelineDetailView: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var period: AdminHomeView.Period
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedLabel: String?
    @State private var dailyHeight: CGFloat = 0
    private let customPointsProvider: (() -> [APIClient.ActivityTimelinePoint])?
    private let customDailyAverageProvider: (() -> Double)?
    private let customLoadHandler: ((AdminHomeView.Period) async -> Void)?
    private let titleOverride: String?
    private let showActiveSeries: Bool
    private let startDateProvider: (() -> Date)?
    private let endDateProvider: (() -> Date)?
    private let memberId: String?

    init(
        initialPeriod: AdminHomeView.Period,
        pointsProvider: (() -> [APIClient.ActivityTimelinePoint])? = nil,
        dailyAverageProvider: (() -> Double)? = nil,
        loadHandler: ((AdminHomeView.Period) async -> Void)? = nil,
        memberId: String? = nil,
        title: String? = nil,
        showActiveSeries: Bool = true,
        startDateProvider: (() -> Date)? = nil,
        endDateProvider: (() -> Date)? = nil
    ) {
        _period = State(initialValue: initialPeriod)
        self.customPointsProvider = pointsProvider
        self.customDailyAverageProvider = dailyAverageProvider
        self.customLoadHandler = loadHandler
        self.memberId = memberId
        self.titleOverride = title
        self.showActiveSeries = showActiveSeries
        self.startDateProvider = startDateProvider
        self.endDateProvider = endDateProvider
    }

    private var points: [APIClient.ActivityTimelinePoint] {
        if memberId != nil {
            return memberTimelinePoints(from: programContext.memberHistory)
        }
        return customPointsProvider?() ?? programContext.activityTimeline
    }

    private var dailyAverage: Double {
        if memberId != nil {
            return programContext.memberHistoryDailyAverage
        }
        return customDailyAverageProvider?() ?? programContext.activityTimelineDailyAverage
    }

    private var axisStartDate: Date {
        if memberId != nil {
            return programContext.memberHistoryStartDate
        }
        return startDateProvider?() ?? programContext.startDate
    }

    private var axisEndDate: Date {
        if memberId != nil {
            return programContext.memberHistoryEndDate
        }
        return endDateProvider?() ?? programContext.endDate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Workout Activity Timeline")
                    .font(.title3.weight(.semibold))
                Text(showActiveSeries ? "Workouts · Active members" : "Workouts")
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
            }

            Picker("Period", selection: $period) {
                ForEach(AdminHomeView.Period.allCases, id: \.self) { p in
                    Text(p.label).tag(p)
                }
            }
            .pickerStyle(.segmented)

            if selectedLabel == nil {
                HeaderStats(label: titleOverride ?? rangeLabel(for: period, startDate: axisStartDate, endDate: axisEndDate), dailyAverage: dailyAverage)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: HeaderHeightKey.self, value: geo.size.height)
                        }
                    )
                    .onPreferenceChange(HeaderHeightKey.self) { dailyHeight = $0 }
            } else {
                Color.clear.frame(height: dailyHeight)
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 240, alignment: .center)
            } else if points.isEmpty {
                Text("No data for this range yet.")
                    .font(.footnote)
                    .foregroundColor(Color(.secondaryLabel))
                    .frame(maxWidth: .infinity, minHeight: 240, alignment: .center)
            } else {
                let yMax: Double = {
                    if showActiveSeries {
                        return max(Double(points.map { max($0.workouts, $0.active_members) }.max() ?? 1), 1)
                    }
                    return max(Double(points.map { $0.workouts }.max() ?? 1), 1)
                }()
                let barWidth: CGFloat = 12
                ScrollableBarChart(barCount: points.count, minBarWidth: barWidth) {
                    Chart {
                        ForEach(points) { point in
                            BarMark(
                                x: .value("Label", point.label),
                                y: .value("Workouts", point.workouts),
                                width: .fixed(barWidth)
                            )
                            .foregroundStyle(.orange.opacity(0.9))
                            .cornerRadius(8)

                            if showActiveSeries {
                                LineMark(
                                    x: .value("Label", point.label),
                                    y: .value("Active Members", point.active_members)
                                )
                                .lineStyle(.init(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                .foregroundStyle(.purple)
                                .interpolationMethod(.catmullRom)
                                PointMark(
                                    x: .value("Label", point.label),
                                    y: .value("Active Members", point.active_members)
                                )
                                .symbolSize(24)
                                .foregroundStyle(.purple)
                            }
                        }

                    }
                    .chartXAxis {
                        let ticks = axisValues(for: period, startDate: axisStartDate, endDate: axisEndDate)
                        if ticks.isEmpty {
                            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let s = value.as(String.self) {
                                        Text(shortLabel(for: s, period: period))
                                    }
                                }
                            }
                        } else {
                            AxisMarks(values: ticks) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let s = value.as(String.self) {
                                        Text(shortLabel(for: s, period: period))
                                    }
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 5))
                    }
                    .chartYScale(domain: 0...(yMax * 1.1))
                    .frame(height: 280)
                    .drawingGroup()
                    .chartOverlay { proxy in
                        GeometryReader { geo in
                            let plotFrame = proxy.plotAreaFrame

                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let x = value.location.x - geo[plotFrame].origin.x
                                            if let label: String = proxy.value(atX: x) {
                                                selectedLabel = label
                                            }
                                        }
                                        .onEnded { _ in
                                            selectedLabel = nil
                                        }
                                )

                            if let selectedLabel,
                               let tapped = points.first(where: { $0.label == selectedLabel }),
                               let xPos = proxy.position(forX: tapped.label),
                               let yPos = proxy.position(forY: tapped.workouts) {
                                let anchorX = geo[plotFrame].origin.x + xPos
                                let anchorY = geo[plotFrame].origin.y + yPos

                                CalloutView(
                                    label: calloutTitle(for: tapped, period: period),
                                    workouts: tapped.workouts,
                                    active: showActiveSeries ? tapped.active_members : nil,
                                    showActive: showActiveSeries
                                )
                                .position(
                                    x: clamp(anchorX, min: geo.size.width * 0.15, max: geo.size.width * 0.85),
                                    y: max(geo[plotFrame].minY + 12, anchorY - 44)
                                )
                            }
                        }
                    }
                }
                .frame(height: 280)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .task(id: period) {
            await load(period: period)
        }
        .onDisappear {
            Task {
                if let memberId {
                    await programContext.loadMemberHistory(memberId: memberId, period: "week")
                    return
                }
                guard customLoadHandler == nil else { return }
                await load(period: .week)
            }
        }
    }

    private func load(period: AdminHomeView.Period) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        // Clear global error before calling to prevent stale errors from showing
        programContext.errorMessage = nil
        
        if let memberId {
            await programContext.loadMemberHistory(memberId: memberId, period: period.apiValue)
        } else if let customLoadHandler {
            await customLoadHandler(period)
        } else {
            await programContext.loadActivityTimeline(period: period.apiValue)
        }
        
        // Only set error if the timeline call specifically failed
        if programContext.activityTimeline.isEmpty && programContext.errorMessage != nil {
            errorMessage = programContext.errorMessage
        }
        
        isLoading = false
    }
}

struct LifestyleTimelineDetailView: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var period: AdminHomeView.Period
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedLabel: String?
    @State private var dailyHeight: CGFloat = 0
    private let memberId: String?

    init(initialPeriod: AdminHomeView.Period, memberId: String? = nil) {
        _period = State(initialValue: initialPeriod)
        self.memberId = memberId
    }

    private var points: [APIClient.HealthTimelinePoint] {
        programContext.healthTimeline
    }

    private var dailyAverageSleep: Double {
        programContext.healthTimelineDailyAverageSleep
    }

    private var dailyAverageFood: Double {
        programContext.healthTimelineDailyAverageFood
    }

    private var axisStartDate: Date {
        programContext.startDate
    }

    private var axisEndDate: Date {
        programContext.endDate
    }

    private var yMax: Double {
        max(Double(points.map { max($0.sleep_hours, $0.food_quality) }.max() ?? 1), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Lifestyle Timeline")
                    .font(.title3.weight(.semibold))
                Text("Sleep · Diet quality")
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
            }

            Picker("Period", selection: $period) {
                ForEach(AdminHomeView.Period.allCases, id: \.self) { p in
                    Text(p.label).tag(p)
                }
            }
            .pickerStyle(.segmented)

            if selectedLabel == nil {
                HealthHeaderStats(
                    label: rangeLabel(for: period, startDate: axisStartDate, endDate: axisEndDate),
                    sleepAverage: dailyAverageSleep,
                    foodAverage: dailyAverageFood
                )
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: HeaderHeightKey.self, value: geo.size.height)
                    }
                )
                .onPreferenceChange(HeaderHeightKey.self) { dailyHeight = $0 }
            } else {
                Color.clear.frame(height: dailyHeight)
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 240, alignment: .center)
            } else if points.isEmpty {
                Text("No data for this range yet.")
                    .font(.footnote)
                    .foregroundColor(Color(.secondaryLabel))
                    .frame(maxWidth: .infinity, minHeight: 240, alignment: .center)
            } else {
                let barWidth: CGFloat = 12
                ScrollableBarChart(barCount: points.count, minBarWidth: barWidth) {
                    Chart {
                        ForEach(points) { point in
                            BarMark(
                                x: .value("Label", point.label),
                                y: .value("Sleep Hours", point.sleep_hours),
                                width: .fixed(barWidth)
                            )
                            .foregroundStyle(Color.appBlue.opacity(0.9))
                            .cornerRadius(8)

                            LineMark(
                                x: .value("Label", point.label),
                                y: .value("Diet Quality", point.food_quality)
                            )
                            .lineStyle(.init(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .foregroundStyle(Color.appGreen)
                            .interpolationMethod(.catmullRom)
                            PointMark(
                                x: .value("Label", point.label),
                                y: .value("Diet Quality", point.food_quality)
                            )
                            .symbolSize(24)
                            .foregroundStyle(Color.appGreen)
                        }
                    }
                    .chartXAxis {
                        let ticks = axisValues(for: period, startDate: axisStartDate, endDate: axisEndDate)
                        if ticks.isEmpty {
                            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let s = value.as(String.self) {
                                        Text(shortLabel(for: s, period: period))
                                    }
                                }
                            }
                        } else {
                            AxisMarks(values: ticks) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let s = value.as(String.self) {
                                        Text(shortLabel(for: s, period: period))
                                    }
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 5))
                    }
                    .chartYScale(domain: 0...(yMax * 1.1))
                    .frame(height: 280)
                    .drawingGroup()
                    .chartOverlay { proxy in
                        GeometryReader { geo in
                            let plotFrame = proxy.plotAreaFrame

                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let x = value.location.x - geo[plotFrame].origin.x
                                            if let label: String = proxy.value(atX: x) {
                                                selectedLabel = label
                                            }
                                        }
                                        .onEnded { _ in
                                            selectedLabel = nil
                                        }
                                )

                            if let selectedLabel,
                               let tapped = points.first(where: { $0.label == selectedLabel }),
                               let xPos = proxy.position(forX: tapped.label),
                               let yPos = proxy.position(forY: tapped.sleep_hours) {
                                let anchorX = geo[plotFrame].origin.x + xPos
                                let anchorY = geo[plotFrame].origin.y + yPos

                                HealthCalloutView(
                                    label: calloutTitle(dateString: tapped.date, label: tapped.label, period: period),
                                    sleep: tapped.sleep_hours,
                                    food: tapped.food_quality
                                )
                                .position(
                                    x: clamp(anchorX, min: geo.size.width * 0.15, max: geo.size.width * 0.85),
                                    y: max(geo[plotFrame].minY + 12, anchorY - 44)
                                )
                            }
                        }
                    }
                }
                .frame(height: 280)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .task(id: period) {
            await load(period: period)
        }
        .onDisappear {
            Task {
                await programContext.loadHealthTimeline(period: AdminHomeView.Period.week.apiValue, memberId: memberId)
            }
        }
    }

    private func load(period: AdminHomeView.Period) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        await programContext.loadHealthTimeline(period: period.apiValue, memberId: memberId)
        errorMessage = programContext.errorMessage
        isLoading = false
    }
}


struct CardShell<Content: View, Background: View>: View {
    let background: Background
    var strokeColor: Color = Color(.white).opacity(0.35)
    var height: CGFloat = 240
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: height, alignment: .topLeading)
            .background(
                ZStack {
                    background
                        .blur(radius: 12)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.white).opacity(0.25))
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color(.systemBackground).opacity(0.3))
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .shadow(color: Color(.black).opacity(0.06), radius: 10, x: 0, y: 6)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                IconBadge(icon: icon, accent: accent)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(.tertiaryLabel))
                    .font(.subheadline.weight(.bold))
            }

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(Color(.label))

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(Color(.label))

            Text(subtitle)
                .font(.footnote)
                .foregroundColor(Color(.secondaryLabel))
                .lineLimit(2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
        .frame(height: 240, alignment: .topLeading)
    }
}

struct ActivityTile: View {
    let title: String
    let subtitle: String
    let accent: Color
    let values: [CGFloat]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                IconBadge(icon: "waveform.path.ecg.rectangle", accent: accent)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(.tertiaryLabel))
                    .font(.subheadline.weight(.bold))
            }

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(Color(.label))

            Text(subtitle)
                .font(.footnote)
                .foregroundColor(Color(.secondaryLabel))

            SparklineView(values: values)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
    }
}

struct SparklineView: View {
    let values: [CGFloat]

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let clamped = values.isEmpty ? [CGFloat(0)] : values
            let step = width / CGFloat(max(clamped.count - 1, 1))
            let maxValue = max(clamped.max() ?? 1, 1)

            Path { path in
                for index in clamped.indices {
                    let x = CGFloat(index) * step
                    let y = height - (clamped[index] / maxValue) * height
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [Color.appGreen, Color.appBlue],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineJoin: .round)
            )
        }
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

struct IconBadge: View {
    let icon: String
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accent.opacity(0.18))
                .frame(width: 42, height: 42)
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(accent)
        }
    }
}

struct AddWorkoutCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(.black).opacity(0.6))
                    .font(.subheadline.weight(.bold))
            }

            Text("Add workout")
                .font(.title3.weight(.bold))
                .foregroundColor(.black)

            Text("Quick add a session and keep progress up to date.")
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.65))
                .multilineTextAlignment(.leading)
                .padding(.bottom, 4)

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Capsule()
                    .fill(Color.appOrange)
                    .frame(height: 38)
                    .overlay(
                        Label("Log session", systemImage: "bolt.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 14)
                    )
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.appOrange, Color.appOrangeGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .mask(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.appOrange.opacity(0.3), lineWidth: 1)
        )
        .frame(height: 230, alignment: .topLeading)
    }
}

struct AddDailyHealthCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.white.opacity(0.7))
                    .font(.subheadline.weight(.bold))
            }

            Text("Log daily health")
                .font(.title3.weight(.bold))
                .foregroundColor(.white)

            Text("Track sleep hours and diet quality for the day.")
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.75))
                .multilineTextAlignment(.leading)
                .padding(.bottom, 4)

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 38)
                    .overlay(
                        Label("Log day", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                    )
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.appBlue, Color.appBlueLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .mask(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.appBlue.opacity(0.25), lineWidth: 1)
        )
        .frame(height: 230, alignment: .topLeading)
    }
}

// MARK: - Detail view

struct AnalyticsDetailView: View {
    let title: String
    let subtitle: String
    @Binding var period: AdminHomeView.Period
    let timelineValues: [CGFloat]
    var onChangePeriod: ((AdminHomeView.Period) -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title2.weight(.bold))
                            .foregroundColor(Color(.label))
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    Spacer()
                }

                PeriodSelector(period: $period)
                    .onChange(of: period) { _, newValue in
                        onChangePeriod?(newValue)
                    }

                SparklineView(values: timelineValues)
                    .frame(height: 160)
            }
            .padding(20)
        }
        .adaptiveBackground(topLeading: true)
    }
}

struct InviteMemberView: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.dismiss) private var dismiss

    @State private var username: String = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var showSuccessToast = false

    private var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        programContext.programId != nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    usernameField
                    infoNote

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.appRed)
                            .font(.footnote.weight(.semibold))
                    }

                    sendButton
                }
                .padding(20)
            }

            if showSuccessToast {
                successToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 16)
            }
        }
        .adaptiveBackground(topLeading: true)
        .navigationTitle("Invite Member")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Invite member")
                .font(.title2.weight(.bold))
                .foregroundColor(Color(.label))
            Text("Enter the exact username of the person you want to invite to this program.")
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
        }
    }

    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Username")
                .font(.subheadline.weight(.semibold))
            HStack {
                Text("@")
                    .foregroundColor(Color(.tertiaryLabel))
                    .font(.body.weight(.medium))
                TextField("username", text: $username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.asciiCapable)
                if !username.isEmpty {
                    Button {
                        username = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private var infoNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.subheadline)
            Text("The user must have an account to receive the invitation. They will see your invite in their pending invitations.")
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
        }
        .padding(12)
        .background(Color.blue.opacity(0.08))
        .cornerRadius(10)
    }

    private var sendButton: some View {
        Button(action: { Task { await sendInvite() } }) {
            if isSending {
                ProgressView()
                    .tint(.black)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                    Text("Send Invitation")
                        .font(.headline.weight(.semibold))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isFormValid ? Color.appOrange : Color(.systemGray3))
        .foregroundColor(.black)
        .cornerRadius(14)
        .disabled(!isFormValid || isSending)
    }

    private func sendInvite() async {
        guard let token = programContext.authToken,
              let programId = programContext.programId else { return }

        isSending = true
        errorMessage = nil
        showSuccessToast = false

        do {
            let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = try await APIClient.shared.sendProgramInvite(
                token: token,
                programId: programId,
                username: trimmedUsername
            )

            // Always show success (privacy-preserving)
            showSuccessToast = true
            username = ""
            scheduleToastDismiss()

        } catch {
            // Even on error, show success for privacy
            // But if it's a network error, show that
            if error.localizedDescription.contains("network") ||
               error.localizedDescription.contains("connection") {
                errorMessage = "Network error. Please try again."
            } else {
                showSuccessToast = true
                username = ""
                scheduleToastDismiss()
            }
        }

        isSending = false
    }

    private var successToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.appGreen)
            Text("Invite sent")
                .foregroundColor(Color(.label))
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(999)
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
    }

    private func scheduleToastDismiss() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            withAnimation {
                showSuccessToast = false
            }
        }
    }
}

struct AddWorkoutDetailView: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var selectedMember: APIClient.MemberDTO?
    @State private var selectedWorkout: APIClient.WorkoutDTO?
    @State private var selectedDate: Date = Date()
    @State private var durationHoursText: String = ""
    @State private var durationMinutesText: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var showMemberPicker = false
    @State private var showWorkoutPicker = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                formFields
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.appRed)
                        .font(.footnote.weight(.semibold))
                }
                Button(action: { Task { await save() } }) {
                    Group {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Save workout")
                                .font(.headline.weight(.semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appOrange)
                    .foregroundColor(.black)
                    .cornerRadius(14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isSaving || !isFormValid)
            }
            .padding(20)
        }
        .adaptiveBackground(topLeading: true)
        .task {
            await ensureLookups()
        }
        .alert("Workout logged", isPresented: $showSuccessAlert) {
            Button("OK") { dismiss() }
        }
        .sheet(isPresented: $showMemberPicker) {
            SearchablePickerSheet(
                title: "Select Member",
                options: programContext.members.map {
                    SearchablePickerSheet.PickerOption(id: $0.id, label: $0.member_name)
                },
                selectedId: selectedMember?.id,
                onSelect: { option in
                    selectedMember = programContext.members.first { $0.id == option.id }
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showWorkoutPicker) {
            SearchablePickerSheet(
                title: "Select Workout",
                options: workoutOptions.map {
                    SearchablePickerSheet.PickerOption(id: $0, label: $0)
                },
                selectedId: selectedWorkout?.workout_name,
                onSelect: { option in
                    selectWorkout(named: option.label)
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    private var computedDurationMinutes: Int {
        (Int(durationHoursText) ?? 0) * 60 + (Int(durationMinutesText) ?? 0)
    }

    private var isFormValid: Bool {
        selectedMember != nil && selectedWorkout != nil && computedDurationMinutes > 0
    }

    private var canSelectAnyMember: Bool {
        let result = programContext.globalRole == "global_admin" ||
            programContext.loggedInUserProgramRole == "admin" ||
            programContext.loggedInUserProgramRole == "logger"
        return result
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Log workout")
                .font(.title2.weight(.bold))
                .foregroundColor(Color(.label))
            Text("Pick member, workout, date, and duration.")
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
        }
    }

    private var formFields: some View {
        VStack(spacing: 14) {
            memberField

            VStack(alignment: .leading, spacing: 6) {
                Text("Workout type")
                    .font(.subheadline.weight(.semibold))
                Button {
                    showWorkoutPicker = true
                } label: {
                    HStack {
                        Text(selectedWorkout?.workout_name ?? "Select workout")
                            .foregroundColor(selectedWorkout == nil ? Color(.tertiaryLabel) : Color(.label))
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }

            dateField

            VStack(alignment: .leading, spacing: 6) {
                Text("Duration")
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        TextField("0", text: $durationHoursText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 56)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        Text("hr")
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    HStack(spacing: 6) {
                        TextField("0", text: $durationMinutesText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 56)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        Text("min")
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var workoutOptions: [String] {
        if programContext.programId != nil {
            return programContext.programWorkouts
                .filter { !$0.is_hidden }
                .map { $0.workout_name }
        }
        return programContext.workouts.map { $0.workout_name }
    }

    private func selectWorkout(named name: String) {
        if programContext.programId != nil {
            selectedWorkout = APIClient.WorkoutDTO(workout_name: name)
        } else {
            selectedWorkout = programContext.workouts.first { $0.workout_name == name }
        }
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Date")
                .font(.subheadline.weight(.semibold))
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }

    @ViewBuilder
    private var memberField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Member")
                .font(.subheadline.weight(.semibold))
            if canSelectAnyMember {
                Button {
                    showMemberPicker = true
                } label: {
                    HStack {
                        Text(selectedMember?.member_name ?? "Select member")
                            .foregroundColor(selectedMember == nil ? Color(.tertiaryLabel) : Color(.label))
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            } else {
                HStack {
                    Text(selectedMember?.member_name ?? programContext.loggedInUserName ?? "You")
                        .foregroundColor(Color(.secondaryLabel))
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray5))
                .cornerRadius(12)
            }
        }
    }

    private func save() async {
        let duration = computedDurationMinutes
        guard let token = programContext.authToken,
              let member = selectedMember,
              let workout = selectedWorkout,
              duration > 0 else { return }

        isSaving = true
        errorMessage = nil
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: selectedDate)
        let programUUID: String? = {
            guard let pid = programContext.programId else { return nil }
            return UUID(uuidString: pid) != nil ? pid : nil
        }()
        do {
            try await APIClient.shared.addWorkoutLog(
                token: token,
                memberName: member.member_name,
                workoutName: workout.workout_name,
                date: dateString,
                durationMinutes: duration,
                programId: programUUID,
                memberId: member.id
            )
            showSuccessAlert = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func ensureLookups() async {
        let needsProgramRefresh = programContext.membersProgramId != programContext.programId
        if programContext.members.isEmpty || programContext.workouts.isEmpty || needsProgramRefresh {
            await programContext.loadLookupData()
        }
        if programContext.programId != nil {
            await programContext.loadProgramWorkouts()
        }
        // Ensure membership details (including program role) are loaded
        if programContext.membershipDetails.isEmpty || needsProgramRefresh {
            await programContext.loadMembershipDetails()
        }
        // Auto-select logged-in user if they can only log for themselves
        if !canSelectAnyMember, selectedMember == nil {
            if let userId = programContext.loggedInUserId {
                selectedMember = programContext.members.first { $0.id == userId }
            }
        }
    }
}

struct AddDailyHealthDetailView: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMember: APIClient.MemberDTO?
    @State private var selectedDate: Date = Date()
    @State private var sleepHoursText: String = ""
    @State private var sleepMinutesText: String = ""
    @State private var foodQuality: Int?
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false
    @State private var showMemberPicker = false

    private var canSelectAnyMember: Bool {
        programContext.globalRole == "global_admin" ||
        programContext.loggedInUserProgramRole == "admin" ||
        programContext.loggedInUserProgramRole == "logger"
    }

    private var trimmedSleepHoursText: String {
        sleepHoursText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedSleepMinutesText: String {
        sleepMinutesText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasSleepInput: Bool {
        !trimmedSleepHoursText.isEmpty || !trimmedSleepMinutesText.isEmpty
    }

    private var sleepHoursValue: Int? {
        guard !trimmedSleepHoursText.isEmpty else { return nil }
        return Int(trimmedSleepHoursText)
    }

    private var sleepMinutesValue: Int? {
        guard !trimmedSleepMinutesText.isEmpty else { return nil }
        return Int(trimmedSleepMinutesText)
    }

    private var isHoursValid: Bool {
        trimmedSleepHoursText.isEmpty || (sleepHoursValue != nil && (0...24).contains(sleepHoursValue ?? 0))
    }

    private var isMinutesValid: Bool {
        trimmedSleepMinutesText.isEmpty || (sleepMinutesValue != nil && (0...59).contains(sleepMinutesValue ?? 0))
    }

    private var sleepValue: Double? {
        guard hasSleepInput else { return nil }
        guard isHoursValid && isMinutesValid else { return nil }
        let hours = Double(sleepHoursValue ?? 0)
        let minutes = Double(sleepMinutesValue ?? 0)
        let total = hours + minutes / 60.0
        guard total >= 0 && total <= 24 else { return nil }
        return total
    }

    private var isSleepValid: Bool {
        !hasSleepInput || sleepValue != nil
    }

    private var hasAtLeastOneMetric: Bool {
        sleepValue != nil || foodQuality != nil
    }

    private var isFormValid: Bool {
        selectedMember != nil &&
        programContext.programId != nil &&
        isSleepValid &&
        hasAtLeastOneMetric
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                formFields

                Button(action: { Task { await save() } }) {
                    Group {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Save daily log")
                                .font(.headline.weight(.semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.appBlue : Color(.systemGray3))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isSaving || !isFormValid)
            }
            .padding(20)
        }
        .adaptiveBackground(topLeading: true)
        .task {
            await ensureLookups()
        }
        .alert("Daily health logged", isPresented: $showSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Daily health log saved.")
        }
        .alert("Unable to log", isPresented: $showErrorAlert) {
            Button("OK") { showErrorAlert = false }
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
        .sheet(isPresented: $showMemberPicker) {
            SearchablePickerSheet(
                title: "Select Member",
                options: programContext.members.map {
                    SearchablePickerSheet.PickerOption(id: $0.id, label: $0.member_name)
                },
                selectedId: selectedMember?.id,
                onSelect: { option in
                    selectedMember = programContext.members.first { $0.id == option.id }
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Log daily health")
                .font(.title2.weight(.bold))
                .foregroundColor(Color(.label))
            Text("Track sleep hours and diet quality for today or past days.")
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
        }
    }

    private var formFields: some View {
        VStack(spacing: 14) {
            memberField

            VStack(alignment: .leading, spacing: 6) {
                Text("Date")
                    .font(.subheadline.weight(.semibold))
                DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Sleep time")
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 12) {
                    TextField("Hours", text: $sleepHoursText)
                        .keyboardType(.numberPad)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .onChange(of: sleepHoursText) { _, newValue in
                            let sanitized = sanitizeDigits(newValue)
                            if sanitized != newValue {
                                sleepHoursText = sanitized
                            }
                        }
                    TextField("Minutes", text: $sleepMinutesText)
                        .keyboardType(.numberPad)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .onChange(of: sleepMinutesText) { _, newValue in
                            let sanitized = sanitizeDigits(newValue)
                            if sanitized != newValue {
                                sleepMinutesText = sanitized
                            }
                        }
                }
                if !isSleepValid {
                    Text("Sleep time must be between 0:00 and 24:00.")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.appRed)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Diet quality")
                    .font(.subheadline.weight(.semibold))
                Menu {
                    ForEach(1...5, id: \.self) { rating in
                        Button("\(rating)") {
                            foodQuality = rating
                        }
                    }
                    Button("Clear") { foodQuality = nil }
                } label: {
                    HStack {
                        Text(foodQuality.map { "\($0)" } ?? "Select rating (1-5)")
                            .foregroundColor(foodQuality == nil ? Color(.tertiaryLabel) : Color(.label))
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
    }

    @ViewBuilder
    private var memberField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Member")
                .font(.subheadline.weight(.semibold))
            if canSelectAnyMember {
                Button {
                    showMemberPicker = true
                } label: {
                    HStack {
                        Text(selectedMember?.member_name ?? "Select member")
                            .foregroundColor(selectedMember == nil ? Color(.tertiaryLabel) : Color(.label))
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            } else {
                HStack {
                    Text(selectedMember?.member_name ?? programContext.loggedInUserName ?? "You")
                        .foregroundColor(Color(.secondaryLabel))
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray5))
                .cornerRadius(12)
            }
        }
    }

    private func save() async {
        guard let token = programContext.authToken,
              let member = selectedMember,
              let programId = programContext.programId else { return }

        isSaving = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: selectedDate)

        do {
            try await APIClient.shared.addDailyHealthLog(
                token: token,
                programId: programId,
                memberId: member.id,
                logDate: dateString,
                sleepHours: sleepValue,
                foodQuality: foodQuality
            )
            showSuccessAlert = true
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isSaving = false
    }

    private func ensureLookups() async {
        let needsProgramRefresh = programContext.membersProgramId != programContext.programId
        if programContext.members.isEmpty || needsProgramRefresh {
            await programContext.loadLookupData()
        }
        // Ensure membership details (including program role) are loaded
        if programContext.membershipDetails.isEmpty || needsProgramRefresh {
            await programContext.loadMembershipDetails()
        }
        if !canSelectAnyMember, selectedMember == nil {
            if let userId = programContext.loggedInUserId {
                selectedMember = programContext.members.first { $0.id == userId }
            } else if let fallback = programContext.members.first {
                selectedMember = fallback
            }
        }
    }

    private func sanitizeDigits(_ value: String) -> String {
        let filtered = value.filter { $0.isNumber }
        return String(filtered.prefix(2))
    }
}

// MARK: - Card ordering helpers

enum SummaryCardType: String, CaseIterable, Hashable {
    case addWorkout
    case addDailyHealth
    case programProgress
    case mtdParticipation
    case totalWorkouts
    case totalDuration
    case avgDuration
    case activityTimeline
    case distributionByDay
    case workoutTypes

    var span: Int {
        switch self {
        case .addWorkout, .addDailyHealth, .programProgress, .activityTimeline, .distributionByDay, .workoutTypes:
            return 2
        default:
            return 1
        }
    }

    var requiresFullWidth: Bool {
        switch self {
        case .programProgress, .activityTimeline, .addWorkout, .addDailyHealth, .distributionByDay, .workoutTypes:
            return true
        default:
            return false
        }
    }

    static var defaultOrder: [SummaryCardType] = [
        .programProgress,
        .addWorkout,
        .addDailyHealth,
        .mtdParticipation,
        .totalWorkouts,
        .totalDuration,
        .avgDuration,
        .activityTimeline,
        .distributionByDay,
        .workoutTypes
    ]
}

struct CardDropDelegate: DropDelegate {
    let item: SummaryCardType
    @Binding var items: [SummaryCardType]
    @Binding var dragging: SummaryCardType?
    let onReorder: () -> Void

    func dropEntered(info: DropInfo) {
        guard let dragging,
              dragging != item,
              let from = items.firstIndex(of: dragging),
              let to = items.firstIndex(of: item) else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        onReorder()
        return true
    }
}

struct PlaceholderCard: View {
    let title: String

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color(.secondaryLabel))
            ProgressView()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
    }
}

// MARK: - Shared scaffolds

struct AdminTabScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Color.clear.frame(height: 120)
                    content()
                        .padding(.bottom, 16)
                }
                .padding(.horizontal, 20)
            }

            GlassHeader(title: title, subtitle: subtitle)
                .padding(.horizontal, 16)
                .padding(.top, 12)
        }
    }
}

struct GlassHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            LogoBadge()
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color(.label))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 0.6)
        )
        .adaptiveShadow(radius: 14, y: 8)
    }
}

struct GlassCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.14))
                    .frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color(.label))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 0.6)
        )
        .adaptiveShadow(radius: 12, y: 6)
    }
}

struct LogoBadge: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.appOrangeLight)
                .frame(width: 56, height: 56)

            Image(systemName: "chart.bar.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
                .foregroundStyle(Color.appOrange)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("RaSi Fit'ers brand")
    }
}
