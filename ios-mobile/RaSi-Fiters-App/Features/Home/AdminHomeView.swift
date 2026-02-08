private struct MemberHistoryCard: View {
    @EnvironmentObject var programContext: ProgramContext
    let selectedMember: APIClient.MemberDTO?

    private var memberId: String? {
        selectedMember?.id ?? programContext.selectedMemberOverview?.member_id
    }

    private var memberPoints: [APIClient.ActivityTimelinePoint] {
        memberTimelinePoints(from: programContext.memberHistory)
    }

    var body: some View {
        let capturedMemberId = memberId  // Capture value directly
        return NavigationLink {
            ActivityTimelineDetailView(
                initialPeriod: .week,
                memberId: capturedMemberId,
                showActiveSeries: false
            )
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            ActivityTimelineCardSummary(points: memberPoints, showActive: false)
        }
    }
}

private struct MemberStreakCard: View {
    @EnvironmentObject var programContext: ProgramContext
    let selectedMember: APIClient.MemberDTO?

    private var streaks: APIClient.MemberStreaksResponse? { programContext.memberStreaks }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Streak Stats")
                        .font(.headline.weight(.semibold))
                    Text("Current and longest")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                Spacer()
                NavigationLink {
                    MemberStreakDetail()
                        .environmentObject(programContext)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            HStack(spacing: 12) {
                streakTile(title: "Current", value: streaks?.currentStreakDays ?? 0, icon: "flame.fill", color: .appOrange)
                streakTile(title: "Longest", value: streaks?.longestStreakDays ?? 0, icon: "trophy.fill", color: .appYellow)
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

    private func streakTile(title: String, value: Int, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.subheadline.weight(.bold))
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Color(.secondaryLabel))
            }
            Text("\(value) days")
                .font(.title3.weight(.bold))
                .foregroundColor(Color(.label))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

private struct MemberRecentCard: View {
    @EnvironmentObject var programContext: ProgramContext
    let selectedMember: APIClient.MemberDTO?
    
    private var memberId: String? {
        selectedMember?.id ?? programContext.loggedInUserId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("View Workouts")
                        .font(.headline.weight(.semibold))
                    Text("All workouts")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                Spacer()
                NavigationLink {
                    MemberRecentDetail(memberId: memberId, memberName: selectedMember?.member_name ?? programContext.loggedInUserName)
                        .environmentObject(programContext)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            if programContext.memberRecent.isEmpty {
                Text("No workouts logged yet.")
                    .font(.footnote)
                    .foregroundColor(Color(.secondaryLabel))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 8) {
                    ForEach(programContext.memberRecent.prefix(3)) { item in
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
                            Text("\(item.durationMinutes) min")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }
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
}

private struct MemberHealthCard: View {
    @EnvironmentObject var programContext: ProgramContext
    let selectedMember: APIClient.MemberDTO?

    private var memberId: String? {
        selectedMember?.id ?? programContext.loggedInUserId
    }

    private var memberName: String? {
        selectedMember?.member_name ?? programContext.loggedInUserName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("View Health")
                        .font(.headline.weight(.semibold))
                    Text("Daily health logs")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                Spacer()
                NavigationLink {
                    MemberHealthDetail(memberId: memberId, memberName: memberName)
                        .environmentObject(programContext)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            if programContext.memberHealthLogs.isEmpty {
                Text("No daily health logs yet.")
                    .font(.footnote)
                    .foregroundColor(Color(.secondaryLabel))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 8) {
                    ForEach(programContext.memberHealthLogs.prefix(3)) { item in
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
                    }
                }
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

    private func sleepLabel(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f hrs", value)
    }

    private func foodLabel(_ value: Int?) -> String {
        guard let value else { return "—" }
        return "\(value)/5"
    }
}

// MARK: - Detail Views

private struct MemberStreakDetail: View {
    @EnvironmentObject var programContext: ProgramContext

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let s = programContext.memberStreaks {
                HStack(spacing: 12) {
                    streakTile(title: "Current", value: s.currentStreakDays, icon: "flame.fill", color: .appOrange)
                    streakTile(title: "Longest", value: s.longestStreakDays, icon: "trophy.fill", color: .appYellow)
                }

                Text("Milestones")
                    .font(.headline.weight(.semibold))
                WrapChips(items: s.milestones.map { ($0.dayValue, $0.achieved) })
            } else {
                Text("No streak data.")
                    .font(.footnote)
                    .foregroundColor(Color(.secondaryLabel))
            }
            Spacer()
        }
        .padding(16)
        .navigationTitle("Streak Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func streakTile(title: String, value: Int, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.subheadline.weight(.bold))
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Color(.secondaryLabel))
            }
            Text("\(value) days")
                .font(.title2.weight(.bold))
                .foregroundColor(Color(.label))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

private struct WrapChips: View {
    let items: [(Int, Bool)]
    let spacing: CGFloat = 8
    let runSpacing: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            self.generateContent(in: geo)
        }
        .frame(minHeight: 10)
    }

    private func generateContent(in geo: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                chip(item: item)
                    .padding(.trailing, spacing)
                    .padding(.bottom, runSpacing)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > geo.size.width) {
                            width = 0
                            height -= d.height + runSpacing
                        }
                        let result = width
                        if item == items.last! {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        let result = height
                        if item == items.last! {
                            height = 0
                        }
                        return result
                    })
            }
        }
    }

    private func chip(item: (Int, Bool)) -> some View {
        let achieved = item.1
        return Text("\(item.0)d")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(achieved ? Color.appOrangeLight : Color(.systemGray5))
            .foregroundColor(achieved ? .orange : Color(.secondaryLabel))
            .cornerRadius(10)
    }
}

// MARK: - View Workouts Sort Field Enum
private enum WorkoutSortField: String, CaseIterable {
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
private enum WorkoutSortDirection: String, CaseIterable {
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
private struct WorkoutFilters: Equatable {
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

private struct MemberRecentDetail: View {
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
        .onChange(of: sortField) { _ in Task { await loadWorkouts() } }
        .onChange(of: sortDirection) { _ in Task { await loadWorkouts() } }
        .onChange(of: filters) { _ in Task { await loadWorkouts() } }
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
            Text("\(item.durationMinutes) min")
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
            sortDir: sortDirection.apiValue
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
private struct WorkoutSortSheet: View {
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
private struct WorkoutFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: WorkoutFilters
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
                            filters = WorkoutFilters()
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

// MARK: - View Health Sort Field Enum
private enum HealthSortField: String, CaseIterable {
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
private enum HealthSortDirection: String, CaseIterable {
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
private struct HealthFilters: Equatable {
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

private struct MemberHealthDetail: View {
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
        .onChange(of: sortField) { _ in Task { await loadHealthLogs() } }
        .onChange(of: sortDirection) { _ in Task { await loadHealthLogs() } }
        .onChange(of: filters) { _ in Task { await loadHealthLogs() } }
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
private struct HealthSortSheet: View {
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
private struct HealthFilterSheet: View {
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

private struct DailyHealthEditSheet: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.dismiss) private var dismiss
    let memberId: String
    let item: APIClient.MemberHealthLogResponse.Item
    let onSaved: () -> Void

    @State private var sleepHoursText: String
    @State private var foodQuality: Int?
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    init(memberId: String, item: APIClient.MemberHealthLogResponse.Item, onSaved: @escaping () -> Void) {
        self.memberId = memberId
        self.item = item
        self.onSaved = onSaved
        _sleepHoursText = State(initialValue: item.sleepHours.map { String(format: "%.1f", $0) } ?? "")
        _foodQuality = State(initialValue: item.foodQuality)
    }

    private var trimmedSleepText: String {
        sleepHoursText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var sleepValue: Double? {
        guard !trimmedSleepText.isEmpty else { return nil }
        return Double(trimmedSleepText)
    }

    private var isSleepValid: Bool {
        guard !trimmedSleepText.isEmpty else { return true }
        guard let sleepValue else { return false }
        return sleepValue >= 0 && sleepValue <= 24
    }

    private var hasAtLeastOneMetric: Bool {
        (sleepValue != nil && !trimmedSleepText.isEmpty) || foodQuality != nil
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
                    Text("Sleep hours")
                        .font(.subheadline.weight(.semibold))
                    TextField("e.g. 7.5", text: $sleepHoursText)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    if !isSleepValid {
                        Text("Sleep hours must be between 0 and 24.")
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
}

private struct WorkoutLogEditSheet: View {
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

import SwiftUI
import UniformTypeIdentifiers
import Charts

struct AdminHomeView: View {
    enum Tab {
        case summary
        case members
        case workoutTypes
        case program
    }

    enum Period: String, CaseIterable {
        case week = "W"
        case month = "M"
        case year = "Y"
        case program = "P"

        var label: String { rawValue }

        var apiValue: String {
            switch self {
            case .week: return "week"
            case .month: return "month"
            case .year: return "year"
            case .program: return "program"
            }
        }
    }

    @EnvironmentObject var programContext: ProgramContext
    @State private var selectedTab: Tab = .summary
    @State private var summaryPeriod: Period = .week

    var body: some View {
        TabView(selection: $selectedTab) {
            AdminSummaryTab(period: $summaryPeriod)
                .tabItem {
                    Label("Summary", systemImage: "chart.bar.fill")
                }
                .tag(Tab.summary)

            membersTab
                .tabItem {
                    Label("Members", systemImage: "person.3.fill")
                }
                .tag(Tab.members)

            workoutTypesTab
                .tabItem {
                    Label("Lifestyle", systemImage: "leaf.fill")
                }
                .tag(Tab.workoutTypes)

            programTab
                .tabItem {
                    Label("Program", systemImage: "calendar.badge.clock")
                }
                .tag(Tab.program)
        }
        .adaptiveTint()
        .navigationBarBackButtonHidden(true)
    }

    @ViewBuilder
    private var membersTab: some View {
        if programContext.isProgramAdmin {
            AdminMembersTab()
        } else {
            StandardMembersTab()
        }
    }

    @ViewBuilder
    private var workoutTypesTab: some View {
        if programContext.isProgramAdmin {
            AdminWorkoutTypesTab()
        } else {
            StandardWorkoutTypesTab()
        }
    }

    @ViewBuilder
    private var programTab: some View {
        if programContext.isProgramAdmin {
            AdminProgramTab()
        } else {
            StandardProgramTab()
        }
    }
}

// MARK: - Summary

private struct AdminSummaryTab: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.colorScheme) private var colorScheme
    @Binding var period: AdminHomeView.Period
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var cardOrder: [SummaryCardType] = SummaryCardType.defaultOrder
    @State private var draggingCard: SummaryCardType?
    @State private var timelinePeriod: AdminHomeView.Period = .week
    private let rowSpacing: CGFloat = 12

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    SummaryHeader(
                        title: "Summary",
                        subtitle: programContext.name,
                        status: programContext.status,
                        initials: programContext.adminInitials
                    )

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.appRed)
                            .padding(.horizontal, 4)
                    }

                    VStack(spacing: rowSpacing) {
                        ForEach(Array(laidOutRows().enumerated()), id: \.offset) { _, row in
                            HStack(spacing: 14) {
                                ForEach(row, id: \.self) { card in
                                    cardView(for: card)
                                        .frame(maxWidth: .infinity)
                                        .onDrag {
                                            draggingCard = card
                                            return NSItemProvider(object: card.rawValue as NSString)
                                        }
                                        .onDrop(
                                            of: [UTType.text],
                                            delegate: CardDropDelegate(
                                                item: card,
                                                items: $cardOrder,
                                                dragging: $draggingCard,
                                                onReorder: persistOrder
                                            )
                                        )
                                }
                                if row.count == 1 && !(row.first?.requiresFullWidth ?? false) {
                                    Color.clear.frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
        }
        .task {
            await load()
            restoreOrder()
        }
        .onChange(of: period) { _ in
            Task { await load() }
        }
        .onChange(of: programContext.programId) { _ in
            restoreOrder()
            Task { await programContext.loadLookupData() }
        }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        await programContext.loadAnalytics(period: period.apiValue)
        await programContext.loadMTDParticipation()
        await programContext.loadTotalWorkoutsMTD()
        await programContext.loadTotalDurationMTD()
        await programContext.loadAvgDurationMTD()
        await programContext.loadActivityTimeline(period: timelinePeriod.apiValue)
        await programContext.loadDistributionByDay()
        await programContext.loadWorkoutTypes()
        errorMessage = programContext.errorMessage
        isLoading = false
    }

    /// Arrange cards into rows honoring full-width cards and packing half-width cards two per row.
    private func laidOutRows() -> [[SummaryCardType]] {
        var rows: [[SummaryCardType]] = []
        var currentRow: [SummaryCardType] = []

        for card in cardOrder {
            if card.requiresFullWidth {
                if !currentRow.isEmpty {
                    rows.append(currentRow)
                    currentRow.removeAll()
                }
                rows.append([card])
            } else {
                currentRow.append(card)
                if currentRow.count == 2 {
                    rows.append(currentRow)
                    currentRow.removeAll()
                }
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    @ViewBuilder
    private func cardView(for card: SummaryCardType) -> some View {
        switch card {
        case .addWorkout:
            NavigationLink {
                AddWorkoutDetailView()
            } label: {
                AddWorkoutCard()
                    .frame(maxWidth: .infinity)
            }
        case .addDailyHealth:
            NavigationLink {
                AddDailyHealthDetailView()
            } label: {
                AddDailyHealthCard()
                    .frame(maxWidth: .infinity)
            }
        case .programProgress:
            ProgramProgressCard(
                progress: programContext.completionPercent,
                elapsedDays: programContext.elapsedDays,
                totalDays: programContext.totalDays,
                remainingDays: programContext.remainingDays,
                status: programContext.status
            )
            .frame(maxWidth: .infinity)
        case .mtdParticipation:
            if let mtd = programContext.mtdParticipation {
                MTDParticipationCard(
                    active: mtd.active_members,
                    total: mtd.total_members,
                    pct: mtd.participation_pct,
                    change: mtd.change_pct
                )
            } else {
                PlaceholderCard(title: "MTD Participation")
            }
        case .totalWorkouts:
            TotalWorkoutsCard(
                total: programContext.totalWorkoutsMTD,
                change: programContext.totalWorkoutsChangePct
            )
        case .totalDuration:
            TotalDurationCard(
                hours: programContext.totalDurationHoursMTD,
                change: programContext.totalDurationChangePct
            )
        case .avgDuration:
            AvgDurationCard(
                minutes: programContext.avgDurationMinutesMTD,
                change: programContext.avgDurationChangePctMTD
            )
        case .activityTimeline:
            NavigationLink {
                ActivityTimelineDetailView(initialPeriod: timelinePeriod)
            } label: {
                ActivityTimelineCardSummary(
                    points: programContext.activityTimeline
                )
            }
        case .distributionByDay:
            NavigationLink {
                DistributionByDayDetailView(
                    points: distributionPoints(fromCounts: programContext.distributionByDayCounts)
                )
            } label: {
                DistributionByDayCard(
                    points: distributionPoints(fromCounts: programContext.distributionByDayCounts),
                    interactive: false
                )
            }
        case .workoutTypes:
            NavigationLink {
                WorkoutTypesDetailView(
                    types: programContext.workoutTypes
                )
            } label: {
                WorkoutTypesSummaryCard(
                    types: programContext.workoutTypes
                )
            }
        }
    }

    private func persistOrder() {
        let key = "summary.card.order.\(programContext.programId ?? "default")"
        let raw = cardOrder.map { $0.rawValue }
        UserDefaults.standard.set(raw, forKey: key)
    }

    private func restoreOrder() {
        let key = "summary.card.order.\(programContext.programId ?? "default")"
        if let saved = UserDefaults.standard.stringArray(forKey: key) {
            let savedTypes = saved.compactMap { SummaryCardType(rawValue: $0) }
            let missing = SummaryCardType.defaultOrder.filter { !savedTypes.contains($0) }
            var merged = savedTypes + missing
            if let dailyIndex = merged.firstIndex(of: .addDailyHealth),
               let workoutIndex = merged.firstIndex(of: .addWorkout),
               dailyIndex != workoutIndex + 1 {
                let item = merged.remove(at: dailyIndex)
                let insertIndex = min(workoutIndex + 1, merged.count)
                merged.insert(item, at: insertIndex)
            }
            cardOrder = merged
        } else {
            cardOrder = SummaryCardType.defaultOrder
        }
    }
}

// MARK: - Other Tabs

private struct AdminMembersTab: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var showMemberPicker = false
    @State private var selectedMember: APIClient.MemberDTO?
    private var canViewAs: Bool { programContext.isProgramAdmin }

    private var viewAsLabel: String {
        if let selectedMember {
            return selectedMember.member_name
        }
        if programContext.isGlobalAdmin {
            return "None"
        }
        return programContext.loggedInUserName ?? "Member"
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Members")
                                .font(.largeTitle.weight(.bold))
                                .foregroundColor(Color(.label))
                            Text(programContext.name)
                                .font(.headline.weight(.semibold))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        Spacer()
                        NavigationLink {
                            InviteMemberView()
                        } label: {
                            GlassButton(icon: "envelope.badge.person.crop")
                        }
                    }
                    .padding(.top, 24)

                    NavigationLink {
                        MemberMetricsDetailView()
                    } label: {
                        MemberMetricsPreviewCard()
                    }
                    .buttonStyle(.plain)

                    if canViewAs {
                        viewAsSelector
                        if selectedMember != nil {
                            MemberOverviewCard(member: selectedMember)
                            MemberHistoryCard(selectedMember: selectedMember)
                            MemberStreakCard(selectedMember: selectedMember)
                            MemberRecentCard(selectedMember: selectedMember)
                            MemberHealthCard(selectedMember: selectedMember)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .adaptiveBackground(topLeading: true)
            .navigationBarBackButtonHidden(true)
        }
        .task {
            applyDefaultSelectionIfNeeded()
        }
        .onChange(of: programContext.programId) { _ in
            if !programContext.isGlobalAdmin {
                selectedMember = nil
            }
            applyDefaultSelectionIfNeeded()
        }
        .onChange(of: programContext.members.count) { _ in
            applyDefaultSelectionIfNeeded()
        }
        .onChange(of: programContext.loggedInUserId) { _ in
            if !programContext.isGlobalAdmin {
                selectedMember = nil
            }
            applyDefaultSelectionIfNeeded()
        }
    }

    private var viewAsSelector: some View {
        Button {
            showMemberPicker = true
        } label: {
            HStack {
                Text("View as")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(.label))
                Spacer()
                Text(viewAsLabel)
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.bold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showMemberPicker) {
            MemberPickerView(
                members: programContext.members,
                selected: selectedMember,
                showNoneOption: programContext.isGlobalAdmin,
                onSelect: { member in
                    applySelection(member)
                }
            )
        }
    }

    private func applySelection(_ member: APIClient.MemberDTO?) {
        selectedMember = member
        showMemberPicker = false
        Task {
            await loadMemberData(for: member)
        }
    }

    @MainActor
    private func loadMemberData(for member: APIClient.MemberDTO?) async {
        if let m = member {
            await programContext.loadMemberOverview(memberId: m.id)
            await programContext.loadMemberHistory(memberId: m.id, period: "week")
            await programContext.loadMemberStreaks(memberId: m.id)
            await programContext.loadMemberRecent(memberId: m.id, limit: 10)
            await programContext.loadMemberHealthLogs(memberId: m.id, limit: 10)
        } else {
            programContext.selectedMemberOverview = nil
            programContext.memberHistory = []
            programContext.memberStreaks = nil
            programContext.memberRecent = []
            programContext.memberHealthLogs = []
        }
    }

    private func applyDefaultSelectionIfNeeded() {
        guard !programContext.isGlobalAdmin else { return }
        guard selectedMember == nil else { return }
        guard let userId = programContext.loggedInUserId else { return }
        guard programContext.membersProgramId == programContext.programId else { return }
        guard let member = programContext.members.first(where: { $0.id == userId }) else { return }
        applySelection(member)
    }
}

// MARK: - Standard Members Tab (for non-admin users)

private struct StandardMembersTab: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var loggedInUserMetrics: APIClient.MemberMetricsDTO?

    private var loggedInMember: APIClient.MemberDTO? {
        guard let userId = programContext.loggedInUserId else { return nil }
        return programContext.members.first { $0.id == userId }
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header with View Members button
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Members")
                                .font(.largeTitle.weight(.bold))
                                .foregroundColor(Color(.label))
                            Text(programContext.name)
                                .font(.headline.weight(.semibold))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        Spacer()
                        // View Members button
                        NavigationLink {
                            ProgramMembersListView()
                        } label: {
                            GlassButton(icon: "person.2")
                        }
                    }
                    .padding(.top, 24)

                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.appRed)
                            .padding(.horizontal, 4)
                    } else {
                        // Member Overview card first
                        if programContext.selectedMemberOverview != nil {
                            MemberOverviewCard(member: loggedInMember)
                        }

                        // Logged-in user's MemberMetricsCard second
                        if let metrics = loggedInUserMetrics {
                            MemberMetricsCard(metric: metrics, hero: .workouts)
                        }

                        // Remaining member detail cards
                        if programContext.selectedMemberOverview != nil {
                            MemberHistoryCard(selectedMember: loggedInMember)
                            MemberStreakCard(selectedMember: loggedInMember)
                            MemberRecentCard(selectedMember: loggedInMember)
                            MemberHealthCard(selectedMember: loggedInMember)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .adaptiveBackground(topLeading: true)
            .navigationBarBackButtonHidden(true)
        }
        .task {
            await loadUserData()
        }
        .onChange(of: programContext.programId) { _ in
            Task {
                await loadUserData()
            }
        }
    }

    private func loadUserData() async {
        guard let userId = programContext.loggedInUserId else {
            errorMessage = "Unable to identify logged-in user."
            return
        }

        isLoading = true
        errorMessage = nil

        // Load member metrics for the logged-in user
        await programContext.loadMemberMetrics(
            search: "",
            sort: "workouts",
            direction: "desc",
            filters: [:],
            dateRange: (nil, nil)
        )

        // Find the logged-in user's metrics from the loaded data
        loggedInUserMetrics = programContext.memberMetrics.first { $0.member_id == userId }

        // Load detailed data for the logged-in user
        await programContext.loadMemberOverview(memberId: userId)
        await programContext.loadMemberHistory(memberId: userId, period: "week")
        await programContext.loadMemberStreaks(memberId: userId)
        await programContext.loadMemberRecent(memberId: userId, limit: 10)
        await programContext.loadMemberHealthLogs(memberId: userId, limit: 10)

        isLoading = false
    }
}

// MARK: - Standard Workout Types Tab (for non-admin users)

private struct StandardWorkoutTypesTab: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.appBackground
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Header with View Workouts button
                            HStack(alignment: .center, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Lifestyle")
                                    .font(.largeTitle.weight(.bold))
                                    .foregroundColor(Color(.label))
                                Text(programContext.name)
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(Color(.secondaryLabel))
                            }

                            Spacer()

                            // View Workouts button
                            NavigationLink {
                                ViewWorkoutTypesListView()
                            } label: {
                                GlassButton(icon: "dumbbell")
                            }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.appRed)
                                .padding(.horizontal, 4)
                        }

                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                        } else {
                            // Workout type cards (same layout as admin view)
                            VStack(spacing: 14) {
                                HStack(spacing: 14) {
                                    WorkoutTypesTotalCard(total: programContext.workoutTypesTotal)
                                        .frame(maxWidth: .infinity)
                                    WorkoutTypeMostPopularCard(
                                        name: programContext.workoutTypeMostPopular?.workout_name,
                                        sessions: programContext.workoutTypeMostPopular?.sessions ?? 0
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                                HStack(spacing: 14) {
                                    WorkoutTypeLongestDurationCard(
                                        name: programContext.workoutTypeLongestDuration?.workout_name,
                                        avgMinutes: programContext.workoutTypeLongestDuration?.avg_minutes ?? 0
                                    )
                                    .frame(maxWidth: .infinity)
                                    WorkoutTypeHighestParticipationCard(
                                        name: programContext.workoutTypeHighestParticipation?.workout_name,
                                        participationPct: programContext.workoutTypeHighestParticipation?.participation_pct ?? 0
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                            }

                            WorkoutTypePopularityCard(types: programContext.workoutTypes)

                            NavigationLink {
                                LifestyleTimelineDetailView(
                                    initialPeriod: .week,
                                    memberId: programContext.loggedInUserId
                                )
                            } label: {
                                LifestyleTimelineCardSummary(points: programContext.healthTimeline)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarBackButtonHidden(true)
        }
        .task {
            await loadUserWorkoutTypes()
        }
        .onChange(of: programContext.programId) { _ in
            Task {
                await loadUserWorkoutTypes()
            }
        }
    }

    private func loadUserWorkoutTypes() async {
        guard let userId = programContext.loggedInUserId else {
            errorMessage = "Unable to identify logged-in user."
            return
        }

        isLoading = true
        errorMessage = nil

        // Load workout type data for the logged-in user
        await programContext.loadWorkoutTypesTotal(memberId: userId)
        await programContext.loadWorkoutTypeMostPopular(memberId: userId)
        await programContext.loadWorkoutTypeLongestDuration(memberId: userId)
        await programContext.loadWorkoutTypeHighestParticipation(memberId: nil)  // Always program-wide
        await programContext.loadWorkoutTypes(memberId: userId)
        await programContext.loadHealthTimeline(period: AdminHomeView.Period.week.apiValue, memberId: userId)

        errorMessage = programContext.errorMessage
        isLoading = false
    }
}

private struct AdminWorkoutTypesTab: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showMemberPicker = false
    @State private var selectedMember: APIClient.MemberDTO?
    @State private var hasUserChosenViewAs = false
    private var canViewAs: Bool { programContext.isProgramAdmin }

    private var viewAsLabel: String {
        if let selectedMember {
            return selectedMember.member_name
        }
        if programContext.isGlobalAdmin {
            return "Admin"
        }
        if hasUserChosenViewAs {
            return "Admin"
        }
        return programContext.loggedInUserName ?? "Member"
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    WorkoutTypesHeader(
                        title: "Lifestyle",
                        subtitle: programContext.name
                    )

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.appRed)
                            .padding(.horizontal, 4)
                    }

                    if canViewAs {
                        viewAsSelector
                    }

                    VStack(spacing: 14) {
                        HStack(spacing: 14) {
                            WorkoutTypesTotalCard(total: programContext.workoutTypesTotal)
                                .frame(maxWidth: .infinity)
                            WorkoutTypeMostPopularCard(
                                name: programContext.workoutTypeMostPopular?.workout_name,
                                sessions: programContext.workoutTypeMostPopular?.sessions ?? 0
                            )
                            .frame(maxWidth: .infinity)
                        }
                        HStack(spacing: 14) {
                            WorkoutTypeLongestDurationCard(
                                name: programContext.workoutTypeLongestDuration?.workout_name,
                                avgMinutes: programContext.workoutTypeLongestDuration?.avg_minutes ?? 0
                            )
                            .frame(maxWidth: .infinity)
                            WorkoutTypeHighestParticipationCard(
                                name: programContext.workoutTypeHighestParticipation?.workout_name,
                                participationPct: programContext.workoutTypeHighestParticipation?.participation_pct ?? 0
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }

                    WorkoutTypePopularityCard(types: programContext.workoutTypes)

                    NavigationLink {
                        LifestyleTimelineDetailView(
                            initialPeriod: .week,
                            memberId: selectedMember?.id
                        )
                    } label: {
                        LifestyleTimelineCardSummary(points: programContext.healthTimeline)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
        }
        .task {
            await programContext.loadLookupData()
            applyDefaultSelectionIfNeeded()
            if selectedMember == nil {
                await load()
            }
        }
        .onChange(of: programContext.programId) { _ in
            Task {
                if !programContext.isGlobalAdmin {
                    selectedMember = nil
                    hasUserChosenViewAs = false
                }
                await programContext.loadLookupData()
                applyDefaultSelectionIfNeeded()
                if selectedMember == nil {
                    await load()
                }
            }
        }
        .onChange(of: selectedMember?.id) { _ in
            Task { await load() }
        }
        .onChange(of: programContext.members.count) { _ in
            applyDefaultSelectionIfNeeded()
        }
        .onChange(of: programContext.loggedInUserId) { _ in
            if !programContext.isGlobalAdmin {
                selectedMember = nil
                hasUserChosenViewAs = false
            }
            applyDefaultSelectionIfNeeded()
        }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        let memberId = selectedMember?.id
        await programContext.loadWorkoutTypesTotal(memberId: memberId)
        await programContext.loadWorkoutTypeMostPopular(memberId: memberId)
        await programContext.loadWorkoutTypeLongestDuration(memberId: memberId)
        await programContext.loadWorkoutTypeHighestParticipation(memberId: nil)  // Always program-wide
        await programContext.loadWorkoutTypes(memberId: memberId)
        await programContext.loadHealthTimeline(period: AdminHomeView.Period.week.apiValue, memberId: memberId)
        errorMessage = programContext.errorMessage
        isLoading = false
    }

    private var viewAsSelector: some View {
        Button {
            showMemberPicker = true
        } label: {
            HStack {
                Text("View as")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(.label))
                Spacer()
                Text(viewAsLabel)
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.bold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showMemberPicker) {
            MemberPickerView(
                members: programContext.members,
                selected: selectedMember,
                showNoneOption: true,
                noneLabel: programContext.isGlobalAdmin ? "None" : "Admin",
                onSelect: { member in
                    hasUserChosenViewAs = true
                    selectedMember = member
                    showMemberPicker = false
                }
            )
        }
    }

    private func applyDefaultSelectionIfNeeded() {
        guard !programContext.isGlobalAdmin else { return }
        guard !hasUserChosenViewAs else { return }
        guard selectedMember == nil else { return }
        guard let userId = programContext.loggedInUserId else { return }
        guard programContext.membersProgramId == programContext.programId else { return }
        guard let member = programContext.members.first(where: { $0.id == userId }) else { return }
        selectedMember = member
    }
}

private struct AdminProgramTab: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var showSelectProgram = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    SummaryHeader(
                        title: "Program",
                        subtitle: programContext.name,
                        status: programContext.status,
                        initials: programContext.adminInitials
                    )

                    VStack(spacing: 16) {
                        // Program Info Section - everyone sees Select Program, only admins see Edit
                        ProgramInfoSection(showSelectProgram: $showSelectProgram)

                        // Member Management Section - everyone can view list
                        ProgramMemberManagementSection()

                        // Role Management Section - only global_admin and program_admin
                        if programContext.canEditProgramData {
                            ProgramRoleManagementSection()
                        }

                        // Workout Types Section - everyone can view, permissions vary
                        ProgramWorkoutTypesSection()

                        // My Account Section (always visible)
                        ProgramMyAccountSection()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
        }
        .navigationDestination(isPresented: $showSelectProgram) {
            ProgramPickerView()
                .navigationBarBackButtonHidden(true)
        }
        .task {
            await programContext.loadMembershipDetails()
        }
    }
}

// MARK: - Program Info Section

private struct ProgramInfoSection: View {
    @EnvironmentObject var programContext: ProgramContext
    @Binding var showSelectProgram: Bool
    @State private var showLeaveProgramConfirm = false
    @State private var isLeavingProgram = false
    @State private var leaveProgramError: String?

    private var canLeaveProgram: Bool {
        programContext.loggedInUserProgramRole != "admin" && !programContext.isGlobalAdmin
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Program Info", icon: "info.circle.fill", color: .blue)

            VStack(spacing: 12) {
                // Select Program Button
                Button {
                    showSelectProgram = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.appOrangeVeryLight)
                                .frame(width: 42, height: 42)
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.appOrange)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Select Program")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color(.label))
                            Text("Switch to a different program")
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
                .buttonStyle(.plain)

                // Edit Program Info (only if admin)
                if programContext.canEditProgramData {
                    NavigationLink {
                        EditProgramInfoView()
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.appBlueLight)
                                    .frame(width: 42, height: 42)
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Edit Program Details")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Color(.label))
                                Text("\(programContext.status) • \(programContext.dateRangeLabel)")
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
                    .buttonStyle(.plain)
                }

                if canLeaveProgram {
                    // Leave Program
                    Button {
                        showLeaveProgramConfirm = true
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 42, height: 42)
                                Image(systemName: "arrow.left.circle")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(.secondaryLabel))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Leave Program")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Color(.label))
                                Text("Your data will be preserved")
                                    .font(.caption)
                                    .foregroundColor(Color(.secondaryLabel))
                            }
                            Spacer()
                            if isLeavingProgram {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
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
                    .buttonStyle(.plain)
                    .disabled(isLeavingProgram)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
        )
        .adaptiveShadow(radius: 8, y: 4)
        .alert("Leave Program?", isPresented: $showLeaveProgramConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                Task { await leaveProgram() }
            }
        } message: {
            Text("You will no longer have access to \(programContext.name). Your workout history and data will be preserved. If you're invited back and accept, your data will be restored.")
        }
        .alert("Error", isPresented: .constant(leaveProgramError != nil)) {
            Button("OK") { leaveProgramError = nil }
        } message: {
            Text(leaveProgramError ?? "")
        }
    }

    private func leaveProgram() async {
        isLeavingProgram = true
        leaveProgramError = nil

        do {
            _ = try await programContext.leaveProgram()
            // Success - UI will update automatically as programId is cleared
        } catch {
            leaveProgramError = error.localizedDescription
        }

        isLeavingProgram = false
    }
}

// MARK: - Member Management Section

private struct ProgramMemberManagementSection: View {
    @EnvironmentObject var programContext: ProgramContext

    // Only global_admin and program_admin can invite members
    private var canInviteMember: Bool {
        programContext.canEditProgramData
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Members", icon: "person.2.fill", color: .green)

            VStack(spacing: 12) {
                // View Members - everyone can see the list
                NavigationLink {
                    ProgramMembersListView()
                } label: {
                    settingsRow(
                        icon: "person.3.fill",
                        color: .green,
                        title: "View Members",
                        subtitle: "\(programContext.members.count) enrolled"
                    )
                }
                .buttonStyle(.plain)

                // Invite Member - only global_admin and program_admin
                if canInviteMember {
                    NavigationLink {
                        InviteMemberView()
                    } label: {
                        settingsRow(
                            icon: "envelope.badge.person.crop",
                            color: .blue,
                            title: "Invite Member",
                            subtitle: "Send program invitation"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
        )
        .adaptiveShadow(radius: 8, y: 4)
    }
}

private struct ProgramMembersListView: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var searchText = ""

    // Only global_admin can view member details
    private var canViewMemberDetails: Bool {
        programContext.isGlobalAdmin
    }

    private var filteredMembers: [APIClient.MembershipDetailDTO] {
        if searchText.isEmpty {
            return programContext.membershipDetails
        }
        return programContext.membershipDetails.filter {
            $0.member_name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredMembers) { member in
                // Only global_admin can tap into member details
                if canViewMemberDetails {
                    NavigationLink {
                        MemberDetailEditView(membership: member)
                    } label: {
                        memberRow(member: member, showChevron: true)
                    }
                } else {
                    memberRow(member: member, showChevron: false)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search members")
        .navigationTitle("Members")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await programContext.loadMembershipDetails()
        }
    }

    private func memberRow(member: APIClient.MembershipDetailDTO, showChevron: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(member.program_role == "admin" ? Color.appOrangeLight : Color(.systemGray5))
                    .frame(width: 44, height: 44)
                Text(initials(for: member.member_name))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(member.program_role == "admin" ? .orange : Color(.label))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(member.member_name)
                        .font(.subheadline.weight(.semibold))
                    if member.program_role == "admin" {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.appOrange)
                    }
                }
                Text(member.username ?? "")
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
            }

            Spacer()

            if !member.is_active {
                Text("Inactive")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.appRed)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appRedLight)
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }

    private func initials(for name: String) -> String {
        name.split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map { String($0).uppercased() }
            .joined()
    }
}

private struct MemberDetailEditView: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.dismiss) private var dismiss
    let membership: APIClient.MembershipDetailDTO

    @State private var joinedAt: Date = Date()
    @State private var isActive: Bool = true
    @State private var isSaving = false
    @State private var showRemoveConfirm = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Member Info Header
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(membership.program_role == "admin" ? Color.appOrangeLight : Color(.systemGray5))
                            .frame(width: 60, height: 60)
                        Text(initials)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(membership.program_role == "admin" ? .orange : Color(.label))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(membership.member_name)
                            .font(.title3.weight(.bold))
                        Text("@\(membership.username ?? "")")
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                        if membership.program_role == "admin" {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                Text("Program Admin")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundColor(.appOrange)
                        }
                    }
                }

                Divider()

                // Member Details
                VStack(alignment: .leading, spacing: 14) {
                    if let gender = membership.gender, !gender.isEmpty {
                        detailRow(label: "Gender", value: gender)
                    }
                    if let dob = membership.date_of_birth {
                        detailRow(label: "Date of Birth", value: dob)
                    }
                    if let joined = membership.date_joined {
                        detailRow(label: "Account Created", value: joined)
                    }
                }

                Divider()

                // Editable Fields
                VStack(alignment: .leading, spacing: 14) {
                    Text("Membership Settings")
                        .font(.headline.weight(.semibold))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Joined Program")
                            .font(.subheadline.weight(.semibold))
                        DatePicker("", selection: $joinedAt, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    Toggle(isOn: $isActive) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Active Membership")
                                .font(.subheadline.weight(.semibold))
                            Text(isActive ? "Member is active in this program" : "Member is inactive")
                                .font(.caption)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                    }
                    .adaptiveTint()
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.appRed)
                        .font(.footnote.weight(.semibold))
                }

                // Save Button
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
                .background(Color.appOrange)
                .foregroundColor(.black)
                .cornerRadius(14)
                .disabled(isSaving)

                // Remove Button
                Button(role: .destructive) {
                    showRemoveConfirm = true
                } label: {
                    Text("Remove from Program")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appRedLight)
                        .foregroundColor(.appRed)
                        .cornerRadius(14)
                }
            }
            .padding(20)
        }
        .adaptiveBackground(topLeading: true)
        .navigationTitle("Member Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let joined = membership.joined_at {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: joined) {
                    joinedAt = date
                }
            }
            isActive = membership.is_active
        }
        .alert("Remove Member?", isPresented: $showRemoveConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                Task { await removeMember() }
            }
        } message: {
            Text("This will remove \(membership.member_name) from the program.")
        }
    }

    private var initials: String {
        membership.member_name
            .split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map { String($0).uppercased() }
            .joined()
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil

        do {
            try await programContext.updateMembership(
                memberId: membership.member_id,
                role: nil,
                isActive: isActive,
                joinedAt: joinedAt
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    private func removeMember() async {
        isSaving = true
        errorMessage = nil

        do {
            try await programContext.removeMember(memberId: membership.member_id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}

// MARK: - Role Management Section

private struct ProgramRoleManagementSection: View {
    @EnvironmentObject var programContext: ProgramContext

    private var admins: [APIClient.MembershipDetailDTO] {
        programContext.membershipDetails.filter { $0.program_role == "admin" }
    }

    private var loggers: [APIClient.MembershipDetailDTO] {
        programContext.membershipDetails.filter { $0.program_role == "logger" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Role Management", icon: "person.badge.key.fill", color: .purple)

            VStack(spacing: 12) {
                // Admins subsection
                if !admins.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.appOrange)
                            Text("Admins")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color(.secondaryLabel))
                        }

                        ForEach(admins) { admin in
                            roleRow(member: admin, color: .appOrange)
                        }
                    }
                }

                // Loggers subsection
                if !loggers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("Loggers")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color(.secondaryLabel))
                        }

                        ForEach(loggers) { logger in
                            roleRow(member: logger, color: .blue)
                        }
                    }
                }

                if admins.isEmpty && loggers.isEmpty {
                    Text("No admins or loggers assigned")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }

                // Manage Roles
                NavigationLink {
                    ManageRolesView()
                } label: {
                    settingsRow(
                        icon: "person.badge.key.fill",
                        color: .purple,
                        title: "Manage Roles",
                        subtitle: "Set admin, logger, or member roles"
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
        )
        .adaptiveShadow(radius: 8, y: 4)
    }

    private func roleRow(member: APIClient.MembershipDetailDTO, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text(initials(for: member.member_name))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(member.member_name)
                    .font(.subheadline.weight(.semibold))
                if member.global_role == "global_admin" {
                    Text("Global Admin")
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }

    private func initials(for name: String) -> String {
        name.split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map { String($0).uppercased() }
            .joined()
    }
}

private struct ManageRolesView: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var isUpdating: String?
    @State private var errorMessage: String?

    private var activeAdminCount: Int {
        programContext.membershipDetails.filter { $0.program_role == "admin" && $0.status == "active" }.count
    }

    var body: some View {
        List {
            ForEach(programContext.membershipDetails) { member in
                let isLastActiveAdmin = member.program_role == "admin"
                    && member.status == "active"
                    && activeAdminCount <= 1

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(roleColor(for: member.program_role).opacity(0.2))
                                .frame(width: 44, height: 44)
                            Text(initials(for: member.member_name))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(roleColor(for: member.program_role))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(member.member_name)
                                .font(.subheadline.weight(.semibold))
                            Text(roleDisplayName(for: member.program_role))
                                .font(.caption)
                                .foregroundColor(Color(.secondaryLabel))
                        }

                        Spacer()
                    }

                    if isUpdating == member.member_id {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    } else {
                        // Role selection buttons
                        HStack(spacing: 8) {
                            roleButton(
                                title: "Admin",
                                isSelected: member.program_role == "admin",
                                color: .appOrange,
                                isDisabled: isLastActiveAdmin
                            ) {
                                Task { await updateRole(for: member, to: "admin") }
                            }

                            roleButton(
                                title: "Logger",
                                isSelected: member.program_role == "logger",
                                color: .blue,
                                isDisabled: isLastActiveAdmin
                            ) {
                                Task { await updateRole(for: member, to: "logger") }
                            }

                            roleButton(
                                title: "Member",
                                isSelected: member.program_role == "member",
                                color: Color(.systemGray),
                                isDisabled: isLastActiveAdmin
                            ) {
                                Task { await updateRole(for: member, to: "member") }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Manage Roles")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await programContext.loadMembershipDetails()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func roleButton(title: String, isSelected: Bool, color: Color, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption2.weight(.bold))
                }
                Text(title)
                    .font(.caption.weight(isSelected ? .bold : .semibold))
            }
            .foregroundColor(isSelected ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? color.opacity(0.8) : color.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .disabled(isSelected || isDisabled)
        .opacity(isSelected || !isDisabled ? 1.0 : 0.55)
    }

    private func roleColor(for role: String) -> Color {
        switch role {
        case "admin": return .orange
        case "logger": return .blue
        default: return Color(.systemGray)
        }
    }

    private func roleDisplayName(for role: String) -> String {
        switch role {
        case "admin": return "Program Admin"
        case "logger": return "Logger"
        default: return "Member"
        }
    }

    private func initials(for name: String) -> String {
        name.split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map { String($0).uppercased() }
            .joined()
    }

    private func updateRole(for member: APIClient.MembershipDetailDTO, to newRole: String) async {
        guard member.program_role != newRole else { return }

        isUpdating = member.member_id

        do {
            try await programContext.updateMembership(
                memberId: member.member_id,
                role: newRole,
                isActive: nil,
                joinedAt: nil
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isUpdating = nil
    }
}

// MARK: - Workout Types Section

private struct ProgramWorkoutTypesSection: View {
    @EnvironmentObject var programContext: ProgramContext

    private var visibleCount: Int {
        programContext.programWorkouts.filter { !$0.is_hidden }.count
    }

    private var customCount: Int {
        programContext.programWorkouts.filter { $0.isCustom }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Workout Types", icon: "dumbbell.fill", color: .purple)

            VStack(spacing: 12) {
                // View & Manage Workout Types - unified view
                NavigationLink {
                    ViewWorkoutTypesListView()
                } label: {
                    settingsRow(
                        icon: "list.bullet",
                        color: .purple,
                        title: "Workout Types",
                        subtitle: customCount > 0
                            ? "\(visibleCount) available, \(customCount) custom"
                            : "\(visibleCount) types available"
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
        )
        .adaptiveShadow(radius: 8, y: 4)
        .task {
            await programContext.loadProgramWorkouts()
        }
    }
}

// Workout types list with swipe actions for program admins
private struct ViewWorkoutTypesListView: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var searchText = ""
    @State private var showDeleteConfirm = false
    @State private var workoutToDelete: APIClient.ProgramWorkoutDTO?
    @State private var workoutToEdit: APIClient.ProgramWorkoutDTO?
    @State private var showAddSheet = false
    @State private var newWorkoutName = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?

    private var canManage: Bool {
        programContext.canEditProgramData
    }

    private var filteredWorkouts: [APIClient.ProgramWorkoutDTO] {
        let workouts = programContext.programWorkouts
        if searchText.isEmpty {
            return workouts
        }
        return workouts.filter {
            $0.workout_name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var visibleWorkouts: [APIClient.ProgramWorkoutDTO] {
        filteredWorkouts.filter { !$0.is_hidden }
    }

    private var hiddenWorkouts: [APIClient.ProgramWorkoutDTO] {
        filteredWorkouts.filter { $0.is_hidden }
    }

    var body: some View {
        List {
            // Visible workouts section
            if !visibleWorkouts.isEmpty {
                Section {
                    ForEach(visibleWorkouts) { workout in
                        workoutRow(workout)
                    }
                } header: {
                    Text("Available (\(visibleWorkouts.count))")
                }
            }

            // Hidden workouts section (only show to admins)
            if canManage && !hiddenWorkouts.isEmpty {
                Section {
                    ForEach(hiddenWorkouts) { workout in
                        workoutRow(workout)
                    }
                } header: {
                    HStack {
                        Image(systemName: "eye.slash")
                        Text("Hidden (\(hiddenWorkouts.count))")
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search workout types")
        .navigationTitle("Workout Types")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if canManage {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .task {
            await programContext.loadProgramWorkouts()
        }
        .refreshable {
            await programContext.loadProgramWorkouts()
        }
        .alert("Delete Custom Workout?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let workout = workoutToDelete {
                    Task { await deleteWorkout(workout) }
                }
            }
        } message: {
            Text("This will delete \"\(workoutToDelete?.workout_name ?? "")\" from this program.")
        }
        .sheet(isPresented: $showAddSheet) {
            addCustomWorkoutSheet
        }
        .sheet(item: $workoutToEdit) { workout in
            editCustomWorkoutSheet(workout)
        }
    }

    @ViewBuilder
    private func workoutRow(_ workout: APIClient.ProgramWorkoutDTO) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(workout.isCustom ? Color.appGreenLight : Color.appPurpleLight)
                    .frame(width: 40, height: 40)
                Image(systemName: workout.isCustom ? "star.fill" : "dumbbell.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(workout.isCustom ? .green : .purple)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.workout_name)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    Text(workout.isCustom ? "Custom" : "Standard")
                        .font(.caption2)
                        .foregroundColor(Color(.secondaryLabel))
                    if workout.is_hidden {
                        Text("• Hidden")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()
        }
        .opacity(workout.is_hidden ? 0.5 : 1.0)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if canManage {
                if workout.isGlobal {
                    // Global workout: toggle visibility only
                    Button {
                        Task { await toggleVisibility(workout) }
                    } label: {
                        Label(workout.is_hidden ? "Show" : "Hide", systemImage: workout.is_hidden ? "eye" : "eye.slash")
                    }
                    .tint(workout.is_hidden ? .green : .orange)
                } else {
                    // Custom workout: delete (will fail if has logs)
                    Button(role: .destructive) {
                        workoutToDelete = workout
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    // Custom workout: toggle visibility (alternative to delete)
                    Button {
                        Task { await toggleCustomVisibility(workout) }
                    } label: {
                        Label(workout.is_hidden ? "Show" : "Hide", systemImage: workout.is_hidden ? "eye" : "eye.slash")
                    }
                    .tint(workout.is_hidden ? .green : .orange)
                }
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if canManage && workout.isCustom && !workout.is_hidden {
                // Custom workout: edit (only if not hidden)
                Button {
                    workoutToEdit = workout
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
        }
    }

    private var addCustomWorkoutSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Workout name", text: $newWorkoutName)
                        .autocorrectionDisabled()
                } header: {
                    Text("Add Custom Workout")
                } footer: {
                    Text("Create a custom workout type for this program only.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        newWorkoutName = ""
                        errorMessage = nil
                        showAddSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task { await addCustomWorkout() }
                    }
                    .disabled(newWorkoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func editCustomWorkoutSheet(_ workout: APIClient.ProgramWorkoutDTO) -> some View {
        EditCustomWorkoutSheet(
            workout: workout,
            onSave: { newName in
                Task {
                    do {
                        try await programContext.editCustomProgramWorkout(workoutId: workout.id, name: newName)
                        workoutToEdit = nil
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            },
            onCancel: {
                workoutToEdit = nil
            }
        )
    }

    private func toggleVisibility(_ workout: APIClient.ProgramWorkoutDTO) async {
        guard let libraryId = workout.library_workout_id else { return }
        isProcessing = true
        do {
            try await programContext.toggleWorkoutVisibility(libraryWorkoutId: libraryId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    private func toggleCustomVisibility(_ workout: APIClient.ProgramWorkoutDTO) async {
        isProcessing = true
        do {
            try await programContext.toggleCustomWorkoutVisibility(workoutId: workout.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    private func deleteWorkout(_ workout: APIClient.ProgramWorkoutDTO) async {
        isProcessing = true
        do {
            try await programContext.deleteCustomProgramWorkout(workoutId: workout.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    private func addCustomWorkout() async {
        let name = newWorkoutName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        isProcessing = true
        errorMessage = nil
        do {
            try await programContext.addCustomProgramWorkout(name: name)
            newWorkoutName = ""
            showAddSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }
}

// Helper sheet for editing custom workout
private struct EditCustomWorkoutSheet: View {
    let workout: APIClient.ProgramWorkoutDTO
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var workoutName: String = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Workout name", text: $workoutName)
                        .autocorrectionDisabled()
                } header: {
                    Text("Edit Custom Workout")
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isSaving = true
                        onSave(workoutName.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    .disabled(workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .onAppear {
                workoutName = workout.workout_name
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - My Account Section

private struct ProgramMyAccountSection: View {
    @EnvironmentObject var programContext: ProgramContext
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showSignOutConfirm = false
    private let privacyPolicyURL = URL(string: "https://vinaysankar2004.github.io/RaSi-Fiters/")!

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "My Account", icon: "person.circle.fill", color: .gray)

            VStack(spacing: 12) {
                // My Profile
                NavigationLink {
                    MyProfileView()
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.appOrangeLight)
                                .frame(width: 42, height: 42)
                            Text(programContext.loggedInUserInitials)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.appOrange)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(programContext.loggedInUserName ?? "My Profile")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color(.label))
                            Text("@\(programContext.loggedInUsername ?? "")")
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
                .buttonStyle(.plain)

                // Change Password
                NavigationLink {
                    ChangePasswordView()
                } label: {
                    settingsRow(
                        icon: "lock.fill",
                        color: .appOrange,
                        title: "Change Password",
                        subtitle: "Update your account password"
                    )
                }
                .buttonStyle(.plain)

                // Appearance
                NavigationLink {
                    AppearanceSettingsView()
                        .environmentObject(themeManager)
                } label: {
                    settingsRow(
                        icon: themeManager.appearance.icon,
                        color: .appPurple,
                        title: "Appearance",
                        subtitle: themeManager.appearance.displayName
                    )
                }
                .buttonStyle(.plain)

                Link(destination: privacyPolicyURL) {
                    settingsRow(
                        icon: "doc.text",
                        color: .appOrange,
                        title: "Privacy Policy",
                        subtitle: "Learn how we handle your data"
                    )
                }
                .buttonStyle(.plain)

                // Sign Out
                Button {
                    showSignOutConfirm = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.appRedLight)
                                .frame(width: 42, height: 42)
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.appRed)
                        }
                        Text("Sign Out")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.appRed)
                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.appRed.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
        )
        .adaptiveShadow(radius: 8, y: 4)
        .alert("Sign Out?", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                programContext.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Appearance")
                        .font(.title2.weight(.bold))
                        .foregroundColor(Color(.label))
                    Text("Choose how RaSi Fit'ers looks to you")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .padding(.top, 8)
                
                // Appearance Options
                VStack(spacing: 12) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                themeManager.setAppearance(mode)
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(themeManager.appearance == mode ? Color.appOrangeLight : Color(.systemGray5))
                                        .frame(width: 42, height: 42)
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(themeManager.appearance == mode ? .appOrange : Color(.secondaryLabel))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mode.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color(.label))
                                    Text(modeDescription(mode))
                                        .font(.caption)
                                        .foregroundColor(Color(.secondaryLabel))
                                }
                                
                                Spacer()
                                
                                if themeManager.appearance == mode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.appOrange)
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(.systemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(themeManager.appearance == mode ? Color.appOrange.opacity(0.5) : Color(.systemGray4).opacity(0.6), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Preview Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("Preview")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(Color(.secondaryLabel))
                    
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.appOrangeLight)
                                .frame(width: 48, height: 48)
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.appOrange)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sample Card")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color(.label))
                            Text("This is how cards will appear")
                                .font(.caption)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        
                        Spacer()
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
                    .adaptiveShadow(radius: 8, y: 4)
                }
                .padding(.top, 8)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func modeDescription(_ mode: AppearanceMode) -> String {
        switch mode {
        case .system: return "Follows your device settings"
        case .light: return "Always use light appearance"
        case .dark: return "Always use dark appearance"
        }
    }
}


struct MyProfileView: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var gender: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Profile Header
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.appOrangeLight)
                            .frame(width: 70, height: 70)
                        Text(initials)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.appOrange)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(fullName)
                            .font(.title3.weight(.bold))
                        Text("@\(programContext.loggedInUsername ?? "")")
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                        Text(programContext.isGlobalAdmin ? "Global Admin" : (programContext.isProgramAdmin ? "Program Admin" : "Member"))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.appOrange)
                    }
                }

                Divider()

                // Editable Fields
                VStack(alignment: .leading, spacing: 14) {
                    // First Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("First name")
                            .font(.subheadline.weight(.semibold))
                        TextField("Enter first name", text: $firstName)
                            .textContentType(.givenName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    // Last Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Last name")
                            .font(.subheadline.weight(.semibold))
                        TextField("Enter last name", text: $lastName)
                            .textContentType(.familyName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    // Gender
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Gender")
                            .font(.subheadline.weight(.semibold))
                        Menu {
                            ForEach(["Male", "Female", "Non-binary", "Prefer not to say"], id: \.self) { option in
                                Button(option) { gender = option }
                            }
                            Button("Clear") { gender = "" }
                        } label: {
                            HStack {
                                Text(gender.isEmpty ? "Select gender" : gender)
                                    .foregroundColor(gender.isEmpty ? Color(.tertiaryLabel) : Color(.label))
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.appRed)
                        .font(.footnote.weight(.semibold))
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
                .background(Color.appOrange)
                .foregroundColor(.black)
                .cornerRadius(14)
                .disabled(isSaving)

                // Spacer to push delete button to bottom
                Spacer()
                    .frame(height: 40)

                // Delete Account Section
                if !programContext.isGlobalAdmin {
                    VStack(spacing: 8) {
                        Divider()
                            .padding(.bottom, 8)

                        Button(action: { showDeleteConfirmation = true }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.subheadline)
                                Text("Delete Account")
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundColor(.red.opacity(0.8))
                        }
                        .disabled(isDeleting)

                        Text("This will permanently delete your account and all associated data.")
                            .font(.caption)
                            .foregroundColor(Color(.tertiaryLabel))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                }
            }
            .padding(20)
        }
        .adaptiveBackground(topLeading: true)
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Saved", isPresented: $showSuccessAlert) {
            Button("OK") {}
        } message: {
            Text("Profile updated successfully")
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("This action cannot be undone. All your data, including workout logs, health logs, and program memberships will be permanently deleted.")
        }
        .onAppear {
            // Initialize fields from current values
            if let name = programContext.loggedInUserName {
                let parts = name.split(separator: " ", maxSplits: 1)
                firstName = parts.first.map(String.init) ?? ""
                lastName = parts.count > 1 ? String(parts[1]) : ""
            }
        }
    }

    private var fullName: String {
        let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? (programContext.loggedInUserName ?? "") : name
    }

    private var initials: String {
        let first = firstName.first.map { String($0).uppercased() } ?? ""
        let last = lastName.first.map { String($0).uppercased() } ?? ""
        let computed = "\(first)\(last)"
        return computed.isEmpty ? programContext.loggedInUserInitials : computed
    }

    private func deleteAccount() async {
        isDeleting = true
        errorMessage = nil

        do {
            try await programContext.deleteAccount()
            // After successful deletion, signOut is called automatically
            // which will trigger navigation back to login
        } catch {
            errorMessage = error.localizedDescription
            isDeleting = false
        }
    }

    private func save() async {
        guard let userId = programContext.loggedInUserId else { return }

        // Validate that names are not empty
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespaces)

        if trimmedFirst.isEmpty {
            errorMessage = "First name is required"
            return
        }
        if trimmedLast.isEmpty {
            errorMessage = "Last name is required"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            try await programContext.updateMemberProfile(
                memberId: userId,
                firstName: trimmedFirst,
                lastName: trimmedLast,
                gender: gender.isEmpty ? nil : gender
            )
            showSuccessAlert = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}

struct ChangePasswordView: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false

    private var isValid: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword && newPassword.count >= 6
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Change Password")
                        .font(.title2.weight(.bold))
                        .foregroundColor(Color(.label))
                    Text("Enter your new password")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }

                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("New password")
                            .font(.subheadline.weight(.semibold))
                        HStack {
                            if showPassword {
                                TextField("••••••••", text: $newPassword)
                            } else {
                                SecureField("••••••••", text: $newPassword)
                            }
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm password")
                            .font(.subheadline.weight(.semibold))
                        SecureField("••••••••", text: $confirmPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    if !newPassword.isEmpty && newPassword.count < 6 {
                        Text("Password must be at least 6 characters")
                            .font(.caption)
                            .foregroundColor(.appOrange)
                    }

                    if !confirmPassword.isEmpty && newPassword != confirmPassword {
                        Text("Passwords do not match")
                            .font(.caption)
                            .foregroundColor(.appRed)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.appRed)
                        .font(.footnote.weight(.semibold))
                }

                Button(action: { Task { await save() } }) {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Update Password")
                            .font(.headline.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValid ? Color.appOrange : Color(.systemGray3))
                .foregroundColor(.black)
                .cornerRadius(14)
                .disabled(!isValid || isSaving)
            }
            .padding(20)
        }
        .adaptiveBackground(topLeading: true)
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Password Updated", isPresented: $showSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your password has been changed successfully")
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil

        do {
            try await programContext.changePassword(newPassword: newPassword)
            showSuccessAlert = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}

// MARK: - Section Helpers

private func sectionHeader(title: String, icon: String, color: Color) -> some View {
    HStack(spacing: 10) {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(color)
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundColor(Color(.label))
    }
}

private func settingsRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
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

private struct SummaryHeader: View {
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

private struct WorkoutTypesHeader: View {
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

private struct PeriodSelector: View {
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

private struct ProgramProgressCard: View {
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

private struct CompletionRing: View {
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

private struct MTDParticipationCard: View {
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

private struct TotalWorkoutsCard: View {
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

private struct TotalDurationCard: View {
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

private struct AvgDurationCard: View {
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

private struct WorkoutTypesTotalCard: View {
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

private struct WorkoutTypeMostPopularCard: View {
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

private struct WorkoutTypeLongestDurationCard: View {
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

private struct WorkoutTypeHighestParticipationCard: View {
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

private struct WorkoutTypePopularityCard: View {
    let types: [APIClient.WorkoutTypeDTO]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var metric: WorkoutPopularityMetric = .count
    @State private var showAll = false
    @State private var includeTopCategory = true

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    private var sortedTypes: [APIClient.WorkoutTypeDTO] {
        workoutPopularitySorted(types: types, metric: metric)
    }

    private var outlier: WorkoutPopularityOutlier {
        workoutPopularityOutlier(sortedTypes: sortedTypes, metric: metric)
    }

    private var filteredTypes: [APIClient.WorkoutTypeDTO] {
        guard isCompact, outlier.isOutlier, !includeTopCategory else { return sortedTypes }
        return Array(sortedTypes.dropFirst())
    }

    private var displayTypes: [APIClient.WorkoutTypeDTO] {
        if isCompact && !showAll {
            return Array(filteredTypes.prefix(6))
        }
        return filteredTypes
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

                if isCompact && outlier.isOutlier, let top = outlier.topType {
                    OutlierToggle(
                        topLabel: top.workout_name,
                        topValue: metric.formattedValue(for: top),
                        includeTop: $includeTopCategory
                    )
                }

                Text(metric.axisLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(.secondaryLabel))

                RankedBarList(rows: rows, maxValue: maxValue)

                if isCompact && filteredTypes.count > 6 {
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
        .animation(.easeInOut(duration: 0.2), value: includeTopCategory)
        .animation(.easeInOut(duration: 0.2), value: showAll)
        .onAppear { resetOutlierToggle() }
        .onChange(of: metric) { _ in resetOutlierToggle() }
        .onChange(of: types.count) { _ in resetOutlierToggle() }
    }

    private func resetOutlierToggle() {
        guard isCompact else {
            includeTopCategory = true
            return
        }
        includeTopCategory = !outlier.isOutlier
    }
}

private struct AccentChip: View {
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

private struct ActivityTimelineCardSummary: View {
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

private struct LifestyleTimelineCardSummary: View {
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

private struct ActivityTimelineDetailView: View {
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
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.appRed)
                    .font(.footnote.weight(.semibold))
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

private struct LifestyleTimelineDetailView: View {
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
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.appRed)
                    .font(.footnote.weight(.semibold))
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

// MARK: - Shared header for timeline detail
private struct HealthHeaderStats: View {
    let label: String
    let sleepAverage: Double
    let foodAverage: Double

    private var sleepValue: String {
        String(format: "%.1f hrs", sleepAverage)
    }

    private var foodValue: String {
        String(format: "%.1f / 5", foodAverage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DAILY AVERAGE")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color(.secondaryLabel))
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sleep")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(Color(.secondaryLabel))
                            Text(sleepValue)
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.appBlue)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Diet")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(Color(.secondaryLabel))
                            Text(foodValue)
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.appGreen)
                        }
                    }
                }
                Spacer()
                Text(label.isEmpty ? "—" : label)
                    .font(.callout.weight(.medium))
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
    }
}

private struct HeaderStats: View {
    let label: String
    let dailyAverage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DAILY AVERAGE")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color(.secondaryLabel))
                    Text(String(format: "%.0f", dailyAverage))
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.appOrange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label.isEmpty ? "—" : label)
                        .font(.callout.weight(.medium))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
        }
    }
}

private struct HeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct CalloutView: View {
    let label: String
    let workouts: Int
    let active: Int?
    var showActive: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
            HStack {
                Circle().fill(.orange).frame(width: 6, height: 6)
                Text("Workouts: \(workouts)")
            }
            .font(.caption2)
            if showActive, let active {
                HStack {
                    Circle().fill(.purple).frame(width: 6, height: 6)
                    Text("Active: \(active)")
                }
                .font(.caption2)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(radius: 4, y: 2)
        )
    }
}

private struct HealthCalloutView: View {
    let label: String
    let sleep: Double
    let food: Double

    private var sleepValue: String {
        String(format: "%.1f hrs", sleep)
    }

    private var foodValue: String {
        String(format: "%.1f / 5", food)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
            HStack {
                Circle().fill(Color.appBlue).frame(width: 6, height: 6)
                Text("Sleep: \(sleepValue)")
            }
            .font(.caption2)
            HStack {
                Circle().fill(Color.appGreen).frame(width: 6, height: 6)
                Text("Diet: \(foodValue)")
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

private struct GlassButton: View {
    let icon: String

    var body: some View {
        Image(systemName: icon)
            .font(.title2.weight(.semibold))
            .foregroundColor(Color(.black))
            .frame(width: 52, height: 52)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appOrange, Color.appOrangeGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color(.black).opacity(0.16), radius: 10, x: 0, y: 6)
    }
}

// MARK: - Member Metrics Module

private struct MemberMetricsModule: View {
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
        .onChange(of: sortField) { _ in Task { await loadMetrics() } }
        .onChange(of: sortDirection) { _ in Task { await loadMetrics() } }
        .onChange(of: filters) { _ in Task { await loadMetrics() } }
        .onChange(of: programContext.programId) { _ in Task { await loadMetrics() } }
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

private struct MemberMetricsDetailView: View {
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
        .onChange(of: sortField) { _ in Task { await loadMetrics() } }
        .onChange(of: sortDirection) { _ in Task { await loadMetrics() } }
        .onChange(of: filters) { _ in Task { await loadMetrics() } }
        .onChange(of: programContext.programId) { _ in Task { await loadMetrics() } }
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

private struct MemberMetricsPreviewCard: View {
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

// MARK: - Member Picker and Overview

private struct MemberPickerView: View {
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

private struct MemberOverviewCard: View {
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
private enum SortField: String, CaseIterable, Hashable {
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

private enum SortDirection: String, Hashable {
    case asc
    case desc
}

private struct MetricsFilters: Hashable {
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

private struct SortSheet: View {
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

private struct FilterSheet: View {
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

private struct MemberMetricsCard: View {
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

private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
    Swift.max(min, Swift.min(max, value))
}

private func memberTimelinePoints(from history: [APIClient.MemberHistoryPoint]) -> [APIClient.ActivityTimelinePoint] {
    history.map {
        APIClient.ActivityTimelinePoint(
            date: $0.date,
            label: $0.label,
            workouts: $0.workouts,
            active_members: 0
        )
    }
}
// MARK: - Distribution helpers
private struct DistributionPoint: Identifiable {
    let id = UUID()
    let label: String
    let short: String
    let workouts: Int
}

private func distributionPoints(fromCounts map: [String: Int]) -> [DistributionPoint] {
    let order = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    let short = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    return order.enumerated().map { idx, day in
        let value = map[day] ?? 0
        return DistributionPoint(label: day, short: short[idx], workouts: value)
    }
}

// MARK: - Axis / Callout helpers
private func axisValues(for period: AdminHomeView.Period, startDate: Date, endDate: Date) -> [String] {
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

private func shortLabel(for value: String, period: AdminHomeView.Period) -> String {
    switch period {
    case .year, .program:
        return String(value.prefix(1))
    default:
        return value
    }
}

private func programMonthLabels(start: Date, end: Date) -> [String] {
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

private func calloutTitle(for point: APIClient.ActivityTimelinePoint, period: AdminHomeView.Period) -> String {
    calloutTitle(dateString: point.date, label: point.label, period: period)
}

private func calloutTitle(dateString: String, label: String, period: AdminHomeView.Period) -> String {
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

private func formatCalloutDate(date: Date, period: AdminHomeView.Period, formatter: DateFormatter) -> String {
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

private func rangeLabel(for period: AdminHomeView.Period) -> String {
    rangeLabel(for: period, startDate: Date(), endDate: Date())
}

private func rangeLabel(for period: AdminHomeView.Period, startDate: Date, endDate: Date) -> String {
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
private struct DistributionByDayCard: View {
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

private struct ChartOverlay: View {
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
private func typeColor(for name: String) -> Color {
    let palette: [Color] = [
        Color(red: 0.95, green: 0.60, blue: 0.00), // amber
        Color(red: 0.00, green: 0.60, blue: 0.90), // blue
        Color(red: 0.20, green: 0.70, blue: 0.30), // green
        Color(red: 0.60, green: 0.35, blue: 0.80), // purple
        Color(red: 0.95, green: 0.30, blue: 0.35), // coral red
        Color(red: 0.05, green: 0.75, blue: 0.70), // teal
        Color(red: 0.95, green: 0.45, blue: 0.70), // pink
        Color(red: 0.35, green: 0.45, blue: 0.90), // indigo-ish
        Color(red: 0.85, green: 0.55, blue: 0.15), // brownish
        Color(red: 0.55, green: 0.80, blue: 0.20), // lime
        Color(red: 0.10, green: 0.55, blue: 0.50), // sea
        Color(red: 0.80, green: 0.20, blue: 0.50)  // magenta
    ]
    var hash = 5381
    for u in name.unicodeScalars {
        hash = ((hash << 5) &+ hash) &+ Int(u.value)
    }
    let idx = abs(hash) % palette.count
    return palette[idx]
}

private func barColor(for type: APIClient.WorkoutTypeDTO) -> Color {
    type.workout_name == "Others" ? Color(.systemGray3) : typeColor(for: type.workout_name)
}

// MARK: - Distribution detail
private struct DistributionByDayDetailView: View {
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

// MARK: - Workout Types summary card
private struct WorkoutTypesSummaryCard: View {
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
private struct WorkoutTypesDetailView: View {
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

private struct WorkoutTypeRow: View {
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

private struct ScrollableBarChart<Content: View>: View {
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

private struct CardShell<Content: View, Background: View>: View {
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

private struct MetricCard: View {
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

private struct ActivityTile: View {
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

private struct SparklineView: View {
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

private struct IconBadge: View {
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

private struct AddWorkoutCard: View {
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

private struct AddDailyHealthCard: View {
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

private struct AnalyticsDetailView: View {
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
                    .onChange(of: period) { newValue in
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

private struct InviteMemberView: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.dismiss) private var dismiss

    @State private var username: String = ""
    @State private var isSending = false
    @State private var showSuccessMessage = false
    @State private var errorMessage: String?

    private var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        programContext.programId != nil
    }

    var body: some View {
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

                if showSuccessMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Invitation sent")
                            .foregroundColor(.green)
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }

                sendButton
            }
            .padding(20)
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
                        showSuccessMessage = false
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
        showSuccessMessage = false

        do {
            let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = try await APIClient.shared.sendProgramInvite(
                token: token,
                programId: programId,
                username: trimmedUsername
            )

            // Always show success (privacy-preserving)
            showSuccessMessage = true
            username = ""

        } catch {
            // Even on error, show success for privacy
            // But if it's a network error, show that
            if error.localizedDescription.contains("network") ||
               error.localizedDescription.contains("connection") {
                errorMessage = "Network error. Please try again."
            } else {
                showSuccessMessage = true
                username = ""
            }
        }

        isSending = false
    }
}

private struct AddWorkoutDetailView: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var selectedMember: APIClient.MemberDTO?
    @State private var selectedWorkout: APIClient.WorkoutDTO?
    @State private var selectedDate: Date = Date()
    @State private var durationText: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
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
    }

    private var isFormValid: Bool {
        selectedMember != nil && selectedWorkout != nil && Int(durationText) != nil
    }

    private var canSelectAnyMember: Bool {
        let result = programContext.globalRole == "global_admin" ||
            programContext.loggedInUserProgramRole == "admin" ||
            programContext.loggedInUserProgramRole == "logger"
        print("[AddWorkout] canSelectAnyMember: \(result) | globalRole: '\(programContext.globalRole)' | programRole: '\(programContext.loggedInUserProgramRole)'")
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

            pillPicker(
                title: "Workout type",
                placeholder: "Select workout",
                selection: Binding(
                    get: { selectedWorkout?.workout_name ?? "" },
                    set: { name in selectWorkout(named: name) }
                ),
                options: workoutOptions
            )

            dateField

            VStack(alignment: .leading, spacing: 6) {
                Text("Duration (mins)")
                    .font(.subheadline.weight(.semibold))
                TextField("e.g. 45", text: $durationText)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
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
        let _ = print("[AddWorkout] memberField rendering - members count: \(programContext.members.count), workouts count: \(programContext.workouts.count)")
        VStack(alignment: .leading, spacing: 6) {
            Text("Member")
                .font(.subheadline.weight(.semibold))
            if canSelectAnyMember {
                // Full access: show dropdown picker
                Menu {
                    ForEach(programContext.members, id: \.id) { member in
                        Button(member.member_name) {
                            selectedMember = member
                        }
                    }
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
            } else {
                // Restricted: show disabled picker with user's name
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

    private func pillPicker(title: String, placeholder: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) { selection.wrappedValue = option }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue.isEmpty ? placeholder : selection.wrappedValue)
                        .foregroundColor(selection.wrappedValue.isEmpty ? Color(.tertiaryLabel) : Color(.label))
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

    private func save() async {
        guard let token = programContext.authToken,
              let member = selectedMember,
              let workout = selectedWorkout,
              let duration = Int(durationText) else { return }

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
        print("[AddWorkout] ensureLookups called - globalRole: '\(programContext.globalRole)' | programRole: '\(programContext.loggedInUserProgramRole)'")
        print("[AddWorkout] Before load - members: \(programContext.members.count), workouts: \(programContext.workouts.count)")
        let needsProgramRefresh = programContext.membersProgramId != programContext.programId
        if programContext.members.isEmpty || programContext.workouts.isEmpty || needsProgramRefresh {
            await programContext.loadLookupData()
            print("[AddWorkout] After loadLookupData - members: \(programContext.members.count), workouts: \(programContext.workouts.count)")
        }
        if programContext.programId != nil {
            await programContext.loadProgramWorkouts()
            print("[AddWorkout] After loadProgramWorkouts - programWorkouts: \(programContext.programWorkouts.count)")
        }
        // Ensure membership details (including program role) are loaded
        if programContext.membershipDetails.isEmpty || needsProgramRefresh {
            await programContext.loadMembershipDetails()
            print("[AddWorkout] After loadMembershipDetails - programRole: '\(programContext.loggedInUserProgramRole)'")
        }
        // Auto-select logged-in user if they can only log for themselves
        if !canSelectAnyMember, selectedMember == nil {
            if let userId = programContext.loggedInUserId {
                selectedMember = programContext.members.first { $0.id == userId }
                print("[AddWorkout] Auto-selected self because canSelectAnyMember=false")
            }
        }
    }
}

private struct AddDailyHealthDetailView: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMember: APIClient.MemberDTO?
    @State private var selectedDate: Date = Date()
    @State private var sleepHoursText: String = ""
    @State private var foodQuality: Int?
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false

    private var canSelectAnyMember: Bool {
        programContext.globalRole == "global_admin" ||
        programContext.loggedInUserProgramRole == "admin" ||
        programContext.loggedInUserProgramRole == "logger"
    }

    private var trimmedSleepText: String {
        sleepHoursText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var sleepValue: Double? {
        guard !trimmedSleepText.isEmpty else { return nil }
        return Double(trimmedSleepText)
    }

    private var isSleepValid: Bool {
        guard !trimmedSleepText.isEmpty else { return true }
        guard let sleepValue else { return false }
        return sleepValue >= 0 && sleepValue <= 24
    }

    private var hasAtLeastOneMetric: Bool {
        (sleepValue != nil && !trimmedSleepText.isEmpty) || foodQuality != nil
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
                Text("Sleep hours")
                    .font(.subheadline.weight(.semibold))
                TextField("e.g. 7.5", text: $sleepHoursText)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                if !isSleepValid {
                    Text("Sleep hours must be between 0 and 24.")
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
                Menu {
                    ForEach(programContext.members, id: \.id) { member in
                        Button(member.member_name) {
                            selectedMember = member
                        }
                    }
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

        let sleepHours: Double?
        if trimmedSleepText.isEmpty {
            sleepHours = nil
        } else {
            sleepHours = Double(trimmedSleepText)
        }

        do {
            try await APIClient.shared.addDailyHealthLog(
                token: token,
                programId: programId,
                memberId: member.id,
                logDate: dateString,
                sleepHours: sleepHours,
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
}

// MARK: - Card ordering helpers

private enum SummaryCardType: String, CaseIterable, Hashable {
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

private struct CardDropDelegate: DropDelegate {
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

private struct PlaceholderCard: View {
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

private struct AdminTabScaffold<Content: View>: View {
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

private struct GlassHeader: View {
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

private struct GlassCard: View {
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

private struct LogoBadge: View {
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

// MARK: - Standard Program Tab (for non-admin users)

private struct StandardProgramTab: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var showSelectProgram = false
    @State private var showLeaveProgramConfirm = false
    @State private var isLeavingProgram = false
    @State private var leaveProgramError: String?

    private var loggedInUserInitials: String {
        guard let name = programContext.loggedInUserName else { return "??" }
        return name
            .split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map { String($0).uppercased() }
            .joined()
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.appBackground
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Header
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Program")
                                    .font(.largeTitle.weight(.bold))
                                    .foregroundColor(Color(.label))
                                Text(programContext.name)
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
                                Text(loggedInUserInitials)
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.top, 24)

                        // Program Info Card (read-only)
                        programInfoCard

                        // Switch Program Button
                        switchProgramButton

                        // Leave Program Button
                        leaveProgramButton

                        // My Account Section
                        ProgramMyAccountSection()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $showSelectProgram) {
                ProgramPickerView()
                    .navigationBarBackButtonHidden(true)
            }
            .alert("Leave Program?", isPresented: $showLeaveProgramConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Leave", role: .destructive) {
                    Task { await leaveProgram() }
                }
            } message: {
                Text("You will no longer have access to \(programContext.name). Your workout history and data will be preserved. If you're invited back and accept, your data will be restored.")
            }
            .alert("Error", isPresented: .constant(leaveProgramError != nil)) {
                Button("OK") { leaveProgramError = nil }
            } message: {
                Text(leaveProgramError ?? "")
            }
        }
    }

    private var programInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Program Info")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(Color(.label))
            }

            VStack(alignment: .leading, spacing: 12) {
                // Program Name
                HStack {
                    Text("Name")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                    Spacer()
                    Text(programContext.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(.label))
                }

                Divider()

                // Status
                HStack {
                    Text("Status")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                    Spacer()
                    Text(programContext.status.capitalized)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(statusColor(programContext.status))
                        )
                }

                Divider()

                // Date Range
                HStack {
                    Text("Duration")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                    Spacer()
                    Text(programContext.dateRangeLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color(.label))
                }

                Divider()

                // Progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                        Spacer()
                        Text("\(programContext.completionPercent)%")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(.label))
                    }

                    ProgressView(value: Double(programContext.completionPercent) / 100.0)
                        .accentColor(statusColor(programContext.status))
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)

                    HStack {
                        Text("\(programContext.elapsedDays) days elapsed")
                            .font(.caption)
                            .foregroundColor(Color(.tertiaryLabel))
                        Spacer()
                        Text("\(programContext.remainingDays) days remaining")
                            .font(.caption)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }

                Divider()

                // Active Members
                HStack {
                    Text("Active Members")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                    Spacer()
                    Text("\(programContext.activeMembers)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(.label))
                }
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
        )
        .adaptiveShadow(radius: 8, y: 4)
    }

    private var switchProgramButton: some View {
        Button {
            showSelectProgram = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.appOrangeVeryLight)
                        .frame(width: 42, height: 42)
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.appOrange)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Switch Program")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(.label))
                    Text("View a different program")
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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
            )
            .adaptiveShadow(radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var leaveProgramButton: some View {
        Button {
            showLeaveProgramConfirm = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 42, height: 42)
                    Image(systemName: "arrow.left.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(.secondaryLabel))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Leave Program")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(.label))
                    Text("Your data will be preserved")
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
                Spacer()
                if isLeavingProgram {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(14)
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
        .buttonStyle(.plain)
        .disabled(isLeavingProgram)
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "completed": return .appGreen
        case "planned": return .appBlue
        case "active": return .appOrange
        default: return .appOrange
        }
    }

    private func leaveProgram() async {
        isLeavingProgram = true
        leaveProgramError = nil
        do {
            _ = try await programContext.leaveProgram()
        } catch {
            leaveProgramError = error.localizedDescription
        }
        isLeavingProgram = false
    }
}

// MARK: - Placeholder Tab for Standard Users

private struct PlaceholderTab: View {
    let title: String
    let icon: String
    let description: String

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.appOrangeLight)
                        .frame(width: 100, height: 100)

                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.appOrange)
                }

                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color(.label))

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Text("Coming Soon")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.appOrange)
                    )

                Spacer()
                Spacer()
            }
        }
    }
}

#Preview {
    NavigationStack {
        AdminHomeView()
            .environmentObject(ProgramContext())
    }
}
