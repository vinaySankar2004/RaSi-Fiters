import SwiftUI

// MARK: - Member Picker and Overview

struct MemberPickerView: View {
    let members: [APIClient.MemberDTO]
    let selected: APIClient.MemberDTO?
    let showNoneOption: Bool
    let noneLabel: String
    let onSelect: (APIClient.MemberDTO?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    init(
        members: [APIClient.MemberDTO],
        selected: APIClient.MemberDTO?,
        showNoneOption: Bool = true,
        noneLabel: String = "None",
        onSelect: @escaping (APIClient.MemberDTO?) -> Void
    ) {
        self.members = members
        self.selected = selected
        self.showNoneOption = showNoneOption
        self.noneLabel = noneLabel
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            List {
                if showNoneOption {
                    Button {
                        onSelect(nil)
                        dismiss()
                    } label: {
                        HStack {
                            Text(noneLabel)
                            if selected == nil {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.appOrange)
                            }
                        }
                    }
                }

                ForEach(filtered, id: \.id) { member in
                    Button {
                        onSelect(member)
                        dismiss()
                    } label: {
                        HStack {
                            Text(member.member_name)
                            Spacer()
                            if member.id == selected?.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.appOrange)
                            }
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Search member")
            .navigationTitle("View as")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var filtered: [APIClient.MemberDTO] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return members }
        return members.filter { $0.member_name.lowercased().contains(q) }
    }
}

struct MemberOverviewCard: View {
    @EnvironmentObject var programContext: ProgramContext
    let member: APIClient.MemberDTO?

    private var overview: APIClient.MemberMetricsDTO? { programContext.selectedMemberOverview }
    private var programTotalDays: Int {
        let start = programContext.startDate
        let end = min(programContext.endDate, Date())
        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
        return max(days + 1, 1)
    }
    private func memberProgressPercent(activeDays: Int) -> Int {
        let pct = Double(activeDays) / Double(programTotalDays)
        return Int(round(pct * 100))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Member Overview")
                    .font(.headline.weight(.semibold))
                Spacer()
            }

            if let m = overview {
                topRow(for: m)
                statsGrid(for: m)
                progress(for: m)
            } else {
                Text("No workouts logged yet.")
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
        )
        .adaptiveShadow(radius: 8, y: 4)
    }

    private func topRow(for m: APIClient.MemberMetricsDTO) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(initials(for: m.member_name))
                        .font(.headline.weight(.bold))
                        .foregroundColor(Color(.label))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(m.member_name)
                    .font(.headline.weight(.semibold))
                Text("MTD Workouts: \(m.mtd_workouts ?? 0)")
                    .font(.footnote)
                    .foregroundColor(Color(.secondaryLabel))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                let mp = memberProgressPercent(activeDays: m.active_days)
                Text("\(mp)%")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.appOrange)
                Text("PTD MP %")
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
    }

    private func statsGrid(for m: APIClient.MemberMetricsDTO) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                overviewTile(title: "Total Time", value: "\(m.total_hours ?? m.total_duration / 60) hrs", accent: .purple)
                overviewTile(title: "Favorite", value: m.favorite_workout ?? "—", accent: .green)
            }
        }
    }

    private func progress(for m: APIClient.MemberMetricsDTO) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PTD - Member Progress")
                .font(.subheadline.weight(.semibold))
            ProgressView(value: Double(m.active_days), total: Double(programTotalDays))
                .progressViewStyle(.linear)
                .adaptiveTint()
            Text("\(m.active_days) / \(programTotalDays) days")
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
        }
    }

    private func overviewTile(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(Color(.secondaryLabel))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func initials(for name: String) -> String {
        let comps = name.split(separator: " ").compactMap { $0.first }
        return comps.prefix(2).map { String($0).uppercased() }.joined()
    }
}
enum SortField: String, CaseIterable, Hashable {
    case workouts
    case total_duration
    case avg_duration
    case avg_sleep_hours
    case active_days
    case workout_types
    case current_streak
    case longest_streak
    case avg_food_quality

    var label: String {
        switch self {
        case .workouts: return "Workouts"
        case .total_duration: return "Total Duration"
        case .avg_duration: return "Avg Duration"
        case .avg_sleep_hours: return "Avg Sleep"
        case .active_days: return "Active Days"
        case .workout_types: return "Workout Types"
        case .current_streak: return "Current Streak"
        case .longest_streak: return "Longest Streak"
        case .avg_food_quality: return "Avg Diet Quality"
        }
    }

    var chipLabel: String {
        switch self {
        case .workouts: return "Workouts"
        case .active_days: return "Active Days"
        case .current_streak: return "Current Streak"
        case .avg_sleep_hours: return "Avg Sleep"
        case .avg_food_quality: return "Avg Diet"
        default: return label
        }
    }
}

enum SortDirection: String, Hashable {
    case asc
    case desc
}

struct MetricsFilters: Hashable {
    enum DateMode: String, Hashable {
        case all
        case custom
    }

    var dateMode: DateMode = .all
    var startDate: Date? = nil
    var endDate: Date? = nil
    var workoutsMin: String = ""
    var workoutsMax: String = ""
    var totalDurationMin: String = ""
    var totalDurationMax: String = ""
    var avgDurationMin: String = ""
    var avgDurationMax: String = ""
    var avgSleepHoursMin: String = ""
    var avgSleepHoursMax: String = ""
    var activeDaysMin: String = ""
    var activeDaysMax: String = ""
    var workoutTypesMin: String = ""
    var workoutTypesMax: String = ""
    var currentStreakMin: String = ""
    var longestStreakMin: String = ""
    var avgFoodQualityMin: String = ""
    var avgFoodQualityMax: String = ""

    mutating func clear() {
        dateMode = .all
        startDate = nil
        endDate = nil
        workoutsMin = ""; workoutsMax = ""
        totalDurationMin = ""; totalDurationMax = ""
        avgDurationMin = ""; avgDurationMax = ""
        avgSleepHoursMin = ""; avgSleepHoursMax = ""
        activeDaysMin = ""; activeDaysMax = ""
        workoutTypesMin = ""; workoutTypesMax = ""
        currentStreakMin = ""; longestStreakMin = ""
        avgFoodQualityMin = ""; avgFoodQualityMax = ""
    }

    func addTo(_ dict: inout [String: String]) {
        if dateMode == .custom {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let s = startDate { dict["startDate"] = formatter.string(from: s) }
            if let e = endDate { dict["endDate"] = formatter.string(from: e) }
        }
        dict["workoutsMin"] = workoutsMin
        dict["workoutsMax"] = workoutsMax
        dict["totalDurationMin"] = totalDurationMin
        dict["totalDurationMax"] = totalDurationMax
        dict["avgDurationMin"] = avgDurationMin
        dict["avgDurationMax"] = avgDurationMax
        dict["avgSleepHoursMin"] = avgSleepHoursMin
        dict["avgSleepHoursMax"] = avgSleepHoursMax
        dict["activeDaysMin"] = activeDaysMin
        dict["activeDaysMax"] = activeDaysMax
        dict["workoutTypesMin"] = workoutTypesMin
        dict["workoutTypesMax"] = workoutTypesMax
        dict["currentStreakMin"] = currentStreakMin
        dict["longestStreakMin"] = longestStreakMin
        dict["avgFoodQualityMin"] = avgFoodQualityMin
        dict["avgFoodQualityMax"] = avgFoodQualityMax
    }
}

struct SortSheet: View {
    @Binding var sortField: SortField
    @Binding var sortDirection: SortDirection

    var body: some View {
        NavigationStack {
            Form {
                Section("Sort by") {
                    ForEach(SortField.allCases, id: \.self) { field in
                        HStack {
                            Text(field.label)
                            Spacer()
                            if field == sortField {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.appOrange)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { sortField = field }
                    }
                }
                Section("Direction") {
                    Picker("Direction", selection: $sortDirection) {
                        Text("Descending").tag(SortDirection.desc)
                        Text("Ascending").tag(SortDirection.asc)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Sort")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FilterSheet: View {
    @Binding var filters: MetricsFilters
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.dismiss) private var dismiss
    private var today: Date { Date() }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    Picker("Range", selection: $filters.dateMode) {
                        Text("All").tag(MetricsFilters.DateMode.all)
                        Text("Custom").tag(MetricsFilters.DateMode.custom)
                    }
                    .pickerStyle(.segmented)

                    if filters.dateMode == .custom {
                        DatePicker("Start", selection: Binding(get: {
                            filters.startDate ?? (programContext.startDate)
                        }, set: { filters.startDate = $0 }), in: (programContext.startDate)...today, displayedComponents: .date)
                        DatePicker("End", selection: Binding(get: {
                            filters.endDate ?? today
                        }, set: { filters.endDate = $0 }), in: (filters.startDate ?? programContext.startDate)...today, displayedComponents: .date)
                        Text("Metrics follow the selected date range.")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }

                Section("Workouts") { rangeFields(min: $filters.workoutsMin, max: $filters.workoutsMax, unit: "") }
                Section("Total Duration (mins)") { rangeFields(min: $filters.totalDurationMin, max: $filters.totalDurationMax, unit: "mins") }
                Section("Avg Duration (mins)") { rangeFields(min: $filters.avgDurationMin, max: $filters.avgDurationMax, unit: "mins") }
                Section("Avg Sleep (hrs)") { rangeFields(min: $filters.avgSleepHoursMin, max: $filters.avgSleepHoursMax, unit: "hrs") }
                Section("Active Days") { rangeFields(min: $filters.activeDaysMin, max: $filters.activeDaysMax, unit: "days") }
                Section("Workout Types") { rangeFields(min: $filters.workoutTypesMin, max: $filters.workoutTypesMax, unit: "types") }
                Section("Current Streak") { minField(title: "Min", value: $filters.currentStreakMin, unit: "days") }
                Section("Longest Streak") { minField(title: "Min", value: $filters.longestStreakMin, unit: "days") }
                Section("Avg Diet Quality") { rangeFields(min: $filters.avgFoodQualityMin, max: $filters.avgFoodQualityMax, unit: "") }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear all") { filters.clear() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func rangeFields(min: Binding<String>, max: Binding<String>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            minField(title: "Min", value: min, unit: unit)
            minField(title: "Max", value: max, unit: unit)
        }
    }

    private func minField(title: String, value: Binding<String>, unit: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: value)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
            if !unit.isEmpty {
                Text(unit)
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
    }
}

struct MemberMetricsCard: View {
    let metric: APIClient.MemberMetricsDTO
    let hero: SortField

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(initials)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(Color(.label))
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.member_name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color(.label))
                    Text("Active days \(metric.active_days)")
                        .font(.footnote)
                        .foregroundColor(Color(.secondaryLabel))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(heroValue)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.appOrange)
                    Text(hero.label)
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }

            metricsGrid

            HStack {
                Label("Current Streak \(metric.current_streak)", systemImage: "flame.fill")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.appOrangeLight)
                    .foregroundColor(.appOrange)
                    .cornerRadius(10)
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
        )
        .adaptiveShadow(radius: 8, y: 4)
    }

    private var initials: String {
        let comps = metric.member_name.split(separator: " ").compactMap { $0.first }
        return comps.prefix(2).map { String($0).uppercased() }.joined()
    }

    private var heroValue: String {
        switch hero {
        case .workouts: return "\(metric.workouts)"
        case .total_duration: return "\(metric.total_duration) min"
        case .avg_duration: return "\(metric.avg_duration) min"
        case .avg_sleep_hours:
            return metric.avg_sleep_hours.map { String(format: "%.1f hrs", $0) } ?? "—"
        case .active_days: return "\(metric.active_days)"
        case .workout_types: return "\(metric.workout_types)"
        case .current_streak: return "\(metric.current_streak)"
        case .longest_streak: return "\(metric.longest_streak)"
        case .avg_food_quality:
            return metric.avg_food_quality.map { "\($0) / 5" } ?? "—"
        }
    }

    private var metricsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                metricTile(title: "Workouts", value: "\(metric.workouts)", icon: "figure.strengthtraining.traditional")
                metricTile(title: "Active Days", value: "\(metric.active_days)", icon: "calendar")
            }
            HStack(spacing: 10) {
                metricTile(title: "Workout Types", value: "\(metric.workout_types)", icon: "list.bullet")
                metricTile(title: "Total Duration", value: "\(metric.total_duration) min", icon: "clock")
            }
            HStack(spacing: 10) {
                metricTile(title: "Avg Duration", value: "\(metric.avg_duration) min", icon: "clock.arrow.circlepath")
                metricTile(title: "Longest Streak", value: "\(metric.longest_streak)", icon: "trophy.fill")
            }
            HStack(spacing: 10) {
                metricTile(title: "Avg Sleep", value: avgSleepValue, icon: "bed.double.fill")
                metricTile(title: "Avg Diet Quality", value: avgFoodValue, icon: "leaf.fill")
            }
        }
    }

    private func metricTile(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color(.tertiaryLabel))
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(.secondaryLabel))
            }
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color(.label))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var avgSleepValue: String {
        guard let value = metric.avg_sleep_hours else { return "—" }
        return String(format: "%.1f hrs", value)
    }

    private var avgFoodValue: String {
        guard let value = metric.avg_food_quality else { return "—" }
        return "\(value) / 5"
    }
}

func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
    Swift.max(min, Swift.min(max, value))
}

func memberTimelinePoints(from history: [APIClient.MemberHistoryPoint]) -> [APIClient.ActivityTimelinePoint] {
    history.map {
        APIClient.ActivityTimelinePoint(
            date: $0.date,
            label: $0.label,
            workouts: $0.workouts,
            active_members: 0
        )
    }
}
