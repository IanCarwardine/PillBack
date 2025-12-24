// Medication.swift
// Medication model representing a single medication with dosing information

import Foundation

/// Represents a medication with its dosing schedule and port assignments
struct Medication: Identifiable, Codable, Equatable {
    let id: Int
    var name: String
    var frequency: Int
    var ports: String
    var notes: String
    var isKeyDrug: Bool

    // MARK: - Initialization

    init(id: Int, name: String, frequency: Int, ports: String, notes: String = "", isKeyDrug: Bool = false) {
        self.id = id
        self.name = name
        self.frequency = frequency
        self.ports = ports
        self.notes = notes
        self.isKeyDrug = isKeyDrug
    }

    // MARK: - Port Parsing

    /// Returns an array of port numbers this medication is assigned to
    var portNumbers: [Int] {
        if ports.contains("-") {
            // Range format: "1-6"
            let parts = ports.split(separator: "-")
            if parts.count == 2,
               let start = Int(parts[0].trimmingCharacters(in: .whitespaces)),
               let end = Int(parts[1].trimmingCharacters(in: .whitespaces)) {
                return Array(start...end)
            }
        } else if ports.contains(",") {
            // Comma-separated format: "1,3,5"
            return ports.split(separator: ",")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        } else {
            // Single port: "1"
            if let port = Int(ports.trimmingCharacters(in: .whitespaces)) {
                return [port]
            }
        }
        return []
    }

    /// Check if this medication is in a specific port
    func isInPort(_ portNumber: Int) -> Bool {
        return portNumbers.contains(portNumber)
    }
}

// MARK: - Default Medications

extension Medication {
    /// Default medications for a Parkinson's patient (clinical trial setup)
    static let defaults: [Medication] = [
        Medication(
            id: 1,
            name: "Stalevo 200/50/37mg",
            frequency: 6,
            ports: "1-6",
            notes: "Parkinson's medication - Levodopa/Carbidopa/Entacapone",
            isKeyDrug: true
        ),
        Medication(
            id: 2,
            name: "Pramipexole 0.25mg",
            frequency: 3,
            ports: "1-3",
            notes: "Dopamine agonist",
            isKeyDrug: false
        ),
        Medication(
            id: 3,
            name: "Teva-Rasagiline 1mg",
            frequency: 1,
            ports: "1",
            notes: "MAO-B inhibitor",
            isKeyDrug: false
        ),
        Medication(
            id: 4,
            name: "Citalopram 10mg",
            frequency: 1,
            ports: "1",
            notes: "Antidepressant (1/2 tablet)",
            isKeyDrug: false
        ),
        Medication(
            id: 5,
            name: "Teva-Bupropion XL 150mg",
            frequency: 1,
            ports: "1",
            notes: "Antidepressant",
            isKeyDrug: false
        ),
        Medication(
            id: 6,
            name: "Dulcolax 5mg",
            frequency: 1,
            ports: "6",
            notes: "Laxative (2 tablets)",
            isKeyDrug: false
        ),
        Medication(
            id: 7,
            name: "Zopiclone 7.5mg",
            frequency: 1,
            ports: "6",
            notes: "Sleep aid",
            isKeyDrug: false
        )
    ]
}
