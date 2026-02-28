import SwiftUI

struct MyProfileView: View {
    @EnvironmentObject var programContext: ProgramContext
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var gender: String = ""
    @State private var didEditGender = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Profile Header
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.appOrangeLight)
                            .frame(width: 70, height: 70)
                        Text(initials)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.appOrange)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(fullName)
                            .font(.title3.weight(.bold))
                        Text("@\(programContext.loggedInUsername ?? "")")
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                        Text(programContext.isGlobalAdmin ? "Global Admin" : (programContext.isProgramAdmin ? "Program Admin" : "Member"))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.appOrange)
                    }
                }

                Divider()

                // Editable Fields
                VStack(alignment: .leading, spacing: 14) {
                    // First Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("First name")
                            .font(.subheadline.weight(.semibold))
                        TextField("Enter first name", text: $firstName)
                            .textContentType(.givenName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    // Last Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Last name")
                            .font(.subheadline.weight(.semibold))
                        TextField("Enter last name", text: $lastName)
                            .textContentType(.familyName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    // Gender
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Gender")
                            .font(.subheadline.weight(.semibold))
                        Menu {
                            ForEach(["Male", "Female", "Non-binary", "Prefer not to say"], id: \.self) { option in
                                Button(option) {
                                    gender = option
                                    didEditGender = true
                                }
                            }
                            Button("Clear") {
                                gender = ""
                                didEditGender = true
                            }
                        } label: {
                            HStack {
                                Text(gender.isEmpty ? "Select gender" : gender)
                                    .foregroundColor(gender.isEmpty ? Color(.tertiaryLabel) : Color(.label))
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.appRed)
                        .font(.footnote.weight(.semibold))
                }

                Button(action: { Task { await save() } }) {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Save changes")
                            .font(.headline.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.appOrange)
                .foregroundColor(.black)
                .cornerRadius(14)
                .disabled(isSaving)

                // Spacer to push delete button to bottom
                Spacer()
                    .frame(height: 40)

                // Delete Account Section
                if !programContext.isGlobalAdmin {
                    VStack(spacing: 8) {
                        Divider()
                            .padding(.bottom, 8)

                        Button(action: { showDeleteConfirmation = true }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.subheadline)
                                Text("Delete Account")
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundColor(.red.opacity(0.8))
                        }
                        .disabled(isDeleting)

                        Text("This will permanently delete your account and all associated data.")
                            .font(.caption)
                            .foregroundColor(Color(.tertiaryLabel))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                }
            }
            .padding(20)
        }
        .adaptiveBackground(topLeading: true)
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Saved", isPresented: $showSuccessAlert) {
            Button("OK") {}
        } message: {
            Text("Profile updated successfully")
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("This action cannot be undone. All your data, including workout logs, health logs, and program memberships will be permanently deleted.")
        }
        .onAppear {
            // Initialize fields from current values
            if let name = programContext.loggedInUserName {
                let parts = name.split(separator: " ", maxSplits: 1)
                firstName = parts.first.map(String.init) ?? ""
                lastName = parts.count > 1 ? String(parts[1]) : ""
            }
            gender = programContext.loggedInUserGender ?? ""
        }
        .onChange(of: programContext.loggedInUserGender) { _, newValue in
            guard !didEditGender else { return }
            gender = newValue ?? ""
        }
    }

    private var fullName: String {
        let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? (programContext.loggedInUserName ?? "") : name
    }

    private var initials: String {
        let first = firstName.first.map { String($0).uppercased() } ?? ""
        let last = lastName.first.map { String($0).uppercased() } ?? ""
        let computed = "\(first)\(last)"
        return computed.isEmpty ? programContext.loggedInUserInitials : computed
    }

    private func deleteAccount() async {
        isDeleting = true
        errorMessage = nil

        do {
            try await programContext.deleteAccount()
            // After successful deletion, signOut is called automatically
            // which will trigger navigation back to login
        } catch {
            errorMessage = error.localizedDescription
            isDeleting = false
        }
    }

    private func save() async {
        guard let userId = programContext.loggedInUserId else { return }

        // Validate that names are not empty
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespaces)

        if trimmedFirst.isEmpty {
            errorMessage = "First name is required"
            return
        }
        if trimmedLast.isEmpty {
            errorMessage = "Last name is required"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            try await programContext.updateMemberProfile(
                memberId: userId,
                firstName: trimmedFirst,
                lastName: trimmedLast,
                gender: gender.isEmpty ? nil : gender
            )
            showSuccessAlert = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}
