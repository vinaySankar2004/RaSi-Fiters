import Foundation

extension ProgramContext {

    private enum HealthKitDefaultsKeys {
        static let enabled = "healthkit.enabled"
        static let syncProgramIds = "healthkit.syncProgramIds"
        static let lastSyncDate = "healthkit.lastSyncDate"
        static let lastSyncCount = "healthkit.lastSyncCount"
    }

    // MARK: - Start / Stop

    func startHealthKitSync() {
        guard HealthKitService.shared.isAvailable else { return }

        Task {
            do {
                try await HealthKitService.shared.requestAuthorization()
                await MainActor.run {
                    isHealthKitEnabled = true
                    persistHealthKitSettings()
                }
                HealthKitService.shared.startBackgroundDelivery { [weak self] in
                    Task { @MainActor in
                        await self?.performHealthKitSync()
                    }
                }
            } catch {
                await MainActor.run {
                    isHealthKitEnabled = false
                }
            }
        }
    }

    func stopHealthKitSync() {
        HealthKitService.shared.stopBackgroundDelivery()
        isHealthKitEnabled = false
        persistHealthKitSettings()
    }

    // MARK: - Sync

    private static var isSyncing = false

    @MainActor
    func performHealthKitSync() async {
        guard !ProgramContext.isSyncing,
              isHealthKitEnabled,
              let token = authToken, !token.isEmpty,
              let memberName = loggedInUserName, !memberName.isEmpty,
              !healthKitSyncProgramIds.isEmpty else { return }

        ProgramContext.isSyncing = true
        defer { ProgramContext.isSyncing = false }

        do {
            let workouts = try await HealthKitService.shared.fetchNewWorkouts()
            guard !workouts.isEmpty else { return }

            let aggregated = HealthKitService.shared.aggregate(workouts)
            let count = await HealthKitService.shared.syncToBackend(
                workouts: aggregated,
                token: token,
                memberName: memberName,
                memberId: loggedInUserId,
                programIds: healthKitSyncProgramIds
            )

            lastHealthKitSyncDate = Date()
            lastHealthKitSyncCount = count
            persistHealthKitSettings()
        } catch {
            // Sync failed — will retry on next trigger
        }
    }

    // MARK: - Persistence

    func persistHealthKitSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isHealthKitEnabled, forKey: HealthKitDefaultsKeys.enabled)
        defaults.set(Array(healthKitSyncProgramIds), forKey: HealthKitDefaultsKeys.syncProgramIds)
        defaults.set(lastHealthKitSyncCount, forKey: HealthKitDefaultsKeys.lastSyncCount)
        if let date = lastHealthKitSyncDate {
            defaults.set(date, forKey: HealthKitDefaultsKeys.lastSyncDate)
        } else {
            defaults.removeObject(forKey: HealthKitDefaultsKeys.lastSyncDate)
        }
    }

    func restoreHealthKitSettings() {
        let defaults = UserDefaults.standard
        isHealthKitEnabled = defaults.bool(forKey: HealthKitDefaultsKeys.enabled)
        if let ids = defaults.stringArray(forKey: HealthKitDefaultsKeys.syncProgramIds) {
            healthKitSyncProgramIds = Set(ids)
        }
        lastHealthKitSyncDate = defaults.object(forKey: HealthKitDefaultsKeys.lastSyncDate) as? Date
        lastHealthKitSyncCount = defaults.integer(forKey: HealthKitDefaultsKeys.lastSyncCount)

        if isHealthKitEnabled {
            HealthKitService.shared.startBackgroundDelivery { [weak self] in
                Task { @MainActor in
                    await self?.performHealthKitSync()
                }
            }
        }
    }

    func clearHealthKitSettings() {
        HealthKitService.shared.stopBackgroundDelivery()
        HealthKitService.shared.clearAnchor()

        isHealthKitEnabled = false
        healthKitSyncProgramIds = []
        lastHealthKitSyncDate = nil
        lastHealthKitSyncCount = 0

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: HealthKitDefaultsKeys.enabled)
        defaults.removeObject(forKey: HealthKitDefaultsKeys.syncProgramIds)
        defaults.removeObject(forKey: HealthKitDefaultsKeys.lastSyncDate)
        defaults.removeObject(forKey: HealthKitDefaultsKeys.lastSyncCount)
    }
}
