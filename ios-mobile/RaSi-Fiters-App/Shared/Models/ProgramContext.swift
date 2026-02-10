import Foundation
import Combine

/// Shared program context so all tabs and queries know the active program.
final class ProgramContext: ObservableObject {
    @Published var authToken: String?
    @Published var refreshToken: String? = nil
    @Published var name: String
    @Published var status: String
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var adminName: String
    @Published var activeMembers: Int
    @Published var atRiskMembers: Int
    @Published var totalLogsThisPeriod: Int
    @Published var totalWorkouts: Int
    @Published var totalDurationHours: Int
    @Published var averageDurationMinutes: Int
    @Published var logsChangePct: Double
    @Published var durationChangePct: Double
    @Published var avgDurationChangePct: Double
    @Published var timelinePoints: [AnalyticsSummary.TimelinePoint]
    @Published var distributionByDay: [String: AnalyticsSummary.DayDistribution]
    @Published var distributionByDayCounts: [String: Int]
    @Published var topPerformers: [AnalyticsSummary.TopPerformer]
    @Published var topWorkoutTypes: [AnalyticsSummary.TopWorkoutType]
    @Published var programId: String?
    @Published var programs: [APIClient.ProgramDTO]
    @Published var mtdParticipation: APIClient.MTDParticipationDTO?
    @Published var totalWorkoutsMTD: Int
    @Published var totalWorkoutsChangePct: Double
    @Published var totalDurationHoursMTD: Double
    @Published var totalDurationChangePct: Double
    @Published var avgDurationMinutesMTD: Int
    @Published var avgDurationChangePctMTD: Double
    @Published var activityTimeline: [APIClient.ActivityTimelinePoint]
    @Published var activityTimelineLabel: String
    @Published var activityTimelineDailyAverage: Double
    @Published var healthTimeline: [APIClient.HealthTimelinePoint]
    @Published var healthTimelineDailyAverageSleep: Double
    @Published var healthTimelineDailyAverageFood: Double
    @Published var workoutTypes: [APIClient.WorkoutTypeDTO]
    @Published var workoutTypesTotal: Int
    @Published var workoutTypeMostPopular: APIClient.WorkoutTypeMostPopularDTO?
    @Published var workoutTypeLongestDuration: APIClient.WorkoutTypeLongestDurationDTO?
    @Published var workoutTypeHighestParticipation: APIClient.WorkoutTypeHighestParticipationDTO?
    @Published var members: [APIClient.MemberDTO]
    @Published var membersProgramId: String?
    @Published var workouts: [APIClient.WorkoutDTO]
    @Published var programWorkouts: [APIClient.ProgramWorkoutDTO] = []
    @Published var lastFetchedPeriod: String?
    @Published var memberMetrics: [APIClient.MemberMetricsDTO] = []
    @Published var memberMetricsTotal: Int = 0
    @Published var memberMetricsFiltered: Int = 0
    @Published var memberMetricsSort: String = "workouts"
    @Published var memberMetricsDirection: String = "desc"
    @Published var memberMetricsRangeStart: Date?
    @Published var memberMetricsRangeEnd: Date?
    @Published var globalRole: String = "standard"
    @Published var selectedMemberOverview: APIClient.MemberMetricsDTO?
    @Published var memberHistory: [APIClient.MemberHistoryPoint] = []
    @Published var memberHistoryLabel: String = ""
    @Published var memberHistoryDailyAverage: Double = 0
    @Published var memberHistoryStartDate: Date = Date()
    @Published var memberHistoryEndDate: Date = Date()
    @Published var memberStreaks: APIClient.MemberStreaksResponse?
    @Published var memberRecent: [APIClient.MemberRecentWorkoutsResponse.Item] = []
    @Published var memberHealthLogs: [APIClient.MemberHealthLogResponse.Item] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Logged-in user info
    @Published var loggedInUserId: String?
    @Published var loggedInUserName: String?
    @Published var loggedInUsername: String?
    @Published var loggedInUserProgramRole: String = "member" // "admin" or "member" in current program
    
    // Membership details for program management
    @Published var membershipDetails: [APIClient.MembershipDetailDTO] = []
    
    // Pending program invites
    @Published var pendingInvites: [APIClient.PendingInviteDTO] = []

    // Notifications (queued modals)
    @Published var notificationQueue: [APIClient.NotificationDTO] = []

    private var notificationStreamClient: NotificationStreamClient?
    private var notificationIds: Set<String> = []
    private let notificationDateFormatter = ISO8601DateFormatter()

    init(
        authToken: String? = nil,
        name: String = "Program 1",
        status: String = "Active",
        startDate: Date = Date(timeIntervalSinceNow: -180 * 24 * 60 * 60),
        endDate: Date = Calendar.current.date(byAdding: .day, value: 180, to: Date()) ?? Date(),
        adminName: String = "Admin",
        activeMembers: Int = 35,
        atRiskMembers: Int = 2,
        totalLogsThisPeriod: Int = 0,
        totalWorkouts: Int = 0,
        totalDurationHours: Int = 0,
        averageDurationMinutes: Int = 0,
        logsChangePct: Double = 0,
        durationChangePct: Double = 0,
        avgDurationChangePct: Double = 0,
        timelinePoints: [AnalyticsSummary.TimelinePoint] = [],
        distributionByDay: [String: AnalyticsSummary.DayDistribution] = [:],
        distributionByDayCounts: [String: Int] = [:],
        topPerformers: [AnalyticsSummary.TopPerformer] = [],
        topWorkoutTypes: [AnalyticsSummary.TopWorkoutType] = [],
        programId: String? = nil,
        programs: [APIClient.ProgramDTO] = [],
        mtdParticipation: APIClient.MTDParticipationDTO? = nil,
        totalWorkoutsMTD: Int = 0,
        totalWorkoutsChangePct: Double = 0,
        totalDurationHoursMTD: Double = 0,
        totalDurationChangePct: Double = 0,
        avgDurationMinutesMTD: Int = 0,
        avgDurationChangePctMTD: Double = 0,
        activityTimeline: [APIClient.ActivityTimelinePoint] = [],
        activityTimelineLabel: String = "",
        activityTimelineDailyAverage: Double = 0,
        healthTimeline: [APIClient.HealthTimelinePoint] = [],
        healthTimelineDailyAverageSleep: Double = 0,
        healthTimelineDailyAverageFood: Double = 0,
        workoutTypes: [APIClient.WorkoutTypeDTO] = [],
        workoutTypesTotal: Int = 0,
        workoutTypeMostPopular: APIClient.WorkoutTypeMostPopularDTO? = nil,
        workoutTypeLongestDuration: APIClient.WorkoutTypeLongestDurationDTO? = nil,
        workoutTypeHighestParticipation: APIClient.WorkoutTypeHighestParticipationDTO? = nil,
        members: [APIClient.MemberDTO] = [],
        membersProgramId: String? = nil,
        workouts: [APIClient.WorkoutDTO] = [],
        lastFetchedPeriod: String? = nil,
        memberHistoryLabel: String = "",
        memberHistoryDailyAverage: Double = 0,
        memberHistoryStartDate: Date = Date(),
        memberHistoryEndDate: Date = Date()
    ) {
        self.authToken = authToken
        self.name = name
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.adminName = adminName
        self.activeMembers = activeMembers
        self.atRiskMembers = atRiskMembers
        self.totalLogsThisPeriod = totalLogsThisPeriod
        self.totalWorkouts = totalWorkouts
        self.totalDurationHours = totalDurationHours
        self.averageDurationMinutes = averageDurationMinutes
        self.logsChangePct = logsChangePct
        self.durationChangePct = durationChangePct
        self.avgDurationChangePct = avgDurationChangePct
        self.timelinePoints = timelinePoints
        self.distributionByDay = distributionByDay
        self.distributionByDayCounts = distributionByDayCounts
        self.topPerformers = topPerformers
        self.topWorkoutTypes = topWorkoutTypes
        self.programId = programId
        self.programs = programs
        self.mtdParticipation = mtdParticipation
        self.totalWorkoutsMTD = totalWorkoutsMTD
        self.totalWorkoutsChangePct = totalWorkoutsChangePct
        self.totalDurationHoursMTD = totalDurationHoursMTD
        self.totalDurationChangePct = totalDurationChangePct
        self.avgDurationMinutesMTD = avgDurationMinutesMTD
        self.avgDurationChangePctMTD = avgDurationChangePctMTD
        self.activityTimeline = activityTimeline
        self.activityTimelineLabel = activityTimelineLabel
        self.activityTimelineDailyAverage = activityTimelineDailyAverage
        self.healthTimeline = healthTimeline
        self.healthTimelineDailyAverageSleep = healthTimelineDailyAverageSleep
        self.healthTimelineDailyAverageFood = healthTimelineDailyAverageFood
        self.workoutTypes = workoutTypes
        self.workoutTypesTotal = workoutTypesTotal
        self.workoutTypeMostPopular = workoutTypeMostPopular
        self.workoutTypeLongestDuration = workoutTypeLongestDuration
        self.workoutTypeHighestParticipation = workoutTypeHighestParticipation
        self.members = members
        self.membersProgramId = membersProgramId
        self.workouts = workouts
        self.lastFetchedPeriod = lastFetchedPeriod
        self.memberHistoryLabel = memberHistoryLabel
        self.memberHistoryDailyAverage = memberHistoryDailyAverage
        self.memberHistoryStartDate = memberHistoryStartDate
        self.memberHistoryEndDate = memberHistoryEndDate

        restorePersistedSession()
        configureAPIClientHandlers()
    }

    var dateRangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: startDate)
        formatter.dateFormat = "MMM d, yyyy"
        let end = formatter.string(from: endDate)
        return "\(start) – \(end)"
    }

    var totalDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    var elapsedDays: Int {
        let today = Date()
        guard today > startDate else { return 0 }
        return min(Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0, totalDays)
    }

    var remainingDays: Int {
        max(totalDays - elapsedDays, 0)
    }

    var completionPercent: Int {
        guard totalDays > 0 else { return 0 }
        return Int(round((Double(elapsedDays) / Double(totalDays)) * 100))
    }

    var adminInitials: String {
        adminName
            .split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map { String($0).uppercased() }
            .joined()
    }

    func apply(program: APIClient.ProgramDTO) {
        name = program.name
        status = program.status ?? "Active"
        activeMembers = program.active_members ?? 0
        atRiskMembers = 0
        programId = program.id
        if let role = program.my_role {
            loggedInUserProgramRole = role
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let start = program.start_date, let d = formatter.date(from: start) {
            startDate = d
        }
        if let end = program.end_date, let d = formatter.date(from: end) {
            endDate = d
        }
    }

    @MainActor
    func loadLookupData() async {
        print("[ProgramContext] loadLookupData called - programId: \(programId ?? "nil")")
        guard let token = authToken, !token.isEmpty else { 
            print("[ProgramContext] loadLookupData: No auth token")
            return 
        }
        do {
            let membersData: [APIClient.MemberDTO]
            if let pid = programId {
                print("[ProgramContext] loadLookupData: Fetching program members for programId=\(pid)")
                membersData = try await APIClient.shared.fetchProgramMembers(token: token, programId: pid)
            } else {
                print("[ProgramContext] loadLookupData: Fetching all members (no programId)")
                membersData = try await APIClient.shared.fetchMembers(token: token)
            }
            let workoutsData = try await APIClient.shared.fetchWorkouts(token: token)
            let programsData = try await APIClient.shared.fetchPrograms(token: token)
            members = membersData
            membersProgramId = programId
            workouts = workoutsData
            programs = programsData
            if let pid = programId, let updated = programsData.first(where: { $0.id == pid }) {
                apply(program: updated)
                persistSession()
            } else if programId != nil {
                programId = nil
                name = ""
                status = ""
                loggedInUserProgramRole = "member"
                membershipDetails = []
                persistSession()
            }
            print("[ProgramContext] loadLookupData: Loaded \(membersData.count) members, \(workoutsData.count) workouts, \(programsData.count) programs")
        } catch {
            // Do not fail hard; just log error
            errorMessage = error.localizedDescription
            print("[ProgramContext] loadLookupData error: \(error.localizedDescription)")
        }
    }

    @MainActor
    func loadMemberMetrics(
        search: String = "",
        sort: String = "workouts",
        direction: String = "desc",
        filters: [String: String] = [:],
        dateRange: (start: Date?, end: Date?) = (nil, nil)
    ) async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for member metrics."
            return
        }
        do {
            let resp = try await APIClient.shared.fetchMemberMetrics(
                token: token,
                programId: pid,
                search: search,
                sort: sort,
                direction: direction,
                filters: filters
            )
            memberMetrics = resp.members
            memberMetricsTotal = resp.total
            memberMetricsFiltered = resp.filtered
            memberMetricsSort = resp.sort
            memberMetricsDirection = resp.direction
            if let dr = resp.date_range {
                memberMetricsRangeStart = dr.start.flatMap { Self.dateFromString($0) }
                memberMetricsRangeEnd = dr.end.flatMap { Self.dateFromString($0) }
            } else {
                memberMetricsRangeStart = dateRange.start
                memberMetricsRangeEnd = dateRange.end
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadMemberOverview(
        memberId: String,
        filters: [String: String] = [:],
        dateRange: (start: Date?, end: Date?) = (nil, nil)
    ) async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for member metrics."
            return
        }
        do {
            let resp = try await APIClient.shared.fetchMemberMetrics(
                token: token,
                programId: pid,
                search: nil,
                sort: nil,
                direction: nil,
                memberId: memberId,
                filters: filters
            )
            selectedMemberOverview = resp.members.first
            if let dr = resp.date_range {
                memberMetricsRangeStart = dr.start.flatMap { Self.dateFromString($0) }
                memberMetricsRangeEnd = dr.end.flatMap { Self.dateFromString($0) }
            } else {
                memberMetricsRangeStart = dateRange.start
                memberMetricsRangeEnd = dateRange.end
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadMemberHistory(memberId: String, period: String) async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for member history."
            return
        }
        do {
            let resp = try await APIClient.shared.fetchMemberHistory(
                token: token,
                programId: pid,
                memberId: memberId,
                period: period
            )
            memberHistory = resp.buckets
            memberHistoryLabel = resp.label
            memberHistoryDailyAverage = resp.daily_average
            memberHistoryStartDate = Self.dateFromString(resp.start) ?? Date()
            memberHistoryEndDate = Self.dateFromString(resp.end) ?? Date()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadMemberStreaks(memberId: String) async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for member streaks."
            return
        }
        do {
            let resp = try await APIClient.shared.fetchMemberStreaks(
                token: token,
                programId: pid,
                memberId: memberId
            )
            memberStreaks = resp
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadMemberRecent(
        memberId: String,
        limit: Int = 1000,
        startDate: String? = nil,
        endDate: String? = nil,
        sortBy: String? = nil,
        sortDir: String? = nil
    ) async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for member recent."
            return
        }
        do {
            let resp = try await APIClient.shared.fetchMemberRecentWorkouts(
                token: token,
                programId: pid,
                memberId: memberId,
                limit: limit,
                startDate: startDate,
                endDate: endDate,
                sortBy: sortBy,
                sortDir: sortDir
            )
            memberRecent = resp.items
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadMemberHealthLogs(
        memberId: String,
        limit: Int = 1000,
        startDate: String? = nil,
        endDate: String? = nil,
        sortBy: String? = nil,
        sortDir: String? = nil
    ) async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for daily health logs."
            return
        }
        do {
            let resp = try await APIClient.shared.fetchMemberHealthLogs(
                token: token,
                programId: pid,
                memberId: memberId,
                limit: limit,
                startDate: startDate,
                endDate: endDate,
                sortBy: sortBy,
                sortDir: sortDir
            )
            memberHealthLogs = resp.items
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func deleteWorkoutLog(memberId: String, workoutName: String, date: String) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }
        guard let pid = programId else {
            throw APIError(message: "No program selected")
        }
        try await APIClient.shared.deleteWorkoutLog(
            token: token,
            programId: pid,
            memberId: memberId,
            workoutName: workoutName,
            date: date
        )
    }

    @MainActor
    func updateWorkoutLog(memberName: String?, workoutName: String, date: String, durationMinutes: Int) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }
        guard let pid = programId else {
            throw APIError(message: "No program selected")
        }
        try await APIClient.shared.updateWorkoutLog(
            token: token,
            programId: pid,
            memberName: memberName,
            workoutName: workoutName,
            date: date,
            duration: durationMinutes
        )
    }

    @MainActor
    func updateDailyHealthLog(
        memberId: String,
        logDate: String,
        sleepHours: Double?,
        foodQuality: Int?
    ) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }
        guard let pid = programId else {
            throw APIError(message: "No program selected")
        }
        try await APIClient.shared.updateDailyHealthLog(
            token: token,
            programId: pid,
            memberId: memberId,
            logDate: logDate,
            sleepHours: sleepHours,
            foodQuality: foodQuality
        )
    }

    @MainActor
    func deleteDailyHealthLog(memberId: String, logDate: String) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }
        guard let pid = programId else {
            throw APIError(message: "No program selected")
        }
        try await APIClient.shared.deleteDailyHealthLog(
            token: token,
            programId: pid,
            memberId: memberId,
            logDate: logDate
        )
    }

    private static func dateFromString(_ s: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: s)
    }

    @MainActor
    func loadMTDParticipation() async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for MTD participation."
            return
        }
        do {
            let data = try await APIClient.shared.fetchMTDParticipation(token: token, programId: pid)
            mtdParticipation = data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadTotalWorkoutsMTD() async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for total workouts."
            return
        }
        do {
            let data = try await APIClient.shared.fetchTotalWorkoutsMTD(token: token, programId: pid)
            totalWorkoutsMTD = data.total_workouts
            totalWorkoutsChangePct = data.change_pct
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadTotalDurationMTD() async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for total duration."
            return
        }
        do {
            let data = try await APIClient.shared.fetchTotalDurationMTD(token: token, programId: pid)
            let hours = Double(data.total_minutes) / 60.0
            totalDurationHoursMTD = (hours * 10).rounded() / 10.0
            totalDurationChangePct = data.change_pct
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadAvgDurationMTD() async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for avg duration."
            return
        }
        do {
            let data = try await APIClient.shared.fetchAvgDurationMTD(token: token, programId: pid)
            avgDurationMinutesMTD = data.avg_minutes
            avgDurationChangePctMTD = data.change_pct
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadActivityTimeline(period: String) async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for activity timeline."
            return
        }
        do {
            let resp = try await APIClient.shared.fetchActivityTimeline(token: token, period: period, programId: pid)
            activityTimeline = resp.buckets
            activityTimelineLabel = resp.label
            activityTimelineDailyAverage = resp.daily_average
            errorMessage = nil  // Clear error on success
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadHealthTimeline(period: String, memberId: String? = nil) async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for health timeline."
            return
        }
        do {
            let resp = try await APIClient.shared.fetchHealthTimeline(
                token: token,
                period: period,
                programId: pid,
                memberId: memberId
            )
            healthTimeline = resp.buckets
            healthTimelineDailyAverageSleep = resp.daily_average_sleep
            healthTimelineDailyAverageFood = resp.daily_average_food
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadAnalytics(period: String) async {
        guard let token = authToken, !token.isEmpty else {
            errorMessage = "No auth token set. Log in to load analytics."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let summary = try await APIClient.shared.fetchAnalyticsSummary(token: token, period: period, programId: programId)
            totalLogsThisPeriod = summary.totals.logs
            totalWorkouts = summary.totals.logs
            totalDurationHours = Int(round(Double(summary.totals.duration_minutes) / 60.0))
            averageDurationMinutes = summary.totals.avg_duration_minutes
            logsChangePct = summary.totals.logs_change_pct
            durationChangePct = summary.totals.duration_change_pct
            avgDurationChangePct = summary.totals.avg_duration_change_pct
            atRiskMembers = summary.members.at_risk
            timelinePoints = summary.timeline
            distributionByDay = summary.distribution_by_day
            topPerformers = summary.top_performers
            topWorkoutTypes = summary.top_workout_types
            lastFetchedPeriod = period
            distributionByDayCounts = summary.distribution_by_day.mapValues { $0.workouts }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    func loadDistributionByDay() async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for distribution."
            return
        }
        do {
            let data = try await APIClient.shared.fetchDistributionByDay(token: token, programId: pid)
            distributionByDayCounts = [
                "Sunday": data.Sunday,
                "Monday": data.Monday,
                "Tuesday": data.Tuesday,
                "Wednesday": data.Wednesday,
                "Thursday": data.Thursday,
                "Friday": data.Friday,
                "Saturday": data.Saturday
            ]
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadWorkoutTypes(memberId: String? = nil, limit: Int = 100) async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for workout types."
            return
        }
        do {
            let data = try await APIClient.shared.fetchWorkoutTypes(token: token, programId: pid, memberId: memberId, limit: limit)
            workoutTypes = data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadWorkoutTypesTotal(memberId: String? = nil) async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for workout types total."
            return
        }
        do {
            let data = try await APIClient.shared.fetchWorkoutTypesTotal(token: token, programId: pid, memberId: memberId)
            workoutTypesTotal = data.total_types
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadWorkoutTypeMostPopular(memberId: String? = nil) async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for most popular workout type."
            return
        }
        do {
            let data = try await APIClient.shared.fetchWorkoutTypeMostPopular(token: token, programId: pid, memberId: memberId)
            workoutTypeMostPopular = data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadWorkoutTypeLongestDuration(memberId: String? = nil) async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for longest duration workout type."
            return
        }
        do {
            let data = try await APIClient.shared.fetchWorkoutTypeLongestDuration(token: token, programId: pid, memberId: memberId)
            workoutTypeLongestDuration = data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadWorkoutTypeHighestParticipation(memberId: String? = nil) async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for highest participation workout type."
            return
        }
        do {
            let data = try await APIClient.shared.fetchWorkoutTypeHighestParticipation(token: token, programId: pid, memberId: memberId)
            workoutTypeHighestParticipation = data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Role & Permission Helpers

    var isGlobalAdmin: Bool {
        globalRole == "global_admin"
    }

    var isProgramAdmin: Bool {
        loggedInUserProgramRole == "admin" || isGlobalAdmin
    }

    var canEditProgramData: Bool {
        isProgramAdmin
    }

    var loggedInUserInitials: String {
        guard let name = loggedInUserName else { return "?" }
        return name
            .split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map { String($0).uppercased() }
            .joined()
    }

    // MARK: - Program Management

    @MainActor
    func updateProgram(name: String?, status: String?, startDate: Date?, endDate: Date?) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }
        guard let pid = programId else {
            throw APIError(message: "No program selected")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let startStr = startDate.map { formatter.string(from: $0) }
        let endStr = endDate.map { formatter.string(from: $0) }

        let response = try await APIClient.shared.updateProgram(
            token: token,
            programId: pid,
            name: name,
            status: status,
            startDate: startStr,
            endDate: endStr
        )

        // Update local state
        if let newName = name { self.name = newName }
        if let newStatus = status { self.status = newStatus }
        if let newStart = startDate { self.startDate = newStart }
        if let newEnd = endDate { self.endDate = newEnd }
    }

    // MARK: - Membership Management

    @MainActor
    func loadMembershipDetails() async {
        print("[ProgramContext] loadMembershipDetails called")
        guard let token = authToken, !token.isEmpty else { 
            print("[ProgramContext] loadMembershipDetails: No auth token")
            return 
        }
        guard let pid = programId else {
            errorMessage = "No program selected for membership details."
            print("[ProgramContext] loadMembershipDetails: No program selected")
            return
        }
        do {
            let data = try await APIClient.shared.fetchMembershipDetails(token: token, programId: pid)
            let activeData = data.filter { $0.is_active }
            membershipDetails = activeData
            print("[ProgramContext] loadMembershipDetails: Received \(activeData.count) members")

            // Update logged-in user's program role
            if let userId = loggedInUserId,
               let myMembership = activeData.first(where: { $0.member_id == userId }) {
                print("[ProgramContext] loadMembershipDetails: Found my membership - program_role: '\(myMembership.program_role)'")
                loggedInUserProgramRole = myMembership.program_role
                persistSession()
                print("[ProgramContext] loadMembershipDetails: Updated loggedInUserProgramRole to '\(loggedInUserProgramRole)'")
            } else {
                print("[ProgramContext] loadMembershipDetails: Could not find my membership (userId: \(loggedInUserId ?? "nil"))")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("[ProgramContext] loadMembershipDetails error: \(error.localizedDescription)")
        }
    }

    @MainActor
    func updateMembership(memberId: String, role: String?, isActive: Bool?, joinedAt: Date?) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }
        guard let pid = programId else {
            throw APIError(message: "No program selected")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let joinedStr = joinedAt.map { formatter.string(from: $0) }

        _ = try await APIClient.shared.updateMembership(
            token: token,
            programId: pid,
            memberId: memberId,
            role: role,
            status: nil,
            isActive: isActive,
            joinedAt: joinedStr
        )

        // Refresh membership details
        await loadMembershipDetails()
        await loadLookupData()
    }

    @MainActor
    func removeMember(memberId: String) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }
        guard let pid = programId else {
            throw APIError(message: "No program selected")
        }

        try await APIClient.shared.removeMemberFromProgram(token: token, programId: pid, memberId: memberId)

        // Refresh data
        await loadMembershipDetails()
        await loadLookupData()
    }

    @MainActor
    func updateMembershipStatus(programId: String, status: String) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }
        guard let memberId = loggedInUserId else {
            throw APIError(message: "No member selected")
        }

        _ = try await APIClient.shared.updateMembership(
            token: token,
            programId: programId,
            memberId: memberId,
            role: nil,
            status: status,
            isActive: nil,
            joinedAt: nil
        )
    }

    // MARK: - Member Profile Management

    @MainActor
    func updateMemberProfile(memberId: String, firstName: String?, lastName: String?, gender: String?) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }

        _ = try await APIClient.shared.updateMemberProfile(
            token: token,
            memberId: memberId,
            firstName: firstName,
            lastName: lastName,
            gender: gender
        )

        // Update local state if this is the logged-in user
        if memberId == loggedInUserId {
            if let first = firstName, let last = lastName {
                loggedInUserName = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
            } else if let first = firstName {
                let currentLast = loggedInUserName?.split(separator: " ").dropFirst().joined(separator: " ") ?? ""
                loggedInUserName = "\(first) \(currentLast)".trimmingCharacters(in: .whitespaces)
            } else if let last = lastName {
                let currentFirst = loggedInUserName?.split(separator: " ").first.map(String.init) ?? ""
                loggedInUserName = "\(currentFirst) \(last)".trimmingCharacters(in: .whitespaces)
            }
            persistSession()
        }
    }

    // MARK: - Program Invites

    /// Loads pending invites - fetches appropriate invites based on user's global role
    /// Global admin sees all invites system-wide, standard users see only their own
    @MainActor
    func loadPendingInvites() async {
        guard let token = authToken, !token.isEmpty else {
            print("[ProgramContext] loadPendingInvites: No auth token")
            return
        }
        do {
            if isGlobalAdmin {
                print("[ProgramContext] loadPendingInvites: Fetching all invites (global_admin)")
                pendingInvites = try await APIClient.shared.fetchAllInvites(token: token)
            } else {
                print("[ProgramContext] loadPendingInvites: Fetching my invites (standard user)")
                pendingInvites = try await APIClient.shared.fetchMyInvites(token: token)
            }
            print("[ProgramContext] loadPendingInvites: Loaded \(pendingInvites.count) invites")
        } catch {
            print("[ProgramContext] loadPendingInvites error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    /// Responds to an invite (accept, decline, or revoke)
    /// - Parameters:
    ///   - inviteId: The ID of the invite
    ///   - action: "accept", "decline", or "revoke" (revoke is admin-only)
    ///   - blockFuture: If true, blocks future invites from this program (only for decline)
    /// - Returns: The response message from the server
    @MainActor
    func respondToInvite(inviteId: String, action: String, blockFuture: Bool = false) async throws -> String {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }

        let response = try await APIClient.shared.respondToInvite(
            token: token,
            inviteId: inviteId,
            action: action,
            blockFuture: blockFuture
        )

        // Refresh invites list after responding
        await loadPendingInvites()

        // If accepted, refresh programs list as user may have joined a new program
        if action == "accept" {
            await loadLookupData()
        }

        return response.message
    }

    // MARK: - Program Workout Management (per-program)

    @MainActor
    func loadProgramWorkouts() async {
        guard let token = authToken, !token.isEmpty else { return }
        guard let pid = programId else {
            errorMessage = "No program selected for program workouts."
            return
        }
        do {
            programWorkouts = try await APIClient.shared.fetchProgramWorkouts(token: token, programId: pid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func toggleWorkoutVisibility(libraryWorkoutId: String) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }
        guard let pid = programId else {
            throw APIError(message: "No program selected")
        }

        _ = try await APIClient.shared.toggleProgramWorkoutVisibility(
            token: token,
            programId: pid,
            libraryWorkoutId: libraryWorkoutId
        )
        await loadProgramWorkouts()
    }

    @MainActor
    func toggleCustomWorkoutVisibility(workoutId: String) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }

        _ = try await APIClient.shared.toggleCustomWorkoutVisibility(
            token: token,
            workoutId: workoutId
        )
        await loadProgramWorkouts()
    }

    @MainActor
    func addCustomProgramWorkout(name: String) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }
        guard let pid = programId else {
            throw APIError(message: "No program selected")
        }

        _ = try await APIClient.shared.addCustomProgramWorkout(
            token: token,
            programId: pid,
            workoutName: name
        )
        await loadProgramWorkouts()
    }

    @MainActor
    func editCustomProgramWorkout(workoutId: String, name: String) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }

        _ = try await APIClient.shared.editCustomProgramWorkout(
            token: token,
            workoutId: workoutId,
            workoutName: name
        )
        await loadProgramWorkouts()
    }

    @MainActor
    func deleteCustomProgramWorkout(workoutId: String) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }

        try await APIClient.shared.deleteCustomProgramWorkout(token: token, workoutId: workoutId)
        await loadProgramWorkouts()
    }

    // MARK: - Program Management (Delete)

    @MainActor
    func deleteProgram(programId: String) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }

        _ = try await APIClient.shared.deleteProgram(token: token, programId: programId)

        // Remove from local programs array
        programs.removeAll { $0.id == programId }

        // Clear selection if deleted program was selected
        if self.programId == programId {
            self.programId = nil
            self.name = ""
            self.status = ""
        }
    }

    // MARK: - Program Management (Create)

    @MainActor
    func createProgram(name: String, status: String, startDate: Date?, endDate: Date?) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let startStr = startDate.map { formatter.string(from: $0) }
        let endStr = endDate.map { formatter.string(from: $0) }

        let response = try await APIClient.shared.createProgram(
            token: token,
            name: name,
            status: status,
            startDate: startStr,
            endDate: endStr
        )

        // Refresh programs list to include the new program
        let updatedPrograms = try await APIClient.shared.fetchPrograms(token: token)
        programs = updatedPrograms
    }

    // MARK: - Session Persistence

    private enum SessionDefaultsKeys {
        static let userId = "session.userId"
        static let userName = "session.userName"
        static let username = "session.username"
        static let globalRole = "session.globalRole"
        static let programId = "session.programId"
        static let programRole = "session.programRole"
    }

    private func configureAPIClientHandlers() {
        APIClient.shared.tokenUpdateHandler = { [weak self] accessToken, refreshToken in
            Task { @MainActor in
                self?.authToken = accessToken
                self?.refreshToken = refreshToken
                self?.persistSession()
            }
        }

        APIClient.shared.authFailureHandler = { [weak self] in
            Task { @MainActor in
                self?.signOut()
            }
        }
    }

    private func restorePersistedSession() {
        authToken = SessionStore.shared.accessToken
        refreshToken = SessionStore.shared.refreshToken

        let defaults = UserDefaults.standard
        loggedInUserId = defaults.string(forKey: SessionDefaultsKeys.userId)
        loggedInUserName = defaults.string(forKey: SessionDefaultsKeys.userName)
        loggedInUsername = defaults.string(forKey: SessionDefaultsKeys.username)
        globalRole = defaults.string(forKey: SessionDefaultsKeys.globalRole) ?? globalRole
        programId = defaults.string(forKey: SessionDefaultsKeys.programId)
        loggedInUserProgramRole = defaults.string(forKey: SessionDefaultsKeys.programRole) ?? loggedInUserProgramRole

        if let name = loggedInUserName {
            adminName = name
        }
    }

    func persistSession() {
        SessionStore.shared.saveTokens(accessToken: authToken, refreshToken: refreshToken)

        let defaults = UserDefaults.standard
        setDefault(defaults, value: loggedInUserId, key: SessionDefaultsKeys.userId)
        setDefault(defaults, value: loggedInUserName, key: SessionDefaultsKeys.userName)
        setDefault(defaults, value: loggedInUsername, key: SessionDefaultsKeys.username)
        setDefault(defaults, value: globalRole, key: SessionDefaultsKeys.globalRole)
        setDefault(defaults, value: programId, key: SessionDefaultsKeys.programId)
        setDefault(defaults, value: loggedInUserProgramRole, key: SessionDefaultsKeys.programRole)
    }

    private func clearPersistedSession() {
        SessionStore.shared.clearTokens()
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: SessionDefaultsKeys.userId)
        defaults.removeObject(forKey: SessionDefaultsKeys.userName)
        defaults.removeObject(forKey: SessionDefaultsKeys.username)
        defaults.removeObject(forKey: SessionDefaultsKeys.globalRole)
        defaults.removeObject(forKey: SessionDefaultsKeys.programId)
        defaults.removeObject(forKey: SessionDefaultsKeys.programRole)
    }

    private func setDefault(_ defaults: UserDefaults, value: String?, key: String) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    @MainActor
    func refreshSessionIfNeeded() async {
        guard let refreshToken, !refreshToken.isEmpty else { return }
        do {
            let response = try await APIClient.shared.refreshSession(refreshToken: refreshToken)
            authToken = response.token
            self.refreshToken = response.refreshToken ?? refreshToken
            persistSession()
            await loadLookupData()
            if programId != nil {
                await loadMembershipDetails()
            }
        } catch {
            signOut()
        }
    }

    // MARK: - Account Management

    /// Changes the user's password
    @MainActor
    func changePassword(newPassword: String) async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }

        _ = try await APIClient.shared.changePassword(token: token, newPassword: newPassword)
    }

    /// Permanently deletes the user's account and all associated data
    @MainActor
    func deleteAccount() async throws {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }

        _ = try await APIClient.shared.deleteAccount(token: token)

        // Clear all local state after successful deletion
        signOut()
    }

    // MARK: - Program Membership Actions

    /// Leave the current program (soft removal - data is preserved)
    @MainActor
    func leaveProgram() async throws -> String {
        guard let token = authToken, !token.isEmpty else {
            throw APIError(message: "No auth token")
        }
        guard let pid = programId else {
            throw APIError(message: "No program selected")
        }

        let response = try await APIClient.shared.leaveProgram(token: token, programId: pid)

        // Clear current program selection
        programId = nil
        name = ""
        status = ""
        loggedInUserProgramRole = "member"
        membershipDetails = []

        // Refresh programs list to reflect the change
        await loadLookupData()

        // Persist the session without the program
        persistSession()

        return response.message
    }

    // MARK: - Notifications

    @MainActor
    func startNotificationStreamIfNeeded() {
        guard let token = authToken, !token.isEmpty else { return }
        if notificationStreamClient != nil {
            notificationStreamClient?.disconnect()
            notificationStreamClient = nil
        }

        let streamClient = NotificationStreamClient()
        streamClient.onNotification = { [weak self] notification in
            Task { @MainActor in
                self?.enqueueNotification(notification)
            }
        }
        streamClient.onError = { _ in }
        streamClient.connect(token: token)
        notificationStreamClient = streamClient

        Task {
            await loadUnacknowledgedNotifications()
        }
    }

    @MainActor
    func stopNotificationStream() {
        notificationStreamClient?.disconnect()
        notificationStreamClient = nil
        notificationQueue = []
        notificationIds = []
    }

    @MainActor
    func loadUnacknowledgedNotifications() async {
        guard let token = authToken, !token.isEmpty else { return }
        do {
            let items = try await APIClient.shared.fetchUnacknowledgedNotifications(token: token)
            notificationIds = Set(items.map { $0.id })
            notificationQueue = sortNotifications(items)
        } catch {
            // Ignore; retry on next refresh or stream event
        }
    }

    @MainActor
    func acknowledgeNotification(_ notification: APIClient.NotificationDTO) async {
        guard let token = authToken, !token.isEmpty else { return }
        notificationQueue.removeAll { $0.id == notification.id }
        notificationIds.remove(notification.id)
        do {
            _ = try await APIClient.shared.acknowledgeNotification(token: token, notificationId: notification.id)
        } catch {
            await loadUnacknowledgedNotifications()
        }
    }

    @MainActor
    private func enqueueNotification(_ notification: APIClient.NotificationDTO) {
        guard !notificationIds.contains(notification.id) else { return }
        notificationIds.insert(notification.id)
        notificationQueue.append(notification)
        notificationQueue = sortNotifications(notificationQueue)
        Task { @MainActor in
            await refreshDataForNotification(notification)
        }
    }

    @MainActor
    private func refreshDataForNotification(_ notification: APIClient.NotificationDTO) async {
        let type = notification.type

        if type == "program.invite_received" {
            await loadPendingInvites()
            await loadLookupData()
            return
        }

        if [
            "program.role_changed",
            "program.member_removed",
            "program.member_left",
            "program.member_joined",
            "program.admin_transferred",
            "program.updated",
            "program.deleted"
        ].contains(type) {
            await loadLookupData()
            if programId != nil {
                await loadMembershipDetails()
            }
        }
    }

    private func sortNotifications(_ items: [APIClient.NotificationDTO]) -> [APIClient.NotificationDTO] {
        return items.sorted { lhs, rhs in
            let lhsDate = lhs.createdAt.flatMap { notificationDateFormatter.date(from: $0) } ?? .distantPast
            let rhsDate = rhs.createdAt.flatMap { notificationDateFormatter.date(from: $0) } ?? .distantPast
            return lhsDate < rhsDate
        }
    }

    // MARK: - Sign Out

    func signOut() {
        let tokenToRevoke = refreshToken
        authToken = nil
        refreshToken = nil
        loggedInUserId = nil
        loggedInUserName = nil
        loggedInUsername = nil
        loggedInUserProgramRole = "member"
        globalRole = "standard"
        programId = nil
        membershipDetails = []
        pendingInvites = []

        stopNotificationStream()
        clearPersistedSession()

        if let tokenToRevoke {
            Task {
                try? await APIClient.shared.logout(refreshToken: tokenToRevoke)
            }
        }
    }
}
