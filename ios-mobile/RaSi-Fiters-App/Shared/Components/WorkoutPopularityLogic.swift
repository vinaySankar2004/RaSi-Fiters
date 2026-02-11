import SwiftUI

enum WorkoutPopularityMetric: String, CaseIterable, Identifiable {
    case count
    case totalMinutes
    case avgMinutes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .count: return "Count"
        case .totalMinutes: return "Total Minutes"
        case .avgMinutes: return "Avg Minutes"
        }
    }

    var axisLabel: String {
        switch self {
        case .count: return "Workouts"
        case .totalMinutes: return "Minutes"
        case .avgMinutes: return "Avg mins"
        }
    }

    func value(for type: APIClient.WorkoutTypeDTO) -> Double {
        switch self {
        case .count:
            return Double(type.sessions)
        case .totalMinutes:
            return Double(type.total_duration)
        case .avgMinutes:
            return Double(type.avg_duration_minutes)
        }
    }

    func formattedValue(for type: APIClient.WorkoutTypeDTO) -> String {
        switch self {
        case .count:
            return "\(type.sessions)"
        case .totalMinutes:
            return "\(type.total_duration) mins"
        case .avgMinutes:
            return "\(type.avg_duration_minutes) mins"
        }
    }
}

func workoutPopularitySorted(
    types: [APIClient.WorkoutTypeDTO],
    metric: WorkoutPopularityMetric
) -> [APIClient.WorkoutTypeDTO] {
    types.sorted { metric.value(for: $0) > metric.value(for: $1) }
}

func workoutTypePaletteColor(for name: String) -> Color {
    let palette: [Color] = [
        Color(red: 0.95, green: 0.60, blue: 0.00),
        Color(red: 0.00, green: 0.60, blue: 0.90),
        Color(red: 0.20, green: 0.70, blue: 0.30),
        Color(red: 0.60, green: 0.35, blue: 0.80),
        Color(red: 0.95, green: 0.30, blue: 0.35),
        Color(red: 0.05, green: 0.75, blue: 0.70),
        Color(red: 0.95, green: 0.45, blue: 0.70),
        Color(red: 0.35, green: 0.45, blue: 0.90),
        Color(red: 0.85, green: 0.55, blue: 0.15),
        Color(red: 0.55, green: 0.80, blue: 0.20),
        Color(red: 0.10, green: 0.55, blue: 0.50),
        Color(red: 0.80, green: 0.20, blue: 0.50)
    ]
    var hash = 5381
    for u in name.unicodeScalars {
        hash = ((hash << 5) &+ hash) &+ Int(u.value)
    }
    let idx = abs(hash) % palette.count
    return palette[idx]
}
