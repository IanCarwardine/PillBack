// CompanionMedicationsView.swift
// Onboarding screen for adding companion medications

import SwiftUI

/// Screen for adding companion medications during onboarding
struct CompanionMedicationsView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.metrics) var metrics

    let onContinue: () -> Void
    let onBack: (() -> Void)?

    @State private var showingAddSheet = false
    @State private var editingMedication: Medication?

    init(onContinue: @escaping () -> Void, onBack: (() -> Void)? = nil) {
        self.onContinue = onContinue
        self.onBack = onBack
    }

    private var keyMedication: Medication? {
        viewModel.medications.first { $0.isKeyDrug }
    }

    private var companionMedications: [Medication] {
        viewModel.medications.filter { !$0.isKeyDrug }
    }

    private var keyMedicationDisplayName: String {
        guard let keyMed = keyMedication else { return "your KEY drug" }
        // Extract just the name without dose
        let parts = keyMed.name.components(separatedBy: " ")
        if parts.count > 1, let lastPart = parts.last, lastPart.contains(where: { $0.isNumber }) {
            return parts.dropLast().joined(separator: " ")
        }
        return keyMed.name
    }

    var body: some View {
        ZStack {
            viewModel.currentTheme.colors.bgPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress (step 5 of 6)
                OnboardingProgressView(currentStep: 5, totalSteps: 6)
                    .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 24) {
                        Spacer(minLength: 30)

                        // Icon - Plus in circle
                        ZStack {
                            Circle()
                                .fill(viewModel.currentTheme.colors.accent)
                                .frame(width: 80, height: 80)

                            Image(systemName: "plus")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(.black)
                        }

                        // Title
                        VStack(spacing: 12) {
                            Text("Companion Medications")
                                .font(.system(size: metrics.titleSize, weight: .bold))
                                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                            Text("Add medications that you take alongside\nyour KEY drug (\(keyMedicationDisplayName)).")
                                .font(.system(size: 14))
                                .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                        // Key Medication Card
                        if let keyMed = keyMedication {
                            KeyMedicationCard(medication: keyMed)
                                .padding(.horizontal, metrics.horizontalPadding)
                        }

                        // Companion Medications List or Empty State
                        if companionMedications.isEmpty {
                            EmptyCompanionsView()
                                .padding(.horizontal, metrics.horizontalPadding)
                        } else {
                            CompanionsList(
                                medications: companionMedications,
                                onEdit: { med in editingMedication = med },
                                onDelete: deleteMedication
                            )
                            .padding(.horizontal, metrics.horizontalPadding)
                        }

                        // Add Companion Button
                        Button(action: {
                            HapticManager.selectionChanged()
                            showingAddSheet = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text("Add Companion Medication")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(viewModel.currentTheme.colors.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(viewModel.currentTheme.colors.bgCard)
                            )
                        }
                        .padding(.horizontal, metrics.horizontalPadding)

                        Spacer(minLength: 120)
                    }
                }

                // Navigation buttons
                VStack(spacing: 0) {
                    Divider()
                        .background(viewModel.currentTheme.colors.border)

                    HStack(spacing: 16) {
                        // Back button
                        if let onBack = onBack {
                            Button(action: {
                                HapticManager.selectionChanged()
                                onBack()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Back")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(viewModel.currentTheme.colors.bgElevated)
                                )
                            }
                            .frame(width: 120)
                        }

                        // Continue/Skip button
                        Button(action: {
                            HapticManager.impact(.medium)
                            onContinue()
                        }) {
                            HStack(spacing: 6) {
                                Text(companionMedications.isEmpty ? "Skip for Now" : "Continue")
                                    .font(.system(size: 16, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.currentTheme.colors.accent)
                            )
                        }
                    }
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.vertical, 16)
                }
                .background(viewModel.currentTheme.colors.bgPrimary)
            }
        }
        .fullScreenCover(isPresented: $showingAddSheet) {
            MedicationInputSheet(
                isKeyMedication: false,
                onSave: addCompanionMedication
            )
            .environmentObject(viewModel)
        }
        .fullScreenCover(item: $editingMedication) { medication in
            MedicationInputSheet(
                isKeyMedication: false,
                existingMedication: medication,
                onSave: { name, dose in
                    updateCompanionMedication(medication, name: name, dose: dose)
                }
            )
            .environmentObject(viewModel)
        }
    }

    private func addCompanionMedication(name: String, dose: String) {
        let fullName = dose.isEmpty ? name : "\(name) \(dose)"

        // Find next available ID
        let maxId = viewModel.medications.map { $0.id }.max() ?? 0
        let newMed = Medication(
            id: maxId + 1,
            name: fullName,
            frequency: 6,
            ports: "1-6",
            notes: "",
            isKeyDrug: false
        )
        viewModel.medications.append(newMed)
        viewModel.saveMedicationsPublic()
    }

    private func updateCompanionMedication(_ medication: Medication, name: String, dose: String) {
        let fullName = dose.isEmpty ? name : "\(name) \(dose)"

        if let index = viewModel.medications.firstIndex(where: { $0.id == medication.id }) {
            viewModel.medications[index].name = fullName
            viewModel.saveMedicationsPublic()
        }
    }

    private func deleteMedication(_ medication: Medication) {
        viewModel.medications.removeAll { $0.id == medication.id }
        viewModel.saveMedicationsPublic()
    }
}

// MARK: - Key Medication Card

private struct KeyMedicationCard: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let medication: Medication

    var body: some View {
        HStack(spacing: 22) {
            Image(systemName: "star.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "#f59e0b"))

            Text("\(medication.name)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

            Spacer()
       }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#f59e0b").opacity(0.5), lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.currentTheme.colors.bgCard)
                )
        )
    }
}

// MARK: - Empty State

private struct EmptyCompanionsView: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)

            Text("No companion medications yet")
                .font(.system(size: 14))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Companions List

private struct CompanionsList: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let medications: [Medication]
    let onEdit: (Medication) -> Void
    let onDelete: (Medication) -> Void

    var body: some View {
        VStack(spacing: 8) {
            ForEach(medications, id: \.id) { medication in
                CompanionRow(
                    medication: medication,
                    onEdit: { onEdit(medication) },
                    onDelete: { onDelete(medication) }
                )
            }
        }
    }
}

// MARK: - Companion Row

private struct CompanionRow: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let medication: Medication
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pills.fill")
                .font(.system(size: 18))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)

            Text(medication.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

            Spacer()

            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 16))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
            }

            // Delete button
            Button(action: {
                HapticManager.selectionChanged()
                onDelete()
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#ef4444"))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.currentTheme.colors.bgCard)
        )
    }
}

#Preview {
    CompanionMedicationsView(
        onContinue: { print("Continue") },
        onBack: { print("Back") }
    )
    .environmentObject(PillBackViewModel())
    .environment(\.metrics, ResponsiveMetrics())
}
