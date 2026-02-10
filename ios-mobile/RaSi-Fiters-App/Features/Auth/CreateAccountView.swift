import SwiftUI

struct CreateAccountView: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var gender: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    @State private var isLoading: Bool = false
    @State private var alertMessage: String?
    @State private var isShowingAlert: Bool = false
    @State private var navigateToProgramPicker: Bool = false
    private let privacyPolicyURL = URL(string: "https://vinaysankar2004.github.io/RaSi-Fiters/")!
    private let genderOptions = ["Female", "Male", "Non-binary", "Prefer not to say"]

    var body: some View {
        ZStack {
            AppGradient.background(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    NavigationLink(
                        destination: ProgramPickerView()
                            .navigationBarBackButtonHidden(true),
                        isActive: $navigateToProgramPicker
                    ) {
                        EmptyView()
                    }

                    icon

                    VStack(alignment: .center, spacing: 10) {
                        Text("Create Account")
                            .font(.title.bold())
                            .foregroundColor(Color(.label))

                        Text("Start tracking your fitness journey")
                            .font(.callout.weight(.semibold))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    VStack(spacing: 16) {
                        inputField(title: "First Name", text: $firstName, isSecure: false, accessory: nil)
                        inputField(title: "Last Name", text: $lastName, isSecure: false, accessory: nil)
                        inputField(title: "Username", text: $username, isSecure: false, accessory: nil)
                        inputField(title: "Email", text: $email, isSecure: false, accessory: nil)
                        genderPicker

                        inputField(
                            title: "Password",
                            text: $password,
                            isSecure: !isPasswordVisible,
                            accessory: AnyView(passwordEyeButton)
                        )

                        inputField(
                            title: "Confirm Password",
                            text: $confirmPassword,
                            isSecure: !isConfirmPasswordVisible,
                            accessory: AnyView(confirmPasswordEyeButton)
                        )

                        VStack(spacing: 6) {
                            Text("Password must be at least 8 characters and include upper, lower, and a number.")
                                .font(.footnote)
                                .foregroundColor(Color(.secondaryLabel))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if !confirmPassword.isEmpty && confirmPassword != password {
                                Text("Passwords do not match.")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundColor(.appRed)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    Button(action: { Task { await handleCreateAccount() } }) {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(colorScheme == .dark ? .black : .white)
                            } else {
                                Text("Create Account")
                                    .font(.headline.weight(.semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .frame(maxWidth: 240)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .background(
                            Capsule()
                                .fill(Color(.label))
                        )
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .adaptiveShadow(radius: 8, y: 4)
                    .disabled(!canSubmit || isLoading)

                    VStack(spacing: 6) {
                        Text("By creating an account, you accept our")
                            .font(.footnote)
                            .foregroundColor(Color(.secondaryLabel))

                        Link("Privacy Policy", destination: privacyPolicyURL)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.appOrange)
                    }

                    Button(action: { dismiss() }) {
                        Text("Already have an account? Sign in")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                EmptyView()
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text("Create Account"),
                message: Text(alertMessage ?? "Something went wrong."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var icon: some View {
        ZStack {
            Circle()
                .fill(Color.appOrange)
                .frame(width: 90, height: 90)
                .adaptiveShadow(radius: 10, y: 5)

            Image(systemName: "chart.bar.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundStyle(Color.black)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private func inputField(
        title: String,
        text: Binding<String>,
        isSecure: Bool,
        accessory: AnyView?
    ) -> some View {
        HStack {
            if isSecure {
                SecureField(title, text: text)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            } else {
                TextField(title, text: text)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }

            if let accessory {
                accessory
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.systemGray3), lineWidth: 1)
        )
    }

    private var passwordEyeButton: some View {
        Button(action: { isPasswordVisible.toggle() }) {
            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                .foregroundColor(Color(.secondaryLabel))
        }
    }

    private var confirmPasswordEyeButton: some View {
        Button(action: { isConfirmPasswordVisible.toggle() }) {
            Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye")
                .foregroundColor(Color(.secondaryLabel))
        }
    }

    private var genderPicker: some View {
        Menu {
            ForEach(genderOptions, id: \.self) { option in
                Button(option) { gender = option }
            }
        } label: {
            HStack {
                Text(gender.isEmpty ? "Gender (optional)" : gender)
                    .foregroundColor(gender.isEmpty ? Color(.secondaryLabel) : Color(.label))
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundColor(Color(.secondaryLabel))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(.systemGray3), lineWidth: 1)
            )
        }
    }

    private var passwordMeetsPolicy: Bool {
        guard password.count >= 8 else { return false }
        let hasUpper = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLower = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        return hasUpper && hasLower && hasNumber
    }

    private var canSubmit: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        passwordMeetsPolicy &&
        password == confirmPassword
    }

    private func handleCreateAccount() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await APIClient.shared.registerAccount(
                firstName: firstName,
                lastName: lastName,
                username: username,
                email: email,
                password: password,
                gender: gender
            )

            let response = try await APIClient.shared.loginGlobal(identifier: username, password: password)
            let role = (response.globalRole ?? "").lowercased()

            programContext.authToken = response.token
            programContext.refreshToken = response.refreshToken
            programContext.globalRole = role.isEmpty ? "standard" : role
            programContext.loggedInUserId = response.memberId
            programContext.loggedInUsername = response.username
            if let name = response.memberName {
                programContext.loggedInUserName = name
                programContext.adminName = name
            } else if let uname = response.username {
                programContext.loggedInUserName = uname
                programContext.adminName = uname
            }
            await programContext.loadLookupData()
            programContext.persistSession()

            navigateToProgramPicker = true
        } catch {
            alertMessage = error.localizedDescription
            isShowingAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        CreateAccountView()
            .environmentObject(ProgramContext())
    }
}
