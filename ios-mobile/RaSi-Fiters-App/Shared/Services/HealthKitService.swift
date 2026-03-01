import Foundation
import HealthKit

final class HealthKitService {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()
    private var observerQuery: HKObserverQuery?
    private let anchorKey = "healthkit.workoutAnchor"

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard isAvailable else {
            throw APIError(message: "HealthKit is not available on this device.")
        }
        let workoutType = HKObjectType.workoutType()
        try await healthStore.requestAuthorization(toShare: [], read: [workoutType])
    }

    // MARK: - Anchor Persistence

    private func loadAnchor() -> HKQueryAnchor? {
        guard let data = UserDefaults.standard.data(forKey: anchorKey) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
    }

    private func saveAnchor(_ anchor: HKQueryAnchor) {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true) {
            UserDefaults.standard.set(data, forKey: anchorKey)
        }
    }

    func clearAnchor() {
        UserDefaults.standard.removeObject(forKey: anchorKey)
    }

    // MARK: - Fetch New Workouts (Anchored Query)

    func fetchNewWorkouts() async throws -> [HKWorkout] {
        let workoutType = HKObjectType.workoutType()
        let anchor = loadAnchor()

        // On first sync (nil anchor), only fetch workouts from March 1, 2026 onward
        var predicate: NSPredicate? = nil
        if anchor == nil {
            var components = DateComponents()
            components.year = 2026
            components.month = 3
            components.day = 1
            if let cutoffDate = Calendar.current.date(from: components) {
                predicate = HKQuery.predicateForSamples(withStart: cutoffDate, end: nil, options: .strictStartDate)
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKAnchoredObjectQuery(
                type: workoutType,
                predicate: predicate,
                anchor: anchor,
                limit: HKObjectQueryNoLimit
            ) { [weak self] _, samples, _, newAnchor, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if let newAnchor {
                    self?.saveAnchor(newAnchor)
                }
                let workouts = (samples ?? []).compactMap { $0 as? HKWorkout }
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Background Delivery

    func startBackgroundDelivery(onUpdate: @escaping () -> Void) {
        guard isAvailable else { return }
        let workoutType = HKObjectType.workoutType()

        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { _, completionHandler, error in
            if error == nil {
                onUpdate()
            }
            completionHandler()
        }
        observerQuery = query
        healthStore.execute(query)

        healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { _, _ in }
    }

    func stopBackgroundDelivery() {
        if let query = observerQuery {
            healthStore.stop(query)
            observerQuery = nil
        }
        let workoutType = HKObjectType.workoutType()
        healthStore.disableBackgroundDelivery(for: workoutType) { _, _ in }
    }

    // MARK: - Aggregation

    struct AggregatedWorkout {
        let workoutName: String
        let date: String          // yyyy-MM-dd
        let durationMinutes: Int
    }

    func aggregate(_ workouts: [HKWorkout]) -> [AggregatedWorkout] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Group by (workoutName, date), sum durations
        var grouped: [String: Double] = [:]
        for workout in workouts {
            let name = HealthKitWorkoutTypeMap.workoutName(for: workout.workoutActivityType)
            let date = dateFormatter.string(from: workout.startDate)
            let key = "\(name)||\(date)"
            grouped[key, default: 0] += workout.duration / 60.0
        }

        return grouped.compactMap { key, totalMinutes in
            let parts = key.components(separatedBy: "||")
            guard parts.count == 2 else { return nil }
            return AggregatedWorkout(
                workoutName: parts[0],
                date: parts[1],
                durationMinutes: max(Int(totalMinutes.rounded()), 1)
            )
        }
    }

    // MARK: - Sync to Backend

    func syncToBackend(
        workouts: [AggregatedWorkout],
        token: String,
        memberName: String,
        memberId: String?,
        programIds: Set<String>
    ) async -> Int {
        var syncedCount = 0
        for workout in workouts {
            for programId in programIds {
                do {
                    // Try to add the workout log
                    try await APIClient.shared.addWorkoutLog(
                        token: token,
                        memberName: memberName,
                        workoutName: workout.workoutName,
                        date: workout.date,
                        durationMinutes: workout.durationMinutes,
                        programId: programId,
                        memberId: memberId
                    )
                    syncedCount += 1
                } catch {
                    // On duplicate/conflict, fall back to updating the existing log
                    do {
                        try await APIClient.shared.updateWorkoutLog(
                            token: token,
                            programId: programId,
                            memberName: memberName,
                            workoutName: workout.workoutName,
                            date: workout.date,
                            duration: workout.durationMinutes
                        )
                        syncedCount += 1
                    } catch {
                        // Both add and update failed — skip this entry
                    }
                }
            }
        }
        return syncedCount
    }
}
