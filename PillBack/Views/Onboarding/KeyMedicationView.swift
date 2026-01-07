// KeyMedicationView.swift
// Onboarding screen for entering the key medication

import SwiftUI

/// Screen for entering the key medication during onboarding
struct KeyMedicationView: View {
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

    private var hasKeyMedication: Bool {
        keyMedication != nil
    }

    var body: some View {
        ZStack {
            viewModel.currentTheme.colors.bgPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress (step 4 of 6)
                OnboardingProgressView(currentStep: 4, totalSteps: 6)
                    .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 24) {
                        Spacer(minLength: 30)

                        // Icon - Star in circle
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#f59e0b"))
                                .frame(width: 80, height: 80)

                            Image(systemName: "star.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        // Title
                        VStack(spacing: 12) {
                            Text("Your KEY Medication")
                                .font(.system(size: metrics.titleSize, weight: .bold))
                                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                            Text("This medication drives your entire schedule.\nCompanion meds will sync to these times.")
                                .font(.system(size: 14))
                                .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                        // Key Medication Card or Empty State
                        if let keyMed = keyMedication {
                            KeyMedicationCard(
                                medication: keyMed,
                                onEdit: { editingMedication = keyMed },
                                onDelete: deleteKeyMedication
                            )
                            .padding(.horizontal, metrics.horizontalPadding)
                        } else {
                            EmptyKeyMedsView()
                                .padding(.horizontal, metrics.horizontalPadding)
                        }

                        // Add Key Medication Button (only shown when no key med exists)
                        if !hasKeyMedication {
                            Button(action: {
                                HapticManager.selectionChanged()
                                showingAddSheet = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Add Key Medication")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(Color(hex: "#f59e0b"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(viewModel.currentTheme.colors.bgCard)
                                )
                            }
                            .padding(.horizontal, metrics.horizontalPadding)
                        }

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

                        // Continue button (disabled until key med is defined)
                        Button(action: {
                            HapticManager.impact(.medium)
                            onContinue()
                        }) {
                            HStack(spacing: 6) {
                                Text("Continue")
                                    .font(.system(size: 16, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(hasKeyMedication ? .black : viewModel.currentTheme.colors.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(hasKeyMedication
                                          ? viewModel.currentTheme.colors.accent
                                          : viewModel.currentTheme.colors.bgElevated)
                            )
                        }
                        .disabled(!hasKeyMedication)
                    }
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.vertical, 16)
                }
                .background(viewModel.currentTheme.colors.bgPrimary)
            }
        }
        .fullScreenCover(isPresented: $showingAddSheet) {
            MedicationInputSheet(
                isKeyMedication: true,
                onSave: addKeyMedication
            )
            .environmentObject(viewModel)
        }
        .fullScreenCover(item: $editingMedication) { medication in
            MedicationInputSheet(
                isKeyMedication: true,
                existingMedication: medication,
                onSave: { name, dose in
                    updateKeyMedication(name: name, dose: dose)
                }
            )
            .environmentObject(viewModel)
        }
    }

    private func addKeyMedication(name: String, dose: String) {
        let fullName = dose.isEmpty ? name : "\(name) \(dose)"

        // Remove any existing key medication
        viewModel.medications.removeAll { $0.isKeyDrug }

        // Add new key medication
        let keyMed = Medication(
            id: 1,
            name: fullName,
            frequency: 6,
            ports: "1-6",
            notes: "Key medication",
            isKeyDrug: true
        )
        viewModel.medications.insert(keyMed, at: 0)
        viewModel.saveMedicationsPublic()
    }

    private func updateKeyMedication(name: String, dose: String) {
        let fullName = dose.isEmpty ? name : "\(name) \(dose)"

        if let index = viewModel.medications.firstIndex(where: { $0.isKeyDrug }) {
            viewModel.medications[index].name = fullName
            viewModel.saveMedicationsPublic()
        }
    }

    private func deleteKeyMedication() {
        viewModel.medications.removeAll { $0.isKeyDrug }
        viewModel.saveMedicationsPublic()
    }
}

// MARK: - Key Medication Card

private struct KeyMedicationCard: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let medication: Medication
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "#f59e0b"))

            Text(medication.name)
                .font(.system(size: 16, weight: .semibold))
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
                .stroke(Color(hex: "#f59e0b").opacity(0.5), lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.currentTheme.colors.bgCard)
                )
        )
    }
}

// MARK: - Empty State

private struct EmptyKeyMedsView: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "star")
                .font(.system(size: 40))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)

            Text("No key medication defined")
                .font(.system(size: 14))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)

            Text("Add the medication that drives your schedule")
                .font(.system(size: 12))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    KeyMedicationView(
        onContinue: { print("Continue") },
        onBack: { print("Back") }
    )
    .environmentObject(PillBackViewModel())
    .environment(\.metrics, ResponsiveMetrics())
}
