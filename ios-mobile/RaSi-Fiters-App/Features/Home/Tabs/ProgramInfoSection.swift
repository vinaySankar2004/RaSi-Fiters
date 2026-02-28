import SwiftUI

// MARK: - Program Info Section

struct ProgramInfoSection: View {
    @EnvironmentObject var programContext: ProgramContext
    @Binding var showSelectProgram: Bool
    @State private var showLeaveProgramConfirm = false
    @State private var isLeavingProgram = false
    @State private var leaveProgramError: String?

    private var canLeaveProgram: Bool {
        !programContext.isGlobalAdmin
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Program Info", icon: "info.circle.fill", color: .blue)

            VStack(spacing: 12) {
                // Select Program Button
                Button {
                    showSelectProgram = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.appOrangeVeryLight)
                                .frame(width: 42, height: 42)
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.appOrange)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Select Program")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color(.label))
                            Text("Switch to a different program")
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
                .buttonStyle(.plain)

                // Edit Program Info (only if admin)
                if programContext.canEditProgramData {
                    NavigationLink {
                        EditProgramInfoView()
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.appBlueLight)
                                    .frame(width: 42, height: 42)
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Edit Program Details")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Color(.label))
                                Text("\(programContext.status) • \(programContext.dateRangeLabel)")
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
                    .buttonStyle(.plain)
                }

                if canLeaveProgram {
                    // Leave Program
                    Button {
                        showLeaveProgramConfirm = true
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 42, height: 42)
                                Image(systemName: "arrow.left.circle")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(.secondaryLabel))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Leave Program")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Color(.label))
                                Text("Your data will be preserved")
                                    .font(.caption)
                                    .foregroundColor(Color(.secondaryLabel))
                            }
                            Spacer()
                            if isLeavingProgram {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
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
                    .buttonStyle(.plain)
                    .disabled(isLeavingProgram)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
        )
        .adaptiveShadow(radius: 8, y: 4)
        .alert("Leave Program?", isPresented: $showLeaveProgramConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                Task { await leaveProgram() }
            }
        } message: {
            Text("You will no longer have access to \(programContext.name). Your workout history and data will be preserved. If you're invited back and accept, your data will be restored. If you're the last member, the program will be deleted automatically.")
        }
        .alert("Error", isPresented: .constant(leaveProgramError != nil)) {
            Button("OK") { leaveProgramError = nil }
        } message: {
            Text(leaveProgramError ?? "")
        }
    }

    private func leaveProgram() async {
        isLeavingProgram = true
        leaveProgramError = nil

        do {
            _ = try await programContext.leaveProgram()
            showSelectProgram = true
        } catch {
            leaveProgramError = error.localizedDescription
        }

        isLeavingProgram = false
    }
}
