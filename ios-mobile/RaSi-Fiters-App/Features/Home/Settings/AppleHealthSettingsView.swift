import SwiftUI

struct AppleHealthSettingsView: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var isSyncing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Health")
                        .font(.title2.weight(.bold))
                        .foregroundColor(Color(.label))
                    Text("Automatically sync workouts from Apple Health")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .padding(.top, 8)

                // Connection Toggle
                VStack(spacing: 12) {
                    if programContext.isHealthKitEnabled {
                        connectedRow
                    } else {
                        connectButton
                    }
                }

                // Program Selection (only when connected)
                if programContext.isHealthKitEnabled {
                    programSelectionSection
                    syncStatusSection
                    disconnectSection
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard let token = programContext.authToken, !token.isEmpty else { return }
            if let programs = try? await APIClient.shared.fetchPrograms(token: token) {
                programContext.programs = programs
            }
        }
    }

    // MARK: - Connect Button

    private var connectButton: some View {
        Button {
            programContext.startHealthKitSync()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.appRed.opacity(0.14))
                        .frame(width: 42, height: 42)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.appRed)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connect to Apple Health")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(.label))
                    Text("Grant access to read your workouts")
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.appRed)
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
        .buttonStyle(.plain)
    }

    // MARK: - Connected Row

    private var connectedRow: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.appGreen.opacity(0.14))
                    .frame(width: 42, height: 42)
                Image(systemName: "checkmark.heart.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appGreen)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Connected")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(.label))
                Text("Apple Health workouts will sync automatically")
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.appGreen.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Program Selection

    private var programSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sync to Programs")
                .font(.footnote.weight(.semibold))
                .foregroundColor(Color(.secondaryLabel))

            if programContext.programs.isEmpty {
                Text("No programs available. Join or create a program first.")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
                    )
            } else {
                VStack(spacing: 0) {
                    ForEach(programContext.programs, id: \.id) { program in
                        let isSelected = programContext.healthKitSyncProgramIds.contains(program.id)
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if isSelected {
                                    programContext.healthKitSyncProgramIds.remove(program.id)
                                } else {
                                    programContext.healthKitSyncProgramIds.insert(program.id)
                                }
                                programContext.persistHealthKitSettings()
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(isSelected ? .appOrange : Color(.tertiaryLabel))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(program.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color(.label))
                                    Text(program.status ?? "Active")
                                        .font(.caption)
                                        .foregroundColor(Color(.secondaryLabel))
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)

                        if program.id != programContext.programs.last?.id {
                            Divider()
                                .padding(.leading, 50)
                        }
                    }
                }
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
    }

    // MARK: - Sync Status

    private var syncStatusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sync Status")
                .font(.footnote.weight(.semibold))
                .foregroundColor(Color(.secondaryLabel))

            VStack(spacing: 0) {
                // Last sync date
                HStack {
                    Text("Last Synced")
                        .font(.subheadline)
                        .foregroundColor(Color(.label))
                    Spacer()
                    Text(lastSyncLabel)
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                Divider().padding(.leading, 14)

                // Workout count
                HStack {
                    Text("Workouts Synced")
                        .font(.subheadline)
                        .foregroundColor(Color(.label))
                    Spacer()
                    Text("\(programContext.lastHealthKitSyncCount)")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                Divider().padding(.leading, 14)

                // Sync Now button
                Button {
                    isSyncing = true
                    Task {
                        await programContext.performHealthKitSync()
                        isSyncing = false
                    }
                } label: {
                    HStack {
                        Text("Sync Now")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.appOrange)
                        Spacer()
                        if isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.appOrange)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .disabled(isSyncing)
            }
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

    // MARK: - Disconnect

    private var disconnectSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                programContext.clearHealthKitSettings()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.appRedLight)
                            .frame(width: 42, height: 42)
                        Image(systemName: "heart.slash.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.appRed)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Disconnect Apple Health")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.appRed)
                        Text("Stop syncing and clear settings")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                    }
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
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private var lastSyncLabel: String {
        guard let date = programContext.lastHealthKitSyncDate else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
