import SwiftUI

struct QuickAddWorkoutWidgetEntryView: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedProgramIds: Set<String> = []
    @State private var selectedMemberId: String?
    @State private var selectedWorkoutName: String = ""
    @State private var selectedDate: Date = Date()
    @State private var durationText: String = ""
    @State private var isSaving = false
    @State private var isLoadingDetails = false
    @State private var errorMessage: String?
    @State private var showSuccessToast = false
    @State private var programMembers: [String: [APIClient.MembershipDetailDTO]] = [:]
    @State private var programWorkouts: [String: [APIClient.ProgramWorkoutDTO]] = [:]

    private struct MemberOption: Identifiable, Hashable {
        let id: String
        let name: String
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    programSelection
                    memberField
                    workoutField
                    dateField
                    durationField

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.appRed)
                            .font(.footnote.weight(.semibold))
                    }

                    saveButton
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
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
        .task {
            await loadInitialData()
        }
        .onChange(of: selectedProgramIds) { _ in
            Task { await loadSelectedProgramData() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    exitToMyPrograms()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 36, height: 36)
                        Image(systemName: "chevron.left")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(Color(.label))
                    }
                }
                .buttonStyle(.plain)

                Spacer()
            }

            Text("Quick Add Workout")
                .font(.title2.weight(.bold))
                .foregroundColor(Color(.label))

            Text("Log the same workout across selected programs.")
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
        }
    }

    private var programSelection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Log to Programs")
                .font(.subheadline.weight(.semibold))

            if activePrograms.isEmpty {
                Text("No active programs found.")
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(activePrograms, id: \.id) { program in
                        programRow(program)
                    }
                }
            }

            if isLoadingDetails {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading program details...")
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }

            if selectedProgramIds.isEmpty && !activePrograms.isEmpty {
                Text("Select at least one program.")
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
    }

    private func programRow(_ program: APIClient.ProgramDTO) -> some View {
        let isSelected = selectedProgramIds.contains(program.id)
        return Button {
            toggleProgram(program.id)
        } label: {
            HStack {
                Text(program.name)
                    .foregroundColor(Color(.label))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appGreen)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var memberField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Member")
                .font(.subheadline.weight(.semibold))

            if canSelectAnyMember {
                if availableMembers.isEmpty {
                    let helperText = selectedProgramIds.isEmpty
                        ? "Select programs first"
                        : "No shared members across selected programs"
                    HStack {
                        Text(helperText)
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
                } else {
                    Menu {
                        ForEach(availableMembers) { member in
                            Button(member.name) {
                                selectedMemberId = member.id
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedMemberName ?? "Select member")
                                .foregroundColor(selectedMemberName == nil ? Color(.tertiaryLabel) : Color(.label))
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
            } else {
                HStack {
                    Text(programContext.loggedInUserName ?? "You")
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

    private var workoutField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Workout type")
                .font(.subheadline.weight(.semibold))

            if availableWorkouts.isEmpty {
                let helperText = selectedProgramIds.isEmpty
                    ? "Select programs first"
                    : "No shared workouts across selected programs"
                HStack {
                    Text(helperText)
                        .foregroundColor(Color(.tertiaryLabel))
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray5))
                .cornerRadius(12)
            } else {
                Menu {
                    ForEach(availableWorkouts, id: \.self) { option in
                        Button(option) { selectedWorkoutName = option }
                    }
                } label: {
                    HStack {
                        Text(selectedWorkoutName.isEmpty ? "Select workout" : selectedWorkoutName)
                            .foregroundColor(selectedWorkoutName.isEmpty ? Color(.tertiaryLabel) : Color(.label))
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

    private var durationField: some View {
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

    private var saveButton: some View {
        Button(action: { Task { await save() } }) {
            if isSaving {
                ProgressView().tint(colorScheme == .dark ? .black : .white)
            } else {
                Text("Save workout")
                    .font(.headline.weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isFormValid ? Color.appOrange : Color(.systemGray3))
        .foregroundColor(.black)
        .cornerRadius(14)
        .disabled(!isFormValid || isSaving)
    }

    private var successToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.appGreen)
            Text("Workout logged")
                .foregroundColor(Color(.label))
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(999)
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
    }

    private var activePrograms: [APIClient.ProgramDTO] {
        programContext.programs.filter { ($0.my_status ?? "").lowercased() == "active" }
    }

    private var selectedPrograms: [APIClient.ProgramDTO] {
        activePrograms.filter { selectedProgramIds.contains($0.id) }
    }

    private var canSelectAnyMember: Bool {
        guard !selectedProgramIds.isEmpty else { return false }
        if programContext.isGlobalAdmin { return true }
        if selectedProgramIds.count == 1 {
            let role = selectedPrograms.first?.my_role?.lowercased() ?? ""
            return role == "admin" || role == "logger"
        }
        return !selectedPrograms.contains { ($0.my_role ?? "").lowercased() != "admin" }
    }

    private var availableMembers: [MemberOption] {
        guard !selectedProgramIds.isEmpty else { return [] }
        let lists = selectedProgramIds.compactMap { programMembers[$0] }
        guard lists.count == selectedProgramIds.count, let first = lists.first else { return [] }
        var intersection = Set(first.map { $0.member_id })
        for list in lists.dropFirst() {
            intersection.formIntersection(list.map { $0.member_id })
        }
        return first
            .filter { intersection.contains($0.member_id) }
            .map { MemberOption(id: $0.member_id, name: $0.member_name) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var availableWorkouts: [String] {
        guard !selectedProgramIds.isEmpty else { return [] }
        let lists = selectedProgramIds.compactMap { programWorkouts[$0] }
        guard lists.count == selectedProgramIds.count, let first = lists.first else { return [] }
        var intersection = Set(first.map { $0.workout_name })
        for list in lists.dropFirst() {
            intersection.formIntersection(list.map { $0.workout_name })
        }
        return first
            .map { $0.workout_name }
            .filter { intersection.contains($0) }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var selectedMemberName: String? {
        availableMembers.first(where: { $0.id == selectedMemberId })?.name
    }

    private var isFormValid: Bool {
        guard !selectedProgramIds.isEmpty else { return false }
        guard let _ = resolvedMemberId else { return false }
        guard !selectedWorkoutName.isEmpty else { return false }
        return Int(durationText) != nil
    }

    private var resolvedMemberId: String? {
        if canSelectAnyMember {
            return selectedMemberId
        }
        return programContext.loggedInUserId
    }

    private var resolvedMemberName: String? {
        if canSelectAnyMember {
            return selectedMemberName
        }
        return programContext.loggedInUserName ?? "You"
    }

    private func toggleProgram(_ programId: String) {
        if selectedProgramIds.contains(programId) {
            selectedProgramIds.remove(programId)
        } else {
            selectedProgramIds.insert(programId)
        }
        syncSelectionsAfterDataLoad()
    }

    @MainActor
    private func loadInitialData() async {
        if programContext.programs.isEmpty {
            await programContext.loadLookupData()
        }
        syncSelectionsAfterDataLoad()
    }

    @MainActor
    private func loadSelectedProgramData() async {
        guard let token = programContext.authToken, !token.isEmpty else { return }
        guard !selectedProgramIds.isEmpty else {
            syncSelectionsAfterDataLoad()
            return
        }

        isLoadingDetails = true
        let selectedIds = Array(selectedProgramIds)

        for programId in selectedIds {
            if programMembers[programId] == nil {
                do {
                    let data = try await APIClient.shared.fetchMembershipDetails(token: token, programId: programId)
                    programMembers[programId] = data.filter { $0.is_active }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }

            if programWorkouts[programId] == nil {
                do {
                    let data = try await APIClient.shared.fetchProgramWorkouts(token: token, programId: programId)
                    programWorkouts[programId] = data.filter { !$0.is_hidden }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }

        isLoadingDetails = false
        syncSelectionsAfterDataLoad()
    }

    @MainActor
    private func save() async {
        guard let token = programContext.authToken, !token.isEmpty else { return }
        guard !selectedProgramIds.isEmpty else {
            errorMessage = "Select at least one program."
            return
        }
        guard let memberId = resolvedMemberId,
              let memberName = resolvedMemberName,
              !selectedWorkoutName.isEmpty,
              let duration = Int(durationText) else {
            return
        }

        isSaving = true
        errorMessage = nil
        showSuccessToast = false

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: selectedDate)

        var completedPrograms: [String] = []
        do {
            for programId in selectedProgramIds.sorted() {
                try await APIClient.shared.addWorkoutLog(
                    token: token,
                    memberName: memberName,
                    workoutName: selectedWorkoutName,
                    date: dateString,
                    durationMinutes: duration,
                    programId: programId,
                    memberId: memberId
                )
                completedPrograms.append(programId)
            }

            showSuccessToast = true
            scheduleSuccessDismiss()
        } catch {
            if !completedPrograms.isEmpty {
                let rollbackFailed = await rollbackLogs(
                    programIds: completedPrograms,
                    token: token,
                    memberId: memberId,
                    workoutName: selectedWorkoutName,
                    dateString: dateString
                )
                if rollbackFailed {
                    errorMessage = "Couldn’t save. Some programs may have been updated. Please review My Programs."
                } else {
                    errorMessage = friendlyError(for: error)
                }
            } else {
                errorMessage = friendlyError(for: error)
            }
        }

        isSaving = false
    }

    private func friendlyError(for error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        if message.contains("network") || message.contains("offline") || message.contains("connection") {
            return "Couldn’t save. Try again."
        }
        if message.contains("already") || message.contains("exists") || message.contains("duplicate") {
            return "Workout already logged for at least one selected program."
        }
        return error.localizedDescription
    }

    @MainActor
    private func rollbackLogs(
        programIds: [String],
        token: String,
        memberId: String,
        workoutName: String,
        dateString: String
    ) async -> Bool {
        var failed = false
        for programId in programIds {
            do {
                try await APIClient.shared.deleteWorkoutLog(
                    token: token,
                    programId: programId,
                    memberId: memberId,
                    workoutName: workoutName,
                    date: dateString
                )
            } catch {
                failed = true
            }
        }
        return failed
    }

    @MainActor
    private func scheduleSuccessDismiss() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            exitToMyPrograms()
        }
    }

    @MainActor
    private func syncSelectionsAfterDataLoad() {
        let activeIds = Set(activePrograms.map { $0.id })
        if !activeIds.isEmpty {
            selectedProgramIds = selectedProgramIds.intersection(activeIds)
        }

        if !canSelectAnyMember {
            selectedMemberId = programContext.loggedInUserId
        } else if let selectedMemberId, !availableMembers.contains(where: { $0.id == selectedMemberId }) {
            self.selectedMemberId = nil
        }

        if !availableWorkouts.contains(selectedWorkoutName) {
            selectedWorkoutName = ""
        }
    }

    @MainActor
    private func exitToMyPrograms() {
        programContext.returnToMyPrograms = true
        programContext.widgetRoute = nil
        dismiss()
    }
}

#Preview {
    QuickAddWorkoutWidgetEntryView()
}
