import SwiftUI

// MARK: - Member Metrics Module

struct MemberMetricsModule: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var isExpanded = false
    @State private var searchText = ""
    @State private var sortField: SortField = .workouts
    @State private var sortDirection: SortDirection = .desc
    @State private var showSortSheet = false
    @State private var showFilterSheet = false
    @State private var filters = MetricsFilters()
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 12) {
            headerRow

            if isExpanded {
                controls
                contentList
            } else {
                previewRow
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: isExpanded)
        .task { await loadMetrics() }
        .onChange(of: sortField) { _, _ in Task { await loadMetrics() } }
        .onChange(of: sortDirection) { _, _ in Task { await loadMetrics() } }
        .onChange(of: filters) { _, _ in Task { await loadMetrics() } }
        .onChange(of: programContext.programId) { _, _ in Task { await loadMetrics() } }
    }

    private var headerRow: some View {
        Button {
            withAnimation { isExpanded.toggle() }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Member Performance Metrics")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color(.label))
                    Text(memberCountText)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(Color(.secondaryLabel))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .foregroundColor(Color(.tertiaryLabel))
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
            .adaptiveShadow(radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var previewRow: some View {
        HStack {
            Text(previewText)
                .font(.footnote)
                .foregroundColor(Color(.secondaryLabel))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(.tertiaryLabel))
                TextField("Search member", text: $searchText, onCommit: {
                    Task { await loadMetrics() }
                })
                .textInputAutocapitalization(.none)
                .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        Task { await loadMetrics() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Sort & Filter row
            HStack(spacing: 10) {
                Button {
                    showSortSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Text("Sort by \(sortField.label)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.appOrange)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.footnote.weight(.bold))
                            .foregroundColor(.appOrange)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .adaptiveTint()

                Button {
                    showFilterSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Text("Filter")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.appOrange)
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .font(.headline)
                            .foregroundColor(.appOrange)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .adaptiveTint()
            }
        }
            .sheet(isPresented: $showSortSheet) {
                SortSheet(
                    sortField: $sortField,
                    sortDirection: $sortDirection
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheet(filters: $filters)
                    .environmentObject(programContext)
                    .presentationDetents([.large])
            }
    }

    private var contentList: some View {
        Group {
            if isLoading {
                VStack(spacing: 10) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemGray5))
                            .frame(height: 130)
                            .redacted(reason: .placeholder)
                    }
                }
            } else if programContext.memberMetrics.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No members to display.")
                        .font(.subheadline.weight(.semibold))
                    Text("Adjust filters or try a different search.")
                        .font(.footnote)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(programContext.memberMetrics) { metric in
                        MemberMetricsCard(metric: metric, hero: sortField)
                    }
                }
            }
        }
    }

    private var memberCountText: String {
        let count = programContext.memberMetricsFiltered > 0 ? programContext.memberMetricsFiltered : programContext.memberMetricsTotal
        return "\(count) members"
    }

    private var previewText: String {
        if let top = programContext.memberMetrics.first {
            return "Top by \(sortField.label): \(top.member_name)"
        }
        return "Sorted by \(sortField.label)"
    }

    private func loadMetrics() async {
        guard !isLoading else { return }
        isLoading = true
        var filterParams: [String: String] = [:]
        filters.addTo(&filterParams)
        await programContext.loadMemberMetrics(
            search: searchText,
            sort: sortField.rawValue,
            direction: sortDirection.rawValue,
            filters: filterParams
        )
        isLoading = false
    }
}

// MARK: - Member Metrics Detail & Preview

struct MemberMetricsDetailView: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var searchText = ""
    @State private var sortField: SortField = .workouts
    @State private var sortDirection: SortDirection = .desc
    @State private var showSortSheet = false
    @State private var showFilterSheet = false
    @State private var filters = MetricsFilters()
    @State private var isLoading = false
    @State private var showShare = false
    @State private var shareItem: ShareItem?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                controls
                contentList
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .navigationTitle("Member Performance Metrics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await exportCSV() }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(programContext.memberMetrics.isEmpty)
            }
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: [item.url])
        }
        .task { await loadMetrics() }
        .onChange(of: sortField) { _, _ in Task { await loadMetrics() } }
        .onChange(of: sortDirection) { _, _ in Task { await loadMetrics() } }
        .onChange(of: filters) { _, _ in Task { await loadMetrics() } }
        .onChange(of: programContext.programId) { _, _ in Task { await loadMetrics() } }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(.tertiaryLabel))
                TextField("Search member", text: $searchText, onCommit: {
                    Task { await loadMetrics() }
                })
                .textInputAutocapitalization(.none)
                .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        Task { await loadMetrics() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(12)

            HStack(spacing: 10) {
                Button {
                    showSortSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Text("Sort by \(sortField.label)")
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.footnote.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                Button {
                    showFilterSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Text("Filter")
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
        .sheet(isPresented: $showSortSheet) {
            SortSheet(
                sortField: $sortField,
                sortDirection: $sortDirection
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(filters: $filters)
                .presentationDetents([.large])
        }
    }

    private var contentList: some View {
        Group {
            if isLoading {
                VStack(spacing: 10) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemGray5))
                            .frame(height: 130)
                            .redacted(reason: .placeholder)
                    }
                }
            } else if programContext.memberMetrics.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No members to display.")
                        .font(.subheadline.weight(.semibold))
                    Text("Adjust filters or try a different search.")
                        .font(.footnote)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(programContext.memberMetrics) { metric in
                        MemberMetricsCard(metric: metric, hero: sortField)
                    }
                }
            }
        }
    }

    private func loadMetrics() async {
        guard !isLoading else { return }
        isLoading = true
        var filterParams: [String: String] = [:]
        filters.addTo(&filterParams)
        await programContext.loadMemberMetrics(
            search: searchText,
            sort: sortField.rawValue,
            direction: sortDirection.rawValue,
            filters: filterParams,
            dateRange: (filters.startDate, filters.endDate)
        )
        isLoading = false
    }

    private func exportCSV() async {
        guard !programContext.memberMetrics.isEmpty else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        let startLabel = (filters.startDate ?? programContext.memberMetricsRangeStart).flatMap { formatter.string(from: $0) } ?? "all"
        let endLabel = (filters.endDate ?? programContext.memberMetricsRangeEnd).flatMap { formatter.string(from: $0) } ?? "today"
        let programName = programContext.name.replacingOccurrences(of: " ", with: "")
        let fileName = "MemberPerformanceMetrics_\(programName)_\(startLabel)_to_\(endLabel).csv"

        var csv = "Name,Workouts,Total Duration,Avg Duration,Avg Sleep,Avg Diet Quality,Active Days,Workout Types,Current Streak,Longest Streak\n"
        for m in programContext.memberMetrics {
            let avgSleep = m.avg_sleep_hours.map { String(format: "%.1f", $0) } ?? ""
            let avgFood = m.avg_food_quality.map { "\($0)" } ?? ""
            let line = "\"\(m.member_name.replacingOccurrences(of: "\"", with: "\"\""))\",\(m.workouts),\(m.total_duration),\(m.avg_duration),\(avgSleep),\(avgFood),\(m.active_days),\(m.workout_types),\(m.current_streak),\(m.longest_streak)\n"
            csv.append(line)
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            shareItem = ShareItem(url: url)
        } catch {
            // silently fail for now
        }
    }
}

struct MemberMetricsPreviewCard: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var isLoading = false
    @State private var sortField: SortField = .workouts
    @State private var sortDirection: SortDirection = .desc

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Member Performance Metrics")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color(.label))
                    Text("\(memberCount) members")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }

            if isLoading {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 120)
                    .redacted(reason: .placeholder)
            } else if let top = programContext.memberMetrics.first {
                topPreview(top)
            } else {
                Text("No members to display")
                    .font(.footnote)
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        )
        .adaptiveShadow(radius: 10, y: 6)
        .task { await loadTop() }
    }

    private var memberCount: Int {
        programContext.memberMetricsTotal > 0 ? programContext.memberMetricsTotal : programContext.memberMetrics.count
    }

    private func topPreview(_ metric: APIClient.MemberMetricsDTO) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.appOrange)
                        .font(.caption)
                    Text(metric.member_name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(.label))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(heroValue(metric))
                        .font(.title3.weight(.bold))
                        .foregroundColor(.appOrange)
                    Text("\(sortField.label)")
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            HStack(spacing: 12) {
                miniTile(title: "Workouts", value: "\(metric.workouts)")
                miniTile(title: "Active Days", value: "\(metric.active_days)")
                miniTile(title: "Types", value: "\(metric.workout_types)")
            }
        }
    }

    private func miniTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color(.label))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private func heroValue(_ metric: APIClient.MemberMetricsDTO) -> String {
        switch sortField {
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

    private func loadTop() async {
        guard !isLoading else { return }
        isLoading = true
        await programContext.loadMemberMetrics(
            search: "",
            sort: sortField.rawValue,
            direction: sortDirection.rawValue,
            filters: [:],
            dateRange: (nil, nil)
        )
        isLoading = false
    }
}
