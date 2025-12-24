// AddMedicationSheet.swift
// Sheet for adding or editing a medication

import SwiftUI

/// Sheet for adding or editing medications
struct AddMedicationSheet: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.dismiss) private var dismiss

    let medication: Medication?

    @State private var name: String
    @State private var frequency: Int
    @State private var selectedPorts: Set<Int>
    @State private var notes: String
    @State private var isKeyDrug: Bool
    @State private var showingDeleteConfirmation = false

    private var isEditing: Bool { medication != nil }

    init(medication: Medication?) {
        self.medication = medication
        _name = State(initialValue: medication?.name ?? "")
        _frequency = State(initialValue: medication?.frequency ?? 1)
        _selectedPorts = State(initialValue: Set(medication?.portNumbers ?? [1]))
        _notes = State(initialValue: medication?.notes ?? "")
        _isKeyDrug = State(initialValue: medication?.isKeyDrug ?? false)
    }

    private var portsString: String {
        let sorted = selectedPorts.sorted()
        if sorted.isEmpty { return "" }
        if sorted == Array(1...6) { return "1-6" }
        if sorted.count > 2 {
            // Check if consecutive
            let isConsecutive = sorted.enumerated().allSatisfy { $0.element == sorted[0] + $0.offset }
            if isConsecutive {
                return "\(sorted.first!)-\(sorted.last!)"
            }
        }
        return sorted.map(String.init).joined(separator: ",")
    }

    private var isValid: Bool {
        !name.isEmpty && !selectedPorts.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Name section
                Section {
                    TextField("Medication Name", text: $name)
                } header: {
                    Text("Name")
                }

                // Frequency section
                Section {
                    Stepper("\(frequency)x daily", value: $frequency, in: 1...6)
                } header: {
                    Text("Frequency")
                }

                // Ports section
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(1...6, id: \.self) { port in
                            Button(action: {
                                if selectedPorts.contains(port) {
                                    selectedPorts.remove(port)
                                } else {
                                    selectedPorts.insert(port)
                                }
                            }) {
                                Text("\(port)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(selectedPorts.contains(port) ? .white : viewModel.currentTheme.colors.textSecondary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(selectedPorts.contains(port) ? viewModel.currentTheme.colors.accent : viewModel.currentTheme.colors.bgElevated)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Ports (tap to select)")
                }

                // Notes section
                Section {
                    TextField("Optional notes", text: $notes)
                } header: {
                    Text("Notes")
                }

                // Key drug toggle
                Section {
                    Toggle("KEY DRUG (Levodopa)", isOn: $isKeyDrug)
                } footer: {
                    Text("KEY DRUG medications are highlighted and used for schedule timing calculations.")
                }

                // Delete button (only when editing)
                if isEditing {
                    Section {
                        Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                            HStack {
                                Spacer()
                                Text("Delete Medication")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Medication" : "Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .confirmationDialog(
                "Delete Medication?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    delete()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove \(name) from your medication list.")
            }
        }
    }

    private func save() {
        let nextId = (viewModel.medications.map { $0.id }.max() ?? 0) + 1
        let med = Medication(
            id: medication?.id ?? nextId,
            name: name,
            frequency: frequency,
            ports: portsString,
            notes: notes,
            isKeyDrug: isKeyDrug
        )

        if isEditing {
            viewModel.updateMedication(med)
        } else {
            viewModel.addMedication(med)
        }

        dismiss()
    }

    private func delete() {
        if let med = medication {
            viewModel.deleteMedication(med)
        }
        dismiss()
    }
}

#Preview {
    AddMedicationSheet(medication: nil)
        .environmentObject(PillBackViewModel())
}
