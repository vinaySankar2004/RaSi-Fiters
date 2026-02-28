import SwiftUI
import Charts

// MARK: - Distribution helpers
struct DistributionPoint: Identifiable {
    let id = UUID()
    let label: String
    let short: String
    let workouts: Int
}

func distributionPoints(fromCounts map: [String: Int]) -> [DistributionPoint] {
    let order = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    let short = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    return order.enumerated().map { idx, day in
        let value = map[day] ?? 0
        return DistributionPoint(label: day, short: short[idx], workouts: value)
    }
}

// MARK: - Axis / Callout helpers
func axisValues(for period: AdminHomeView.Period, startDate: Date, endDate: Date) -> [String] {
    switch period {
    case .week:
        return []
    case .month:
        return ["1", "8", "15", "22", "29"]
    case .year:
        return ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    case .program:
        return programMonthLabels(start: startDate, end: endDate)
    }
}

func shortLabel(for value: String, period: AdminHomeView.Period) -> String {
    switch period {
    case .year, .program:
        return String(value.prefix(1))
    default:
        return value
    }
}

func programMonthLabels(start: Date, end: Date) -> [String] {
    var labels: [String] = []
    let cal = Calendar(identifier: .gregorian)
    guard start <= end else { return ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"] }
    var cursor = cal.date(from: cal.dateComponents([.year, .month], from: start)) ?? start
    let endMonth = cal.date(from: cal.dateComponents([.year, .month], from: end)) ?? end
    let df = DateFormatter()
    df.dateFormat = "MMM"
    while cursor <= endMonth {
        labels.append(df.string(from: cursor))
        cursor = cal.date(byAdding: .month, value: 1, to: cursor) ?? cursor
        if labels.count > 24 { break }
    }
    if labels.isEmpty {
        labels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    }
    return labels
}

func calloutTitle(for point: APIClient.ActivityTimelinePoint, period: AdminHomeView.Period) -> String {
    calloutTitle(dateString: point.date, label: point.label, period: period)
}

func calloutTitle(dateString: String, label: String, period: AdminHomeView.Period) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(abbreviation: "UTC")

    // Try full ISO first
    if let date = ISO8601DateFormatter().date(from: dateString.contains("T") ? dateString : dateString + "T00:00:00Z") {
        return formatCalloutDate(date: date, period: period, formatter: formatter)
    }

    // Try yyyy-MM (month buckets)
    if dateString.count == 7, dateString.contains("-") {
        let components = dateString.split(separator: "-")
        if let year = Int(components[0]), let month = Int(components[1]) {
            var dc = DateComponents()
            dc.year = year
            dc.month = month
            dc.day = 1
            let cal = Calendar(identifier: .gregorian)
            if let date = cal.date(from: dc) {
                return formatCalloutDate(date: date, period: period, formatter: formatter)
            }
        }
    }

    // Fallback
    return label
}

func formatCalloutDate(date: Date, period: AdminHomeView.Period, formatter: DateFormatter) -> String {
    switch period {
    case .month:
        formatter.dateFormat = "d MMM yyyy"
    case .year, .program:
        formatter.dateFormat = "MMM yyyy"
    case .week:
        formatter.dateFormat = "EEE, d MMM"
    }
    return formatter.string(from: date)
}

func rangeLabel(for period: AdminHomeView.Period) -> String {
    rangeLabel(for: period, startDate: Date(), endDate: Date())
}

func rangeLabel(for period: AdminHomeView.Period, startDate: Date, endDate: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current
    let today = Date()

    switch period {
    case .week:
        return "This Week"
    case .month:
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: today)
    case .year:
        formatter.dateFormat = "yyyy"
        return formatter.string(from: today)
    case .program:
        formatter.dateFormat = "MMM yyyy"
        let startText = formatter.string(from: startDate)
        let endText = formatter.string(from: endDate)
        return "\(startText) – \(endText)"
    }
}

// MARK: - Distribution card
struct DistributionByDayCard: View {
    let points: [DistributionPoint]
    var interactive: Bool = true
    @State private var selected: DistributionPoint?

    private var yMax: Double {
        max(Double(points.map { $0.workouts }.max() ?? 1), 1)
    }

    var body: some View {
        CardShell(
            background: Color(.systemBackground).opacity(0.95),
            strokeColor: Color(.systemGray4).opacity(0.6),
            height: 280
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Workout Distribution by Day")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color(.label))
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
                    let barWidth: CGFloat = 14
                    ScrollableBarChart(barCount: points.count, minBarWidth: barWidth) {
                        Chart {
                            ForEach(points) { point in
                                BarMark(
                                    x: .value("Day", point.short),
                                    y: .value("Workouts", point.workouts),
                                    width: .fixed(barWidth)
                                )
                                .foregroundStyle(.orange.opacity(0.9))
                                .cornerRadius(8)
                            }

                            if interactive, let tapped = selected {
                                RuleMark(x: .value("Day", tapped.short))
                                    .lineStyle(.init(lineWidth: 1, dash: [4]))
                                    .foregroundStyle(Color(.tertiaryLabel))
                                    .annotation(position: .top, spacing: 6) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(tapped.label)
                                                .font(.caption.weight(.semibold))
                                            HStack {
                                                Circle().fill(.orange).frame(width: 6, height: 6)
                                                Text("Workouts: \(tapped.workouts)")
                                            }
                                            .font(.caption2)
                                        }
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(Color(.systemBackground))
                                                .shadow(radius: 4, y: 2)
                                        )
                                    }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: points.map { $0.short }) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let s = value.as(String.self) {
                                        Text(s)
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: .automatic(desiredCount: 4))
                        }
                        .chartYScale(domain: 0...(yMax * 1.1))
                        .frame(height: 220)
                        .drawingGroup()
                        .chartOverlay { _ in
                            if interactive {
                                ChartOverlay(points: points, selected: $selected)
                            }
                        }
                    }
                    .frame(height: 220)
                }
            }
        }
    }
}

struct ChartOverlay: View {
    let points: [DistributionPoint]
    @Binding var selected: DistributionPoint?

    var body: some View {
        GeometryReader { geo in
            Rectangle().fill(.clear).contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let frame = geo.frame(in: .local)
                            let xRel = value.location.x - frame.origin.x
                            let slot = xRel / frame.width
                            let total = max(points.count - 1, 1)
                            let idx = min(max(Int(round(slot * CGFloat(total))), 0), points.count - 1)
                            selected = points[idx]
                        }
                        .onEnded { _ in
                            selected = nil
                        }
                )
        }
    }
}

// MARK: - Workout type colors
func typeColor(for name: String) -> Color {
    workoutTypePaletteColor(for: name)
}

func barColor(for type: APIClient.WorkoutTypeDTO) -> Color {
    type.workout_name == "Others" ? Color(.systemGray3) : typeColor(for: type.workout_name)
}

// MARK: - Distribution detail
struct DistributionByDayDetailView: View {
    let points: [DistributionPoint]
    @State private var selected: DistributionPoint?

    private var yMax: Double {
        max(Double(points.map { $0.workouts }.max() ?? 1), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Distribution by Day")
                .font(.title3.weight(.semibold))
            Text("Workouts")
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))

            let barWidth: CGFloat = 14
            ScrollableBarChart(barCount: points.count, minBarWidth: barWidth) {
                Chart {
                    ForEach(points) { point in
                        BarMark(
                            x: .value("Day", point.short),
                            y: .value("Workouts", point.workouts),
                            width: .fixed(barWidth)
                        )
                        .foregroundStyle(.orange.opacity(0.9))
                        .cornerRadius(8)
                    }

                    if let tapped = selected {
                        RuleMark(x: .value("Day", tapped.short))
                            .lineStyle(.init(lineWidth: 1, dash: [4]))
                            .foregroundStyle(Color(.tertiaryLabel))
                            .annotation(position: .top, spacing: 6) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tapped.label)
                                        .font(.caption.weight(.semibold))
                                    HStack {
                                        Circle().fill(.orange).frame(width: 6, height: 6)
                                        Text("Workouts: \(tapped.workouts)")
                                    }
                                    .font(.caption2)
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color(.systemBackground))
                                        .shadow(radius: 4, y: 2)
                                )
                            }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: points.map { $0.short }) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let s = value.as(String.self) {
                                Text(s)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4))
                }
                .chartYScale(domain: 0...(yMax * 1.1))
                .frame(height: 280)
                .drawingGroup()
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        if let selected {
                            if let xPos = proxy.position(forX: selected.short),
                               let yPos = proxy.position(forY: selected.workouts) {
                                let plotFrame = proxy.plotAreaFrame
                                let anchorX = geo[plotFrame].origin.x + xPos
                                let anchorY = geo[plotFrame].origin.y + yPos

                                CalloutView(
                                    label: selected.label,
                                    workouts: selected.workouts,
                                    active: nil,
                                    showActive: false
                                )
                                .position(
                                    x: clamp(anchorX, min: geo.size.width * 0.15, max: geo.size.width * 0.85),
                                    y: max(geo[plotFrame].minY + 12, anchorY - 30)
                                )
                            }
                        }

                        ChartOverlay(points: points, selected: $selected)
                    }
                }
            }
            .frame(height: 280)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}
