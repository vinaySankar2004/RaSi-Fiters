import SwiftUI

private func formatDuration(_ totalMinutes: Int) -> String {
    let h = totalMinutes / 60
    let m = totalMinutes % 60
    if h == 0 { return "\(m)m" }
    if m == 0 { return "\(h)h" }
    return "\(h)h \(m)m"
}

// MARK: - View Workouts Sort Field Enum
enum WorkoutSortField: String, CaseIterable {
    case date
    case duration
    case workoutType
    
    var label: String {
        switch self {
        case .date: return "Date"
        case .duration: return "Duration"
        case .workoutType: return "Workout Type"
        }
    }
    
    var apiValue: String { rawValue }
}

// MARK: - View Workouts Sort Direction Enum
enum WorkoutSortDirection: String, CaseIterable {
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

// MARK: - View Workouts Filters
struct WorkoutFilters: Equatable {
    var startDate: Date?
    var endDate: Date?
    var workoutTypeName: String?
    var minDurationMinutes: Int?
    var maxDurationMinutes: Int?
    
    var isActive: Bool {
        startDate != nil || endDate != nil || workoutTypeName != nil || minDurationMinutes != nil || maxDurationMinutes != nil
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

struct MemberRecentDetail: View {
    @EnvironmentObject var programContext: ProgramContext
    let memberId: String?
    let memberName: String?
    @State private var sortField: WorkoutSortField = .date
    @State private var sortDirection: WorkoutSortDirection = .desc
    @State private var showSortSheet = false
    @State private var showFilterSheet = false
    @State private var filters = WorkoutFilters()
    @State private var isLoading = false
    @State private var shareItem: ShareItem?
    @State private var showDeleteAlert = false
    @State private var itemToDelete: APIClient.MemberRecentWorkoutsResponse.Item?
    @State private var deleteErrorMessage: String?
    @State private var showDeleteErrorAlert = false
    @State private var deleteSuccessMessage: String?
    @State private var showDeleteSuccessAlert = false
    @State private var itemToEdit: APIClient.MemberRecentWorkoutsResponse.Item?
    @State private var editSuccessMessage: String?
    @State private var showEditSuccessAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Controls section at the top
            controls
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 14)
            
            // List section for swipe-to-delete support
            contentList
        }
        .navigationTitle("View Workouts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await exportCSV() }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(programContext.memberRecent.isEmpty)
            }
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: [item.url])
        }
        .sheet(isPresented: $showSortSheet) {
            WorkoutSortSheet(sortField: $sortField, sortDirection: $sortDirection)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showFilterSheet) {
            WorkoutFilterSheet(filters: $filters)
                .environmentObject(programContext)
                .presentationDetents([.medium])
        }
        .sheet(item: $itemToEdit) { item in
            WorkoutLogEditSheet(memberName: memberName, item: item) { updatedDuration in
                withAnimation {
                    if let index = programContext.memberRecent.firstIndex(where: { $0.id == item.id }) {
                        programContext.memberRecent[index] = APIClient.MemberRecentWorkoutsResponse.Item(
                            id: item.id,
                            workoutType: item.workoutType,
                            workoutDate: item.workoutDate,
                            durationMinutes: updatedDuration
                        )
                    }
                }
                editSuccessMessage = "\"\(item.workoutType)\" updated."
                showEditSuccessAlert = true
            }
            .environmentObject(programContext)
        }
        .alert("Delete Workout", isPresented: $showDeleteAlert, presenting: itemToDelete) { item in
            Button("Delete", role: .destructive) {
                Task { await deleteWorkout(item) }
            }
            Button("Cancel", role: .cancel) { }
        } message: { item in
            Text("Are you sure you want to delete this \(item.workoutType) workout from \(item.workoutDate)?")
        }
        .alert("Delete Failed", isPresented: $showDeleteErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteErrorMessage ?? "Unable to delete workout.")
        }
        .alert("Deleted", isPresented: $showDeleteSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteSuccessMessage ?? "Workout deleted.")
        }
        .alert("Saved", isPresented: $showEditSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(editSuccessMessage ?? "Workout updated.")
        }
        .task { await loadWorkouts() }
        .onChange(of: sortField) { _, _ in Task { await loadWorkouts() } }
        .onChange(of: sortDirection) { _, _ in Task { await loadWorkouts() } }
        .onChange(of: filters) { _, _ in Task { await loadWorkouts() } }
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
                    .background(filters.isActive ? Color.appOrangeLight : Color(.systemGray6))
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
                    if let name = filters.workoutTypeName, !name.isEmpty {
                        Text("·")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                        Text(name)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                    }
                    if let minD = filters.minDurationMinutes {
                        Text("·")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                        Text("At least \(formatDuration(minD))")
                            .font(.caption.weight(.medium))
                    }
                    if let maxD = filters.maxDurationMinutes {
                        Text("·")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                        Text("At most \(formatDuration(maxD))")
                            .font(.caption.weight(.medium))
                    }
                    Spacer()
                    Button {
                        filters = WorkoutFilters()
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
            } else if programContext.memberRecent.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No workouts found.")
                        .font(.subheadline.weight(.semibold))
                    Text("Adjust filters or log a workout to get started.")
                        .font(.footnote)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            } else {
                List {
                    ForEach(programContext.memberRecent) { item in
                        workoutRow(item)
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
    
    private func workoutRow(_ item: APIClient.MemberRecentWorkoutsResponse.Item) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.appOrangeLight)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.workoutType)
                    .font(.subheadline.weight(.semibold))
                Text(item.workoutDate)
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
            }
            Spacer()
            Text(formatDuration(item.durationMinutes))
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func loadWorkouts() async {
        guard !isLoading else { return }
        guard let mId = memberId else { return }
        isLoading = true
        await programContext.loadMemberRecent(
            memberId: mId,
            limit: 0,
            startDate: filters.startDateString(),
            endDate: filters.endDateString(),
            sortBy: sortField.apiValue,
            sortDir: sortDirection.apiValue,
            workoutType: filters.workoutTypeName,
            minDuration: filters.minDurationMinutes,
            maxDuration: filters.maxDurationMinutes
        )
        isLoading = false
    }
    
    @MainActor
    private func deleteWorkout(_ item: APIClient.MemberRecentWorkoutsResponse.Item) async {
        guard let mId = memberId else { return }
        do {
            try await programContext.deleteWorkoutLog(
                memberId: mId,
                workoutName: item.workoutType,
                date: item.workoutDate
            )
            withAnimation {
                programContext.memberRecent.removeAll { $0.id == item.id }
            }
            itemToDelete = nil
            deleteErrorMessage = nil
            deleteSuccessMessage = "\"\(item.workoutType)\" deleted."
            showDeleteSuccessAlert = true
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteErrorAlert = true
        }
    }

    private func exportCSV() async {
        guard !programContext.memberRecent.isEmpty else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        let startLabel = filters.startDate.flatMap { formatter.string(from: $0) } ?? "all"
        let endLabel = filters.endDate.flatMap { formatter.string(from: $0) } ?? "today"
        let exportMemberName = (memberName ?? "Member").replacingOccurrences(of: " ", with: "")
        let fileName = "Workouts_\(exportMemberName)_\(startLabel)_to_\(endLabel).csv"

        var csv = "Workout Type,Date,Duration (min)\n"
        for w in programContext.memberRecent {
            let line = "\"\(w.workoutType.replacingOccurrences(of: "\"", with: "\"\""))\",\(w.workoutDate),\(w.durationMinutes)\n"
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

// MARK: - Workout Sort Sheet
struct WorkoutSortSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sortField: WorkoutSortField
    @Binding var sortDirection: WorkoutSortDirection
    
    var body: some View {
        NavigationView {
            List {
                Section("Sort By") {
                    ForEach(WorkoutSortField.allCases, id: \.self) { field in
                        Button {
                            sortField = field
                        } label: {
                            HStack {
                                Text(field.label)
                                    .foregroundColor(Color(.label))
                                Spacer()
                                if sortField == field {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.appOrange)
                                }
                            }
                        }
                    }
                }
                
                Section("Direction") {
                    ForEach(WorkoutSortDirection.allCases, id: \.self) { direction in
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
                                        .foregroundColor(.appOrange)
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

// MARK: - Workout Filter Sheet
struct WorkoutFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var programContext: ProgramContext
    @Binding var filters: WorkoutFilters
    @State private var localStartDate: Date = Date()
    @State private var localEndDate: Date = Date()
    @State private var useStartDate: Bool = false
    @State private var useEndDate: Bool = false
    @State private var localWorkoutTypeName: String? = nil
    @State private var localMinDurationHours: String = ""
    @State private var localMinDurationMinutes: String = ""
    @State private var localMaxDurationHours: String = ""
    @State private var localMaxDurationMinutes: String = ""
    @State private var showWorkoutTypePicker: Bool = false
    
    private var workoutTypeOptions: [SearchablePickerSheet.PickerOption] {
        let names = programContext.programWorkouts
            .filter { !$0.is_hidden }
            .map { $0.workout_name }
        return [SearchablePickerSheet.PickerOption(id: "", label: "Any")]
            + names.map { SearchablePickerSheet.PickerOption(id: $0, label: $0) }
    }
    
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
                
                Section("Workout Type") {
                    Button {
                        showWorkoutTypePicker = true
                    } label: {
                        HStack {
                            Text(localWorkoutTypeName ?? "Any")
                                .foregroundColor(localWorkoutTypeName == nil ? Color(.tertiaryLabel) : Color(.label))
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }
                }
                
                Section("Duration") {
                    HStack {
                        Text("Min duration")
                            .frame(width: 100, alignment: .leading)
                        TextField("0", text: $localMinDurationHours)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                        Text("hr")
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                        TextField("0", text: $localMinDurationMinutes)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                        Text("min")
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    HStack {
                        Text("Max duration")
                            .frame(width: 100, alignment: .leading)
                        TextField("0", text: $localMaxDurationHours)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                        Text("hr")
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                        TextField("0", text: $localMaxDurationMinutes)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                        Text("min")
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
                
                if filters.isActive {
                    Section {
                        Button("Clear All Filters", role: .destructive) {
                            filters = WorkoutFilters()
                            useStartDate = false
                            useEndDate = false
                            localWorkoutTypeName = nil
                            localMinDurationHours = ""
                            localMinDurationMinutes = ""
                            localMaxDurationHours = ""
                            localMaxDurationMinutes = ""
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
                localWorkoutTypeName = filters.workoutTypeName
                if let minD = filters.minDurationMinutes {
                    localMinDurationHours = "\(minD / 60)"
                    localMinDurationMinutes = "\(minD % 60)"
                }
                if let maxD = filters.maxDurationMinutes {
                    localMaxDurationHours = "\(maxD / 60)"
                    localMaxDurationMinutes = "\(maxD % 60)"
                }
            }
            .sheet(isPresented: $showWorkoutTypePicker) {
                SearchablePickerSheet(
                    title: "Workout Type",
                    options: workoutTypeOptions,
                    selectedId: localWorkoutTypeName ?? "",
                    onSelect: { option in
                        localWorkoutTypeName = option.id.isEmpty ? nil : option.label
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .task {
                if programContext.programWorkouts.isEmpty, programContext.programId != nil {
                    await programContext.loadProgramWorkouts()
                }
            }
        }
    }
    
    private func applyFilters() {
        filters.startDate = useStartDate ? localStartDate : nil
        filters.endDate = useEndDate ? localEndDate : nil
        filters.workoutTypeName = localWorkoutTypeName
        let minTotal = (Int(localMinDurationHours) ?? 0) * 60 + (Int(localMinDurationMinutes) ?? 0)
        let maxTotal = (Int(localMaxDurationHours) ?? 0) * 60 + (Int(localMaxDurationMinutes) ?? 0)
        filters.minDurationMinutes = minTotal > 0 ? minTotal : nil
        filters.maxDurationMinutes = maxTotal > 0 ? maxTotal : nil
    }
}
