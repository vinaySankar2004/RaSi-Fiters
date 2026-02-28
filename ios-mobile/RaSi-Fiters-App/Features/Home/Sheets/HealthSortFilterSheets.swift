import SwiftUI

// MARK: - View Health Sort Field Enum
enum HealthSortField: String, CaseIterable {
    case date
    case sleep_hours
    case food_quality

    var label: String {
        switch self {
        case .date: return "Date"
        case .sleep_hours: return "Sleep Hours"
        case .food_quality: return "Diet Quality"
        }
    }

    var apiValue: String { rawValue }
}

// MARK: - View Health Sort Direction Enum
enum HealthSortDirection: String, CaseIterable {
    case asc
    case desc

    var label: String {
        switch self {
        case .asc: return "Ascending"
        case .desc: return "Descending"
        }
    }

    var icon: String {
        switch self {
        case .asc: return "arrow.up"
        case .desc: return "arrow.down"
        }
    }

    var apiValue: String { rawValue }
}

// MARK: - View Health Filters
struct HealthFilters: Equatable {
    var startDate: Date?
    var endDate: Date?

    var isActive: Bool {
        startDate != nil || endDate != nil
    }

    func startDateString() -> String? {
        guard let startDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: startDate)
    }

    func endDateString() -> String? {
        guard let endDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: endDate)
    }
}

struct MemberHealthDetail: View {
    @EnvironmentObject var programContext: ProgramContext
    let memberId: String?
    let memberName: String?
    @State private var sortField: HealthSortField = .date
    @State private var sortDirection: HealthSortDirection = .desc
    @State private var showSortSheet = false
    @State private var showFilterSheet = false
    @State private var filters = HealthFilters()
    @State private var isLoading = false
    @State private var shareItem: ShareItem?
    @State private var showDeleteAlert = false
    @State private var itemToDelete: APIClient.MemberHealthLogResponse.Item?
    @State private var deleteErrorMessage: String?
    @State private var showDeleteErrorAlert = false
    @State private var itemToEdit: APIClient.MemberHealthLogResponse.Item?

    var body: some View {
        VStack(spacing: 0) {
            controls
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 14)

            contentList
        }
        .navigationTitle("View Health")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await exportCSV() }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(programContext.memberHealthLogs.isEmpty)
            }
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: [item.url])
        }
        .sheet(isPresented: $showSortSheet) {
            HealthSortSheet(sortField: $sortField, sortDirection: $sortDirection)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showFilterSheet) {
            HealthFilterSheet(filters: $filters)
                .presentationDetents([.medium])
        }
        .sheet(item: $itemToEdit) { item in
            if let mId = memberId {
                DailyHealthEditSheet(memberId: mId, item: item) {
                    Task { await loadHealthLogs() }
                }
                .environmentObject(programContext)
            }
        }
        .alert("Delete Daily Health Log", isPresented: $showDeleteAlert, presenting: itemToDelete) { item in
            Button("Delete", role: .destructive) {
                Task { await deleteHealthLog(item) }
            }
            Button("Cancel", role: .cancel) { }
        } message: { item in
            Text("Are you sure you want to delete this daily health log from \(item.logDate)?")
        }
        .alert("Delete Failed", isPresented: $showDeleteErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteErrorMessage ?? "Unable to delete daily health log.")
        }
        .task { await loadHealthLogs() }
        .onChange(of: sortField) { _, _ in Task { await loadHealthLogs() } }
        .onChange(of: sortDirection) { _, _ in Task { await loadHealthLogs() } }
        .onChange(of: filters) { _, _ in Task { await loadHealthLogs() } }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Button {
                    showSortSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: sortDirection.icon)
                            .font(.footnote.weight(.bold))
                        Text("Sort: \(sortField.label)")
                            .font(.subheadline.weight(.semibold))
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
                        Image(systemName: filters.isActive ? "line.horizontal.3.decrease.circle.fill" : "line.horizontal.3.decrease.circle")
                            .font(.headline)
                        Text("Filter")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(filters.isActive ? Color.appBlueLight : Color(.systemGray6))
                    .cornerRadius(12)
                }
            }

            if filters.isActive {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                    if let start = filters.startDate {
                        Text(formatDate(start))
                            .font(.caption.weight(.medium))
                    }
                    Text("-")
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                    if let end = filters.endDate {
                        Text(formatDate(end))
                            .font(.caption.weight(.medium))
                    }
                    Spacer()
                    Button {
                        filters = HealthFilters()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }

    private var contentList: some View {
        Group {
            if isLoading {
                VStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray5))
                            .frame(height: 60)
                            .redacted(reason: .placeholder)
                    }
                }
                .padding(.horizontal, 20)
            } else if programContext.memberHealthLogs.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No daily health logs found.")
                        .font(.subheadline.weight(.semibold))
                    Text("Adjust filters or log daily health to get started.")
                        .font(.footnote)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            } else {
                List {
                    ForEach(programContext.memberHealthLogs) { item in
                        healthRow(item)
                            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    itemToEdit = item
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.appBlue)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    itemToDelete = item
                                    showDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func healthRow(_ item: APIClient.MemberHealthLogResponse.Item) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.appBlueLight)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text("Sleep \(sleepLabel(item.sleepHours))")
                    .font(.subheadline.weight(.semibold))
                Text(item.logDate)
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
            }
            Spacer()
            Text("Diet \(foodLabel(item.foodQuality))")
                .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
        )
    }

    private func sleepLabel(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f hrs", value)
    }

    private func foodLabel(_ value: Int?) -> String {
        guard let value else { return "—" }
        return "\(value)/5"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func loadHealthLogs() async {
        guard !isLoading else { return }
        guard let mId = memberId else { return }
        isLoading = true
        await programContext.loadMemberHealthLogs(
            memberId: mId,
            limit: 0,
            startDate: filters.startDateString(),
            endDate: filters.endDateString(),
            sortBy: sortField.apiValue,
            sortDir: sortDirection.apiValue
        )
        isLoading = false
    }

    private func deleteHealthLog(_ item: APIClient.MemberHealthLogResponse.Item) async {
        guard let mId = memberId else { return }
        do {
            try await programContext.deleteDailyHealthLog(
                memberId: mId,
                logDate: item.logDate
            )
            await loadHealthLogs()
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteErrorAlert = true
        }
    }

    private func exportCSV() async {
        guard !programContext.memberHealthLogs.isEmpty else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        let startLabel = filters.startDate.flatMap { formatter.string(from: $0) } ?? "all"
        let endLabel = filters.endDate.flatMap { formatter.string(from: $0) } ?? "today"
        let exportMemberName = (memberName ?? "Member").replacingOccurrences(of: " ", with: "")
        let fileName = "HealthLogs_\(exportMemberName)_\(startLabel)_to_\(endLabel).csv"

        var csv = "Date,Sleep Hours,Diet Quality\n"
        for log in programContext.memberHealthLogs {
            let sleepValue = log.sleepHours.map { String(format: "%.1f", $0) } ?? ""
            let foodValue = log.foodQuality.map { "\($0)" } ?? ""
            let line = "\(log.logDate),\(sleepValue),\(foodValue)\n"
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

// MARK: - Health Sort Sheet
struct HealthSortSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sortField: HealthSortField
    @Binding var sortDirection: HealthSortDirection

    var body: some View {
        NavigationView {
            List {
                Section("Sort By") {
                    ForEach(HealthSortField.allCases, id: \.self) { field in
                        Button {
                            sortField = field
                        } label: {
                            HStack {
                                Text(field.label)
                                    .foregroundColor(Color(.label))
                                Spacer()
                                if sortField == field {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.appBlue)
                                }
                            }
                        }
                    }
                }

                Section("Direction") {
                    ForEach(HealthSortDirection.allCases, id: \.self) { direction in
                        Button {
                            sortDirection = direction
                        } label: {
                            HStack {
                                Image(systemName: direction.icon)
                                    .foregroundColor(Color(.secondaryLabel))
                                Text(direction.label)
                                    .foregroundColor(Color(.label))
                                Spacer()
                                if sortDirection == direction {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.appBlue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Health Filter Sheet
struct HealthFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: HealthFilters
    @State private var localStartDate: Date = Date()
    @State private var localEndDate: Date = Date()
    @State private var useStartDate: Bool = false
    @State private var useEndDate: Bool = false

    var body: some View {
        NavigationView {
            List {
                Section("Date Range") {
                    Toggle("Start Date", isOn: $useStartDate)
                    if useStartDate {
                        DatePicker("From", selection: $localStartDate, displayedComponents: .date)
                    }

                    Toggle("End Date", isOn: $useEndDate)
                    if useEndDate {
                        DatePicker("To", selection: $localEndDate, displayedComponents: .date)
                    }
                }

                if filters.isActive {
                    Section {
                        Button("Clear All Filters", role: .destructive) {
                            filters = HealthFilters()
                            useStartDate = false
                            useEndDate = false
                        }
                    }
                }
            }
            .navigationTitle("Filter Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let start = filters.startDate {
                    localStartDate = start
                    useStartDate = true
                }
                if let end = filters.endDate {
                    localEndDate = end
                    useEndDate = true
                }
            }
        }
    }

    private func applyFilters() {
        filters.startDate = useStartDate ? localStartDate : nil
        filters.endDate = useEndDate ? localEndDate : nil
    }
}

struct DailyHealthEditSheet: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.dismiss) private var dismiss
    let memberId: String
    let item: APIClient.MemberHealthLogResponse.Item
    let onSaved: () -> Void

    @State private var sleepHoursText: String
    @State private var sleepMinutesText: String
    @State private var foodQuality: Int?
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    init(memberId: String, item: APIClient.MemberHealthLogResponse.Item, onSaved: @escaping () -> Void) {
        self.memberId = memberId
        self.item = item
        self.onSaved = onSaved
        let split = Self.splitSleepHours(item.sleepHours)
        _sleepHoursText = State(initialValue: split.hours)
        _sleepMinutesText = State(initialValue: split.minutes)
        _foodQuality = State(initialValue: item.foodQuality)
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
        isSleepValid && hasAtLeastOneMetric
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit daily health")
                        .font(.title2.weight(.bold))
                        .foregroundColor(Color(.label))
                    Text(item.logDate)
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
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

                Button(action: { Task { await save() } }) {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Save changes")
                            .font(.headline.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.appBlue : Color(.systemGray3))
                .foregroundColor(.white)
                .cornerRadius(14)
                .disabled(isSaving || !isFormValid)
            }
            .padding(20)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .alert("Unable to save", isPresented: $showErrorAlert) {
            Button("OK") { showErrorAlert = false }
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
    }

    private func save() async {
        guard isFormValid else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await programContext.updateDailyHealthLog(
                memberId: memberId,
                logDate: item.logDate,
                sleepHours: sleepValue,
                foodQuality: foodQuality
            )
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isSaving = false
    }

    private static func splitSleepHours(_ value: Double?) -> (hours: String, minutes: String) {
        guard let value else { return ("", "") }
        let clamped = min(max(value, 0), 24)
        var hours = Int(clamped)
        var minutes = Int((clamped - Double(hours)) * 60.0 + 0.5)
        if minutes == 60 {
            hours = min(hours + 1, 24)
            minutes = 0
        }
        if hours >= 24 {
            hours = 24
            minutes = 0
        }
        return (String(hours), String(minutes))
    }

    private func sanitizeDigits(_ value: String) -> String {
        let filtered = value.filter { $0.isNumber }
        return String(filtered.prefix(2))
    }
}

struct WorkoutLogEditSheet: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.dismiss) private var dismiss
    let memberName: String?
    let item: APIClient.MemberRecentWorkoutsResponse.Item
    let onSaved: (Int) -> Void

    @State private var durationText: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    init(
        memberName: String?,
        item: APIClient.MemberRecentWorkoutsResponse.Item,
        onSaved: @escaping (Int) -> Void
    ) {
        self.memberName = memberName
        self.item = item
        self.onSaved = onSaved
        _durationText = State(initialValue: "\(item.durationMinutes)")
    }

    private var trimmedDurationText: String {
        durationText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var durationValue: Int? {
        guard !trimmedDurationText.isEmpty else { return nil }
        return Int(trimmedDurationText)
    }

    private var isDurationValid: Bool {
        guard let durationValue else { return false }
        return durationValue > 0
    }

    private var isFormValid: Bool {
        isDurationValid
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit workout log")
                        .font(.title2.weight(.bold))
                        .foregroundColor(Color(.label))
                    Text(item.workoutType)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(.secondaryLabel))
                    Text(item.workoutDate)
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Duration (minutes)")
                        .font(.subheadline.weight(.semibold))
                    TextField("e.g. 45", text: $durationText)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    if !isDurationValid {
                        Text("Enter a duration greater than 0.")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.appRed)
                    }
                }

                Button(action: { Task { await save() } }) {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Save changes")
                            .font(.headline.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.appBlue : Color(.systemGray3))
                .foregroundColor(.white)
                .cornerRadius(14)
                .disabled(isSaving || !isFormValid)
            }
            .padding(20)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .alert("Unable to save", isPresented: $showErrorAlert) {
            Button("OK") { showErrorAlert = false }
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
    }

    private func save() async {
        guard let durationValue, isFormValid else { return }
        isSaving = true
        errorMessage = nil

        do {
            try await programContext.updateWorkoutLog(
                memberName: memberName,
                workoutName: item.workoutType,
                date: item.workoutDate,
                durationMinutes: durationValue
            )
            onSaved(durationValue)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isSaving = false
    }
}
