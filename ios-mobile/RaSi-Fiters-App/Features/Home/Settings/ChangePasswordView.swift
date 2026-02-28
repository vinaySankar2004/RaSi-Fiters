import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false

    private var isValid: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword && newPassword.count >= 6
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Change Password")
                        .font(.title2.weight(.bold))
                        .foregroundColor(Color(.label))
                    Text("Enter your new password")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }

                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("New password")
                            .font(.subheadline.weight(.semibold))
                        HStack {
                            if showPassword {
                                TextField("••••••••", text: $newPassword)
                            } else {
                                SecureField("••••••••", text: $newPassword)
                            }
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm password")
                            .font(.subheadline.weight(.semibold))
                        SecureField("••••••••", text: $confirmPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    if !newPassword.isEmpty && newPassword.count < 6 {
                        Text("Password must be at least 6 characters")
                            .font(.caption)
                            .foregroundColor(.appOrange)
                    }

                    if !confirmPassword.isEmpty && newPassword != confirmPassword {
                        Text("Passwords do not match")
                            .font(.caption)
                            .foregroundColor(.appRed)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.appRed)
                        .font(.footnote.weight(.semibold))
                }

                Button(action: { Task { await save() } }) {
                    Group {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Update Password")
                                .font(.headline.weight(.semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValid ? Color.appOrange : Color(.systemGray3))
                    .foregroundColor(.black)
                    .cornerRadius(14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!isValid || isSaving)
            }
            .padding(20)
        }
        .adaptiveBackground(topLeading: true)
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Password Updated", isPresented: $showSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your password has been changed successfully")
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil

        do {
            try await programContext.changePassword(newPassword: newPassword)
            showSuccessAlert = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}
