// PortSettingsSheet.swift
// Sheet for configuring individual port settings

import SwiftUI

/// Sheet for configuring port time and medications
struct PortSettingsSheet: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.dismiss) var dismiss

    let dose: Dose

    @State private var scheduledTime: Date
    @State private var selectedKeyMedicationId: Int?
    @State private var selectedCompanionIds: Set<Int>

    init(dose: Dose) {
        self.dose = dose
        _scheduledTime = State(initialValue: dose.scheduledTime)
        _selectedKeyMedicationId = State(initialValue: dose.keyMedicationId)

        // Initialize companion IDs (all medications except key)
        let companionIds = dose.medications
            .filter { $0.id != dose.keyMedicationId }
            .map { $0.id }
        _selectedCompanionIds = State(initialValue: Set(companionIds))
    }

    /// Available medications to choose from
    private var availableMedications: [Medication] {
        viewModel.medications
    }

    /// Key medications only (isKeyDrug == true)
    private var availableKeyMedications: [Medication] {
        availableMedications.filter { $0.isKeyDrug }
    }

    /// Companion medications only (isKeyDrug == false)
    private var availableCompanions: [Medication] {
        availableMedications.filter { !$0.isKeyDrug }
    }

    var body: some View {
        NavigationView {
            ZStack {
                viewModel.currentTheme.colors.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Port Header
                        PortHeaderSection(portNumber: dose.portNumber)

                        // Time Section
                        TimeSection(scheduledTime: $scheduledTime)

                        // Key Medicine Section
                        KeyMedicineSection(
                            selectedId: $selectedKeyMedicationId,
                            medications: availableKeyMedications
                        )

                        // Companion Medicines Section
                        CompanionMedicinesSection(
                            selectedIds: $selectedCompanionIds,
                            medications: availableCompanions
                        )

                        Spacer(minLength: 100)
                    }
                    .padding()
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

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(viewModel.currentTheme.colors.accent)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func saveSettings() {
        // Build medications array
        var medications: [Medication] = []

        // Add key medication first if selected
        if let keyId = selectedKeyMedicationId,
           let keyMed = availableMedications.first(where: { $0.id == keyId }) {
            medications.append(keyMed)
        }

        // Add companion medications
        for companionId in selectedCompanionIds {
            if let companion = availableMedications.first(where: { $0.id == companionId }) {
                medications.append(companion)
            }
        }

        // Update the dose
        viewModel.updatePortSettings(
            dose: dose,
            scheduledTime: scheduledTime,
            keyMedicationId: selectedKeyMedicationId,
            medications: medications
        )

        HapticManager.success()
    }
}

// MARK: - Port Header Section

private struct PortHeaderSection: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let portNumber: Int

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(viewModel.currentTheme.colors.accent)
                    .frame(width: 60, height: 60)

                Text("\(portNumber)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
            }

            Text("Port \(portNumber) Settings")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)
        }
        .padding(.top, 8)
    }
}

// MARK: - Time Section

private struct TimeSection: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Binding var scheduledTime: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Scheduled Time", systemImage: "clock.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)

            DatePicker(
                "",
                selection: $scheduledTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.currentTheme.colors.bgCard)
            )
            .colorScheme(viewModel.currentTheme != .daylight ? .dark : .light)
        }
    }
}

// MARK: - Key Medicine Section

private struct KeyMedicineSection: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Binding var selectedId: Int?
    let medications: [Medication]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Key Medicine", systemImage: "star.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)

            Text("Select the primary medication for this port")
                .font(.system(size: 12))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)

            if medications.isEmpty {
                EmptyMedicationPrompt()
            } else {
                VStack(spacing: 8) {
                    ForEach(medications, id: \.id) { medication in
                        MedicationSelectRow(
                            medication: medication,
                            isSelected: selectedId == medication.id,
                            isKey: true
                        ) {
                            HapticManager.selectionChanged()
                            if selectedId == medication.id {
                                selectedId = nil
                            } else {
                                selectedId = medication.id
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.currentTheme.colors.bgCard)
        )
    }
}

// MARK: - Companion Medicines Section

private struct CompanionMedicinesSection: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Binding var selectedIds: Set<Int>
    let medications: [Medication]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Companion Medicines", systemImage: "pills.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)

            Text("Select additional medications for this port")
                .font(.system(size: 12))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)

            if medications.isEmpty {
                Text("No other medications available")
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.currentTheme.colors.textMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(medications, id: \.id) { medication in
                        MedicationSelectRow(
                            medication: medication,
                            isSelected: selectedIds.contains(medication.id),
                            isKey: false
                        ) {
                            HapticManager.selectionChanged()
                            if selectedIds.contains(medication.id) {
                                selectedIds.remove(medication.id)
                            } else {
                                selectedIds.insert(medication.id)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.currentTheme.colors.bgCard)
        )
    }
}

// MARK: - Medication Select Row

private struct MedicationSelectRow: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let medication: Medication
    let isSelected: Bool
    let isKey: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? viewModel.currentTheme.colors.accent : viewModel.currentTheme.colors.textMuted,
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(viewModel.currentTheme.colors.accent)
                            .frame(width: 16, height: 16)
                    }
                }

                // Medication info
                VStack(alignment: .leading, spacing: 2) {
                    Text(medication.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                        .lineLimit(1)

                    if !medication.notes.isEmpty {
                        Text(medication.notes)
                            .font(.system(size: 11))
                            .foregroundColor(viewModel.currentTheme.colors.textMuted)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Key drug badge
                if medication.isKeyDrug {
                    Text("KEY")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(viewModel.currentTheme.colors.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .stroke(viewModel.currentTheme.colors.accent, lineWidth: 1)
                        )
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected
                          ? viewModel.currentTheme.colors.accent.opacity(0.1)
                          : viewModel.currentTheme.colors.bgElevated)
            )
        }
    }
}

// MARK: - Empty Medication Prompt

private struct EmptyMedicationPrompt: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "pills")
                .font(.system(size: 32))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)

            Text("No medications added")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)

            Text("Add medications in the Settings tab")
                .font(.system(size: 12))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

#Preview {
    PortSettingsSheet(
        dose: Dose(
            portNumber: 1,
            scheduledTime: Date(),
            medications: Medication.defaults
        )
    )
    .environmentObject(PillBackViewModel())
}
