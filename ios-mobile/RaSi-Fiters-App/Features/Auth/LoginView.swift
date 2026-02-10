import SwiftUI

struct LoginView: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var identifier: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isLoading: Bool = false
    @State private var alertMessage: String?
    @State private var isShowingAlert: Bool = false
    @State private var navigateToProgramPicker: Bool = false
    private let privacyPolicyURL = URL(string: "https://vinaysankar2004.github.io/RaSi-Fiters/")!

    var body: some View {
        ZStack {
            AppGradient.background(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                NavigationLink(
                    destination: ProgramPickerView()
                        .navigationBarBackButtonHidden(true),
                    isActive: $navigateToProgramPicker
                ) {
                    EmptyView()
                }

                icon

                VStack(alignment: .center, spacing: 10) {
                    Text("Welcome Back")
                        .font(.title.bold())
                        .foregroundColor(Color(.label))

                    Text("Login to access your fitness dashboard")
                        .font(.callout.weight(.semibold))
                        .foregroundColor(Color(.secondaryLabel))
                }
                .frame(maxWidth: .infinity, alignment: .center)

                VStack(spacing: 16) {
                    inputField(
                        title: "Username or Email",
                        text: $identifier,
                        isSecure: false,
                        accessory: nil
                    )

                    inputField(
                        title: "Password",
                        text: $password,
                        isSecure: !isPasswordVisible,
                        accessory: AnyView(passwordEyeButton)
                    )
                }

                Button(action: { Task { await handleLogin() } }) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(colorScheme == .dark ? .black : .white)
                        } else {
                            Text("Login")
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
                .disabled(isLoading || identifier.isEmpty || password.isEmpty)

                HStack(spacing: 6) {
                    Text("New here?")
                        .font(.footnote)
                        .foregroundColor(Color(.secondaryLabel))

                    NavigationLink {
                        CreateAccountView()
                    } label: {
                        Text("Create an account")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.appOrange)
                    }
                }

                VStack(spacing: 4) {
                    Text("Training hard? Login to track your progress.")
                        .font(.footnote)
                        .foregroundColor(Color(.secondaryLabel))
                        .frame(maxWidth: .infinity, alignment: .center)

                    Link("Privacy Policy", destination: privacyPolicyURL)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.appOrange)
                }
                .padding(.top, 6)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Hide the default title area while keeping the back button.
            ToolbarItem(placement: .principal) {
                EmptyView()
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text("Login"),
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

    private func handleLogin() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await APIClient.shared.loginGlobal(identifier: identifier, password: password)
            let role = (response.globalRole ?? "").lowercased()

            // Store token and user info in shared context
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

            // Both global_admin and standard users go to ProgramPickerView
            navigateToProgramPicker = true
        } catch {
            alertMessage = error.localizedDescription
            isShowingAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(ProgramContext())
    }
}
