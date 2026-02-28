import SwiftUI

struct EditProgramInfoView: View {
    @EnvironmentObject var programContext: ProgramContext
    @Environment(\.dismiss) private var dismiss

    @State private var programName: String = ""
    @State private var programStatus: String = "Active"
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false

    private let statusOptions = ["active", "planned", "completed"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit Program")
                        .font(.title2.weight(.bold))
                        .foregroundColor(Color(.label))
                    Text("Update program details")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabel))
                }

                VStack(spacing: 14) {
                    // Program Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Program name")
                            .font(.subheadline.weight(.semibold))
                        TextField("e.g. Winter Fitness Challenge", text: $programName)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    // Status
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Status")
                            .font(.subheadline.weight(.semibold))
                        Menu {
                            ForEach(statusOptions, id: \.self) { option in
                                Button(option.capitalized) { programStatus = option }
                            }
                        } label: {
                            HStack {
                                Text(programStatus.capitalized)
                                    .foregroundColor(Color(.label))
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }

                    // Start Date
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Start date")
                            .font(.subheadline.weight(.semibold))
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    // End Date
                    VStack(alignment: .leading, spacing: 6) {
                        Text("End date")
                            .font(.subheadline.weight(.semibold))
                        DatePicker("", selection: $endDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
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
                            Text("Save changes")
                                .font(.headline.weight(.semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appOrange)
                    .foregroundColor(.black)
                    .cornerRadius(14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isSaving || programName.isEmpty)
            }
            .padding(20)
        }
        .adaptiveBackground(topLeading: true)
        .navigationTitle("Edit Program")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            programName = programContext.name
            programStatus = programContext.status.lowercased()
            startDate = programContext.startDate
            endDate = programContext.endDate
        }
        .alert("Saved", isPresented: $showSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Program updated successfully")
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil

        do {
            try await programContext.updateProgram(
                name: programName,
                status: programStatus.lowercased(),
                startDate: startDate,
                endDate: endDate
            )
            showSuccessAlert = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}

#Preview {
    NavigationStack {
        EditProgramInfoView()
            .environmentObject(ProgramContext())
    }
}
