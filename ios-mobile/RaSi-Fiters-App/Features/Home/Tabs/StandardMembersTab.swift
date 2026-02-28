import SwiftUI

// MARK: - Standard Members Tab (for non-admin users)

struct StandardMembersTab: View {
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
        .onChange(of: programContext.programId) { _, _ in
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
