import SwiftUI

struct ProgramPickerView: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation = false
    @State private var programToDelete: APIClient.ProgramDTO?
    @State private var isDeleting = false
    @State private var showProgramActions = false
    @State private var programToEdit: APIClient.ProgramDTO?
    @State private var programToOpen: APIClient.ProgramDTO?
    @State private var showSignOutConfirmation = false
    @State private var showAccountMenu = false
    @State private var accountDestination: AccountDestination?
    
    private var pendingInvitesCount: Int {
        programContext.pendingInvites.count
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            List {
                Color.clear
                    .frame(height: 90)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                if isLoading {
                    ProgressView()
                        .padding(.top, 12)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else if programContext.programs.isEmpty {
                    emptyState
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(programContext.programs, id: \.id) { program in
                        let membershipStatus = program.my_status?.lowercased()
                        let canOpen = programContext.isGlobalAdmin || membershipStatus == nil || membershipStatus == "active"
                        let canManage = programContext.isGlobalAdmin || (membershipStatus == "active" && program.my_role == "admin")
                        let card = ProgramCard(
                            program: program,
                            membershipStatus: membershipStatus,
                            onAccept: membershipStatus == "invited" ? {
                                _ = Task<Void, Never> { await respondToInvite(program: program, accept: true) }
                            } : nil,
                            onDecline: (membershipStatus == "invited" || membershipStatus == "requested") ? {
                                _ = Task<Void, Never> { await respondToInvite(program: program, accept: false) }
                            } : nil
                        )

                        card
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard canOpen else { return }
                            applyProgram(program)
                            programToOpen = program
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            if canManage {
                                Button {
                                    applyProgram(program)
                                    programToEdit = program
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if canManage {
                                Button(role: .destructive) {
                                    programToDelete = program
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                // Bottom padding for floating button
                Color.clear
                    .frame(height: 90)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            // Header at top
            VStack {
                pickerHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                Spacer()
            }
            
            // Floating action at bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    floatingProgramActionsButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 24)
                }
            }

        }
        .navigationBarBackButtonHidden(true)
        .task {
            await loadPrograms()
            await programContext.loadPendingInvites()
        }
        .sheet(isPresented: $showProgramActions) {
            ProgramActionsSheet(onDismiss: {
                // Refresh programs when sheet dismisses (in case user accepted an invite)
                Task {
                    await loadPrograms()
                    await programContext.loadPendingInvites()
                }
            })
            .environmentObject(programContext)
        }
        .sheet(isPresented: $showAccountMenu) {
            AccountMenuSheet(
                onSelectDestination: handleAccountSelection(_:),
                onSignOut: handleAccountSignOut
            )
            .environmentObject(programContext)
        }
        .navigationDestination(item: $programToOpen) { _ in
            AdminHomeView()
                .environmentObject(programContext)
        }
        .navigationDestination(item: $programToEdit) { _ in
            EditProgramInfoView()
                .environmentObject(programContext)
        }
        .navigationDestination(item: $accountDestination) { destination in
            switch destination {
            case .profile:
                MyProfileView()
            case .password:
                ChangePasswordView()
            case .appearance:
                AppearanceSettingsView()
            }
        }
        .alert("Delete Program?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                programToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let program = programToDelete {
                    Task {
                        await deleteProgram(program)
                    }
                }
            }
        } message: {
            if let program = programToDelete {
                Text("Are you sure you want to delete \"\(program.name)\"? This action cannot be undone.")
            }
        }
        .alert("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                programContext.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    private var pickerHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("My Programs")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(Color(.label))
                Text("Manage your fitness programs")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color(.secondaryLabel))
            }
            Spacer()
            Button {
                showAccountMenu = true
            } label: {
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ? Color(.white) : Color(.black))
                        .frame(width: 56, height: 56)
                    Image(systemName: "person.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Account settings")
        }
        .padding(.horizontal, 4)
    }
    
    private var floatingProgramActionsButton: some View {
        Button {
            showProgramActions = true
        } label: {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? Color(.white) : Color(.black))
                    .frame(width: 56, height: 56)
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .black : .white)

                // Badge for pending invites
                if pendingInvitesCount > 0 {
                    Text("\(pendingInvitesCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Circle().fill(Color.appRed))
                        .offset(x: 18, y: -18)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Program actions")
    }

    private func deleteProgram(_ program: APIClient.ProgramDTO) async {
        guard let token = programContext.authToken else { return }
        isDeleting = true
        do {
            try await programContext.deleteProgram(programId: program.id)
            programToDelete = nil
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
        isDeleting = false
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("No programs yet")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color(.label))
            Text("Create a program to get started.")
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }

    private func applyProgram(_ program: APIClient.ProgramDTO) {
        programContext.name = program.name
        programContext.status = (program.status ?? "Active")
        programContext.programId = program.id
        programContext.activeMembers = program.active_members ?? 0
        programContext.totalWorkouts = 0
        programContext.atRiskMembers = 0
        if let role = program.my_role {
            programContext.loggedInUserProgramRole = role
        }

        let formatterIn = DateFormatter()
        formatterIn.dateFormat = "yyyy-MM-dd"
        if let startString = program.start_date, let d = formatterIn.date(from: startString) {
            programContext.startDate = d
        }
        if let endString = program.end_date, let d = formatterIn.date(from: endString) {
            programContext.endDate = d
        }

        programContext.persistSession()

        // Load membership details to get the user's role in this program
        Task {
            await programContext.loadMembershipDetails()
            await programContext.loadLookupData()
        }
    }

    private func respondToInvite(program: APIClient.ProgramDTO, accept: Bool) async {
        do {
            let status = accept ? "active" : "removed"
            try await programContext.updateMembershipStatus(programId: program.id, status: status)
            await loadPrograms()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loadPrograms() async {
        guard let token = programContext.authToken, !token.isEmpty else {
            errorMessage = "Please log in to load programs."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let programs = try await APIClient.shared.fetchPrograms(token: token)
            await MainActor.run {
                programContext.programs = programs
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    private func handleAccountSelection(_ destination: AccountDestination) {
        showAccountMenu = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            accountDestination = destination
        }
    }

    private func handleAccountSignOut() {
        showAccountMenu = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showSignOutConfirmation = true
        }
    }
}

private enum AccountDestination: String, Identifiable {
    case profile
    case password
    case appearance

    var id: String { rawValue }
}

private struct AccountMenuSheet: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let onSelectDestination: (AccountDestination) -> Void
    let onSignOut: () -> Void

    private let privacyPolicyURL = URL(string: "https://vinaysankar2004.github.io/RaSi-Fiters/")!

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header

                        VStack(spacing: 12) {
                            Button {
                                onSelectDestination(.profile)
                            } label: {
                                ProfileRow(
                                    initials: programContext.loggedInUserInitials,
                                    name: programContext.loggedInUserName ?? "My Profile",
                                    username: programContext.loggedInUsername ?? ""
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                onSelectDestination(.password)
                            } label: {
                                AccountRow(
                                    icon: "lock.fill",
                                    color: .appOrange,
                                    title: "Change Password",
                                    subtitle: "Update your account password"
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                onSelectDestination(.appearance)
                            } label: {
                                AccountRow(
                                    icon: "paintpalette.fill",
                                    color: .appPurple,
                                    title: "Appearance",
                                    subtitle: "Choose light or dark mode"
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                dismiss()
                                openURL(privacyPolicyURL)
                            } label: {
                                AccountRow(
                                    icon: "doc.text",
                                    color: .appOrange,
                                    title: "Privacy Policy",
                                    subtitle: "Learn how we handle your data"
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                onSignOut()
                            } label: {
                                SignOutRow()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 48, height: 48)
                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(.secondaryLabel))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("My Account")
                    .font(.title3.weight(.bold))
                    .foregroundColor(Color(.label))
                Text("Manage your profile and preferences.")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Color(.secondaryLabel))
            }
            Spacer()
        }
    }
}

private struct ProfileRow: View {
    let initials: String
    let name: String
    let username: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.appOrangeLight)
                    .frame(width: 42, height: 42)
                Text(initials)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.appOrange)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(.label))
                Text(username.isEmpty ? "Update your personal info" : "@\(username)")
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
}

private struct AccountRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
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
}

private struct SignOutRow: View {
    var body: some View {
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
}

private struct ProgramCard: View {
    let program: APIClient.ProgramDTO
    let membershipStatus: String?
    let onAccept: (() -> Void)?
    let onDecline: (() -> Void)?

    private var normalizedStatus: String? {
        membershipStatus?.lowercased()
    }

    private var isInvited: Bool {
        normalizedStatus == "invited"
    }

    private var isRequested: Bool {
        normalizedStatus == "requested"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(program.name)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color(.label))
                Spacer()
                StatusPill(text: program.status ?? "Active", color: statusColor(program.status))
            }

            Text(dateRange(program))
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))

            if isInvited || isRequested {
                Text(isInvited ? "Invitation pending" : "Request pending approval")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Color(.secondaryLabel))
            } else {
                Text(membersSummary(program))
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }

            ProgressView(value: progressValue(program))
                .accentColor(statusColor(program.status))
                .scaleEffect(x: 1, y: 1.1, anchor: .center)

            if isInvited || isRequested {
                HStack(spacing: 10) {
                    if let onAccept, isInvited {
                        Button(action: onAccept) {
                            Text("Accept")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.appOrange))
                                .foregroundColor(.black)
                        }
                    }
                    if let onDecline {
                        Button(action: onDecline) {
                            Text(isRequested ? "Cancel request" : "Decline")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color(.systemGray5)))
                                .foregroundColor(Color(.label))
                        }
                    }
                    Spacer()
                }
            }

        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.appBackgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .adaptiveShadow(radius: 12, y: 6)
    }

    private var borderColor: Color {
        if isInvited || isRequested {
            return Color.appOrange.opacity(0.35)
        }
        return Color(.systemGray4).opacity(0.5)
    }

    private func dateRange(_ program: APIClient.ProgramDTO) -> String {
        let formatterIn = DateFormatter()
        formatterIn.dateFormat = "yyyy-MM-dd"
        let formatterOut = DateFormatter()
        formatterOut.dateFormat = "MMM d, yyyy"
        let start = program.start_date.flatMap { formatterIn.date(from: $0) }.map { formatterOut.string(from: $0) } ?? "Start"
        let end = program.end_date.flatMap { formatterIn.date(from: $0) }.map { formatterOut.string(from: $0) } ?? "End"
        return "\(start) – \(end)"
    }

    private func membersSummary(_ program: APIClient.ProgramDTO) -> String {
        let active = program.active_members ?? 0
        let total = program.total_members ?? 0
        return "\(active) active / \(total) total members"
    }

    private func progressValue(_ program: APIClient.ProgramDTO) -> Double {
        let total = program.total_members ?? 0
        guard total > 0 else { return 0 }
        let active = program.active_members ?? 0
        return min(max(Double(active) / Double(total), 0), 1)
    }

    private func statusColor(_ status: String?) -> Color {
        switch (status ?? "").lowercased() {
        case "completed": return .appGreen
        case "planned": return .appBlue
        case "active": return .appOrange
        default: return .appOrange
        }
    }
}

private struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.18))
            )
            .foregroundColor(color)
    }
}

// MARK: - Program Actions Sheet (Tabbed)

private struct ProgramActionsSheet: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let onDismiss: () -> Void
    
    @State private var selectedTab: Int = 0
    
    private var hasInvites: Bool {
        !programContext.pendingInvites.isEmpty
    }
    
    private var invitesTabLabel: String {
        programContext.isGlobalAdmin ? "All Invites" : "My Invites"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("", selection: $selectedTab) {
                    Label(invitesTabLabel, systemImage: "envelope.fill")
                        .tag(0)
                    Label("Create", systemImage: "plus")
                        .tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Tab content
                TabView(selection: $selectedTab) {
                    InvitesTabView(onAccepted: {
                        dismiss()
                        onDismiss()
                    })
                    .tag(0)
                    
                    CreateProgramTabView(onCreated: {
                        dismiss()
                        onDismiss()
                    })
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(
                AppGradient.sheetBackground(for: colorScheme)
                    .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                        onDismiss()
                    }
                    .foregroundColor(Color(.label))
                }
            }
        }
        .onAppear {
            // Default to invites tab if there are pending invites
            if hasInvites {
                selectedTab = 0
            } else {
                selectedTab = 1
            }
        }
    }
}

// MARK: - Invites Tab View

private struct InvitesTabView: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.colorScheme) private var colorScheme
    
    let onAccepted: () -> Void
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var inviteToDecline: APIClient.PendingInviteDTO?
    @State private var showDeclineConfirmation = false
    @State private var blockFutureInvites = false
    
    private var isGlobalAdmin: Bool {
        programContext.isGlobalAdmin
    }
    
    private var headerTitle: String {
        isGlobalAdmin ? "All Program Invitations" : "Program Invitations"
    }
    
    private var headerSubtitle: String {
        isGlobalAdmin ? "Manage invites across all programs" : "Accept invitations to join programs"
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(headerTitle)
                            .font(.title2.weight(.bold))
                            .foregroundColor(Color(.label))
                        Text(headerSubtitle)
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Content
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.top, 40)
                    } else if programContext.pendingInvites.isEmpty {
                        emptyState
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                    } else {
                        // Invites list
                        if isGlobalAdmin {
                            adminInvitesList
                        } else {
                            standardInvitesList
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            
            if showDeclineConfirmation, let invite = inviteToDecline {
                DeclineInviteDialog(
                    programName: invite.program_name ?? "this program",
                    blockFutureInvites: $blockFutureInvites,
                    onDecline: {
                        Task {
                            await respondToInvite(invite, action: "decline", blockFuture: blockFutureInvites)
                        }
                    },
                    onCancel: {
                        inviteToDecline = nil
                        blockFutureInvites = false
                        showDeclineConfirmation = false
                    }
                )
                .transition(.opacity)
            }
        }
        .task {
            await refreshInvites()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.open")
                .font(.system(size: 40))
                .foregroundColor(Color(.tertiaryLabel))
            Text("No pending invitations")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color(.label))
            Text(isGlobalAdmin ? "There are no pending invites in the system." : "You don't have any program invitations right now.")
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
    
    private var standardInvitesList: some View {
        VStack(spacing: 12) {
            ForEach(programContext.pendingInvites) { invite in
                InviteCard(
                    invite: invite,
                    isAdmin: false,
                    onAccept: {
                        Task { await respondToInvite(invite, action: "accept") }
                    },
                    onDecline: {
                        inviteToDecline = invite
                        showDeclineConfirmation = true
                    },
                    onRevoke: nil
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var adminInvitesList: some View {
        VStack(spacing: 16) {
            // Group invites by program
            let groupedInvites = Dictionary(grouping: programContext.pendingInvites) { $0.program_name ?? "Unknown Program" }
            let sortedKeys = groupedInvites.keys.sorted()
            
            ForEach(sortedKeys, id: \.self) { programName in
                if let invites = groupedInvites[programName] {
                    VStack(alignment: .leading, spacing: 10) {
                        // Program header
                        Text(programName)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(Color(.label))
                            .padding(.horizontal, 20)
                        
                        // Invites for this program
                        ForEach(invites) { invite in
                            InviteCard(
                                invite: invite,
                                isAdmin: true,
                                onAccept: {
                                    Task { await respondToInvite(invite, action: "accept") }
                                },
                                onDecline: {
                                    inviteToDecline = invite
                                    showDeclineConfirmation = true
                                },
                                onRevoke: {
                                    Task { await respondToInvite(invite, action: "revoke") }
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .alert("Unable to update invitation", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private func refreshInvites() async {
        isLoading = true
        errorMessage = nil
        await programContext.loadPendingInvites()
        isLoading = false
    }
    
    private func respondToInvite(_ invite: APIClient.PendingInviteDTO, action: String, blockFuture: Bool = false) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await programContext.respondToInvite(
                inviteId: invite.invite_id,
                action: action,
                blockFuture: blockFuture
            )
            
            // If accepted, trigger the callback to dismiss and refresh
            if action == "accept" {
                onAccepted()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        inviteToDecline = nil
        blockFutureInvites = false
        showDeclineConfirmation = false
        isLoading = false
    }
}

private struct DeclineInviteDialog: View {
    let programName: String
    @Binding var blockFutureInvites: Bool
    let onDecline: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Text("Decline invitation?")
                        .font(.title3.weight(.bold))
                        .foregroundColor(Color(.label))
                    Text(programName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                
                Button {
                    blockFutureInvites.toggle()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(blockFutureInvites ? Color.appOrange : Color(.tertiaryLabel), lineWidth: 1.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(blockFutureInvites ? Color.appOrange.opacity(0.15) : Color.clear)
                                )
                                .frame(width: 22, height: 22)
                            if blockFutureInvites {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.appOrange)
                            }
                        }
                        Text("Block future invites")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(.label))
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(blockFutureInvites ? Color.appOrange.opacity(0.6) : Color.clear, lineWidth: 1)
                    )
                }
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                
                VStack(spacing: 10) {
                    Button(role: .destructive) {
                        onDecline()
                    } label: {
                        Text("Decline")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.appRed)
                            )
                    }
                    
                    Button {
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(Color(.label))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.systemGray5))
                            )
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 12)
            .padding(.horizontal, 28)
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Invite Card

private struct InviteCard: View {
    let invite: APIClient.PendingInviteDTO
    let isAdmin: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onRevoke: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var statusColor: Color {
        switch (invite.program_status ?? "").lowercased() {
        case "completed": return .appGreen
        case "planned": return .appBlue
        case "active": return .appOrange
        default: return .appOrange
        }
    }
    
    private var dateRangeText: String {
        let formatterIn = DateFormatter()
        formatterIn.dateFormat = "yyyy-MM-dd"
        let formatterOut = DateFormatter()
        formatterOut.dateFormat = "MMM d, yyyy"
        
        let start = invite.program_start_date.flatMap { formatterIn.date(from: $0) }.map { formatterOut.string(from: $0) } ?? "Start"
        let end = invite.program_end_date.flatMap { formatterIn.date(from: $0) }.map { formatterOut.string(from: $0) } ?? "End"
        return "\(start) – \(end)"
    }
    
    private var invitedAtText: String {
        guard let invitedAt = invite.invited_at else { return "" }
        
        // Try parsing ISO8601 format
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d, yyyy"
        
        if let date = isoFormatter.date(from: invitedAt) {
            return "Invited on \(displayFormatter.string(from: date))"
        }
        
        // Fallback: try without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: invitedAt) {
            return "Invited on \(displayFormatter.string(from: date))"
        }
        
        return "Invited recently"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack {
                if !isAdmin {
                    Text(invite.program_name ?? "Unknown Program")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color(.label))
                }
                Spacer()
                if let status = invite.program_status {
                    StatusPill(text: status, color: statusColor)
                }
            }
            
            // Admin view: Show who the invite is TO
            if isAdmin, let inviteeName = invite.invited_member_name ?? invite.invited_username {
                HStack(spacing: 4) {
                    Text("To:")
                        .foregroundColor(Color(.secondaryLabel))
                    Text(inviteeName)
                        .foregroundColor(Color(.label))
                    if let username = invite.invited_username, invite.invited_member_name != nil {
                        Text("@\(username)")
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                .font(.subheadline.weight(.medium))
            }
            
            // Date range
            Text(dateRangeText)
                .font(.subheadline)
                .foregroundColor(Color(.secondaryLabel))
            
            // Invited by and date
            HStack {
                if let invitedBy = invite.invited_by_name {
                    Text("Invited by \(invitedBy)")
                        .font(.footnote)
                        .foregroundColor(Color(.tertiaryLabel))
                }
                Spacer()
                Text(invitedAtText)
                    .font(.footnote)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            
            // Action buttons
            HStack(spacing: 10) {
                Button(action: onAccept) {
                    Text("Accept")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.appOrange))
                        .foregroundColor(.black)
                }
                
                Button(action: onDecline) {
                    Text("Decline")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color(.systemGray5)))
                        .foregroundColor(Color(.label))
                }
                
                if isAdmin, let onRevoke {
                    Button(action: onRevoke) {
                        Text("Revoke")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Capsule().stroke(Color.appRed, lineWidth: 1.5))
                            .foregroundColor(.appRed)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.appBackgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appOrange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Create Program Tab View

private struct CreateProgramTabView: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.colorScheme) private var colorScheme
    
    let onCreated: () -> Void
    
    @State private var programName: String = ""
    @State private var status: String = "planned"
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    
    private let statusOptions = ["planned", "active", "completed"]
    
    private var isFormValid: Bool {
        !programName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var accentColor: Color {
        Color.appOrange
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Program")
                        .font(.title2.weight(.bold))
                        .foregroundColor(Color(.label))
                    Text("Set up a new fitness program.")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                // Form fields
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Program name")
                            .font(.subheadline.weight(.semibold))
                        TextField("e.g. Summer 2026 Challenge", text: $programName)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Status")
                            .font(.subheadline.weight(.semibold))
                        Menu {
                            ForEach(statusOptions, id: \.self) { option in
                                Button(option.capitalized) { status = option }
                            }
                        } label: {
                            HStack {
                                Text(status.capitalized)
                                    .foregroundColor(Color(.label))
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Start date")
                            .font(.subheadline.weight(.semibold))
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("End date")
                            .font(.subheadline.weight(.semibold))
                        DatePicker("", selection: $endDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.appRed)
                        .font(.footnote.weight(.semibold))
                }
                
                Button(action: { Task { await save() } }) {
                    if isSaving {
                        ProgressView().tint(colorScheme == .dark ? .black : .white)
                    } else {
                        Text("Create Program")
                            .font(.headline.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? accentColor : Color(.systemGray3))
                .foregroundColor(.black)
                .cornerRadius(14)
                .disabled(!isFormValid || isSaving)
                
                Spacer(minLength: 40)
            }
            .padding(20)
        }
        .alert("Program Created", isPresented: $showSuccessAlert) {
            Button("OK") {
                onCreated()
            }
        } message: {
            Text("Your new program has been created successfully.")
        }
    }
    
    private func save() async {
        isSaving = true
        errorMessage = nil
        
        do {
            try await programContext.createProgram(
                name: programName.trimmingCharacters(in: .whitespacesAndNewlines),
                status: status,
                startDate: startDate,
                endDate: endDate
            )
            showSuccessAlert = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSaving = false
    }
}

#Preview {
    NavigationStack {
        ProgramPickerView()
            .environmentObject(ProgramContext())
    }
}
