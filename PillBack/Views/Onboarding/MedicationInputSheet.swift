// MedicationInputSheet.swift
// Unified sheet for adding/editing medications

import SwiftUI

/// Sheet for adding or editing a medication
struct MedicationInputSheet: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.dismiss) var dismiss

    let isKeyMedication: Bool
    let existingMedication: Medication?
    let onSave: (String, String) -> Void

    @State private var medicationName: String
    @State private var dose: String
    @FocusState private var focusedField: Field?

    enum Field {
        case name, dose
    }

    init(
        isKeyMedication: Bool,
        existingMedication: Medication? = nil,
        onSave: @escaping (String, String) -> Void
    ) {
        self.isKeyMedication = isKeyMedication
        self.existingMedication = existingMedication
        self.onSave = onSave

        // Parse existing medication name and dose
        if let existing = existingMedication {
            // Try to extract dose from name (e.g., "Stalevo 200/50mg" -> "Stalevo", "200/50mg")
            let parts = existing.name.components(separatedBy: " ")
            if parts.count > 1, let lastPart = parts.last, lastPart.contains(where: { $0.isNumber }) {
                _medicationName = State(initialValue: parts.dropLast().joined(separator: " "))
                _dose = State(initialValue: lastPart)
            } else {
                _medicationName = State(initialValue: existing.name)
                _dose = State(initialValue: "")
            }
        } else {
            _medicationName = State(initialValue: "")
            _dose = State(initialValue: "")
        }
    }

    private var isValid: Bool {
        !medicationName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            ZStack {
                viewModel.currentTheme.colors.bgPrimary.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(viewModel.currentTheme.colors.accent)
                            .frame(width: 80, height: 80)

                        Image(systemName: isKeyMedication ? "star.fill" : "plus")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .padding(.top, 20)

                    // Title
                    Text(isKeyMedication ? "Key Medication" : "Add Companion")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                    // Input Fields
                    VStack(spacing: 16) {
                        // Medication Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Medication Name")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(viewModel.currentTheme.colors.textMuted)

                            TextField("e.g., Stalevo", text: $medicationName)
                                .font(.system(size: 18))
                                .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(viewModel.currentTheme.colors.bgCard)
                                )
                                .focused($focusedField, equals: .name)
                        }

                        // Dose
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Dose")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(viewModel.currentTheme.colors.textMuted)

                            TextField("e.g., 200/50mg", text: $dose)
                                .font(.system(size: 18))
                                .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(viewModel.currentTheme.colors.bgCard)
                                )
                                .focused($focusedField, equals: .dose)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // Save Button
                    Button(action: saveAndDismiss) {
                        Text("Save")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(isValid ? .black : viewModel.currentTheme.colors.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isValid
                                          ? viewModel.currentTheme.colors.accent
                                          : viewModel.currentTheme.colors.bgElevated)
                            )
                    }
                    .disabled(!isValid)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                }
            }
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                        .foregroundColor(viewModel.currentTheme.colors.accent)
                    }
                }
            }
            .onAppear {
                // Auto-focus name field to bring up keyboard
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    focusedField = .name
                }
            }
        }
        .interactiveDismissDisabled()
    }

    private func saveAndDismiss() {
        HapticManager.success()
        let trimmedName = medicationName.trimmingCharacters(in: .whitespaces)
        let trimmedDose = dose.trimmingCharacters(in: .whitespaces)
        onSave(trimmedName, trimmedDose)
        dismiss()
    }
}

#Preview {
    MedicationInputSheet(
        isKeyMedication: true,
        onSave: { name, dose in
            print("Saved: \(name) \(dose)")
        }
    )
    .environmentObject(PillBackViewModel())
}
