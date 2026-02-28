import SwiftUI

// MARK: - Detail Views

struct MemberStreakDetail: View {
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

struct WrapChips: View {
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
