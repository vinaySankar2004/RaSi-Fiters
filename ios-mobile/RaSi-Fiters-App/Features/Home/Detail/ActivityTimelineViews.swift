import SwiftUI

// MARK: - Shared header for timeline detail
struct HealthHeaderStats: View {
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

struct HeaderStats: View {
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

struct HeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct CalloutView: View {
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

struct HealthCalloutView: View {
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

struct GlassButton: View {
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
