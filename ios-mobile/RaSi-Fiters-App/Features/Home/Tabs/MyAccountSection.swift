import SwiftUI

// MARK: - My Account Section

struct ProgramMyAccountSection: View {
    @EnvironmentObject var programContext: ProgramContext
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showSignOutConfirm = false
    private let privacyPolicyURL = URL(string: "https://vinaysankar2004.github.io/RaSi-Fiters/")!

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "My Account", icon: "person.circle.fill", color: .gray)

            VStack(spacing: 12) {
                // My Profile
                NavigationLink {
                    MyProfileView()
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.appOrangeLight)
                                .frame(width: 42, height: 42)
                            Text(programContext.loggedInUserInitials)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.appOrange)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(programContext.loggedInUserName ?? "My Profile")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color(.label))
                            Text("@\(programContext.loggedInUsername ?? "")")
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

                // Change Password
                NavigationLink {
                    ChangePasswordView()
                } label: {
                    settingsRow(
                        icon: "lock.fill",
                        color: .appOrange,
                        title: "Change Password",
                        subtitle: "Update your account password"
                    )
                }
                .buttonStyle(.plain)

                // Appearance
                NavigationLink {
                    AppearanceSettingsView()
                        .environmentObject(themeManager)
                } label: {
                    settingsRow(
                        icon: themeManager.appearance.icon,
                        color: .appPurple,
                        title: "Appearance",
                        subtitle: themeManager.appearance.displayName
                    )
                }
                .buttonStyle(.plain)

                // Apple Health
                NavigationLink {
                    AppleHealthSettingsView()
                } label: {
                    settingsRow(
                        icon: "heart.fill",
                        color: .appRed,
                        title: "Apple Health",
                        subtitle: "Sync workouts automatically"
                    )
                }
                .buttonStyle(.plain)

                Link(destination: privacyPolicyURL) {
                    settingsRow(
                        icon: "doc.text",
                        color: .appOrange,
                        title: "Privacy Policy",
                        subtitle: "Learn how we handle your data"
                    )
                }
                .buttonStyle(.plain)

                // Sign Out
                Button {
                    showSignOutConfirm = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.appRedLight)
                                .frame(width: 42, height: 42)
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.appRed)
                        }
                        Text("Sign Out")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.appRed)
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
        .alert("Sign Out?", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                programContext.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}
