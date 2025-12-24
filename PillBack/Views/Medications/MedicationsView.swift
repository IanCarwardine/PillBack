// MedicationsView.swift
// Medications tab showing all configured medications

import SwiftUI

/// Medications list view
struct MedicationsView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @State private var showingAddSheet = false
    @State private var medicationToEdit: Medication?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Medications")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                        Text("\(viewModel.medications.count) medications configured")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(viewModel.currentTheme.colors.textMuted)
                    }

                    Spacer()

                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(viewModel.currentTheme.colors.accent)
                    }
                    .accessibilityLabel("Add medication")
                }
                .padding(.horizontal)

                // KEY DRUG section
                let keyDrugs = viewModel.medications.filter { $0.isKeyDrug }
                if !keyDrugs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("KEY DRUG")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(Color(hex: "#eab308"))
                            .padding(.horizontal)

                        ForEach(keyDrugs, id: \.id) { medication in
                            MedicationRowView(
                                medication: medication,
                                onEdit: { medicationToEdit = medication }
                            )
                        }
                    }
                }

                // Other medications
                let otherMeds = viewModel.medications.filter { !$0.isKeyDrug }
                if !otherMeds.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("OTHER MEDICATIONS")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(viewModel.currentTheme.colors.textMuted)
                            .padding(.horizontal)

                        ForEach(otherMeds, id: \.id) { medication in
                            MedicationRowView(
                                medication: medication,
                                onEdit: { medicationToEdit = medication }
                            )
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(viewModel.currentTheme.colors.bgPrimary)
        .sheet(isPresented: $showingAddSheet) {
            AddMedicationSheet(medication: nil)
                .environmentObject(viewModel)
        }
        .sheet(item: $medicationToEdit) { medication in
            AddMedicationSheet(medication: medication)
                .environmentObject(viewModel)
        }
    }
}

/// Row view for a single medication
struct MedicationRowView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let medication: Medication
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(medication.isKeyDrug ? Color(hex: "#eab308").opacity(0.2) : viewModel.currentTheme.colors.bgElevated)
                        .frame(width: 44, height: 44)

                    Image(systemName: medication.isKeyDrug ? "star.fill" : "pill.fill")
                        .font(.system(size: 18))
                        .foregroundColor(medication.isKeyDrug ? Color(hex: "#eab308") : viewModel.currentTheme.colors.accent)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                    HStack(spacing: 8) {
                        // Frequency
                        Label("\(medication.frequency)x daily", systemImage: "clock")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(viewModel.currentTheme.colors.textSecondary)

                        // Ports
                        Text("Ports: \(medication.ports)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(viewModel.currentTheme.colors.textMuted)
                    }

                    if !medication.notes.isEmpty {
                        Text(medication.notes)
                            .font(.system(size: 11))
                            .foregroundColor(viewModel.currentTheme.colors.textMuted)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.currentTheme.colors.textMuted)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.currentTheme.colors.bgCard)
            )
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MedicationsView()
        .environmentObject(PillBackViewModel())
}
