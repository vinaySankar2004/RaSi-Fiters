import SwiftUI
import UniformTypeIdentifiers

// MARK: - Summary

struct AdminSummaryTab: View {
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
        .onChange(of: period) { _, _ in
            Task { await load() }
        }
        .onChange(of: programContext.programId) { _, _ in
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
