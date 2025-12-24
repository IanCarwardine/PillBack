// EditDoseSheet.swift
// Sheet for editing dose time or untaking a dose

import SwiftUI

/// Sheet for editing a taken dose's time or reverting to pending
struct EditDoseSheet: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.dismiss) private var dismiss

    let dose: Dose
    @State private var selectedTime: Date
    @State private var showingUntakeConfirmation = false

    init(dose: Dose) {
        self.dose = dose
        self._selectedTime = State(initialValue: dose.actualTime ?? Date())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Dose Info
                VStack(spacing: 8) {
                    PortIndicator(portNumber: dose.portNumber, status: dose.status)

                    Text("Port \(dose.portNumber)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                    Text("Scheduled: \(dose.scheduledTimeString)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                }
                .padding(.top)

                Divider()

                // Time Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Actual Time Taken")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(viewModel.currentTheme.colors.textSecondary)

                    DatePicker(
                        "Time",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

                // Timing Preview
                if dose.status == .taken {
                    let diff = Int(selectedTime.timeIntervalSince(dose.scheduledTime) / 60)
                    let absDiff = abs(diff)
                    let category = timingCategoryFor(difference: diff)

                    VStack(spacing: 8) {
                        TimingBadge(category: category)

                        Text(diff == 0 ? "On time" : "\(absDiff) min \(diff > 0 ? "late" : "early")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.currentTheme.colors.bgElevated)
                    )
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: updateTime) {
                        Text("Update Time")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.currentTheme.colors.accent)
                            )
                    }

                    Button(action: { showingUntakeConfirmation = true }) {
                        Text("Mark as Not Taken")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(viewModel.currentTheme.colors.danger)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.currentTheme.colors.danger, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(viewModel.currentTheme.colors.bgPrimary)
            .navigationTitle("Edit Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(viewModel.currentTheme.colors.accent)
                }
            }
            .confirmationDialog(
                "Mark as Not Taken?",
                isPresented: $showingUntakeConfirmation,
                titleVisibility: .visible
            ) {
                Button("Mark as Not Taken", role: .destructive) {
                    untakeDose()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will revert Port \(dose.portNumber) to pending status.")
            }
        }
    }

    private func updateTime() {
        viewModel.updateDoseTime(dose: dose, newTime: selectedTime)
        dismiss()
    }

    private func untakeDose() {
        viewModel.untakeDose(dose: dose)
        dismiss()
    }

    private func timingCategoryFor(difference: Int) -> TimingCategory {
        let absDiff = abs(difference)
        if absDiff <= 5 { return .excellent }
        if absDiff <= 10 { return .good }
        if absDiff <= 20 { return .fair }
        return .poor
    }
}

#Preview {
    EditDoseSheet(
        dose: Dose(
            portNumber: 1,
            scheduledTime: Date().addingTimeInterval(-3600),
            actualTime: Date().addingTimeInterval(-3600 + 300),
            medications: [],
            status: .taken
        )
    )
    .environmentObject(PillBackViewModel())
}
