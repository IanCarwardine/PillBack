// SettingsView.swift
// Settings tab for configuring schedule and preferences

import SwiftUI

/// Settings view for app configuration
struct SettingsView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @State private var showingResetConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Personal Section
                SettingsSection(title: "Personal") {
                    SettingsNameRow()
                }

                // Schedule Section
                SettingsSection(title: "Schedule") {
                    ScheduleSettingsView()
                }

                // Appearance Section
                SettingsSection(title: "Appearance") {
                    ThemeSettingsRow()
                }

                // Data Section
                SettingsSection(title: "Data") {
                    // Export button (stub for Phase 3)
                    SettingsButton(
                        icon: "square.and.arrow.up",
                        title: "Export Data",
                        subtitle: "Coming soon",
                        action: {}
                    )
                    .disabled(true)
                    .opacity(0.5)

                    Divider()
                        .background(viewModel.currentTheme.colors.border)

                    // Reset button
                    Button(action: { showingResetConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(viewModel.currentTheme.colors.danger)
                                .frame(width: 28)

                            Text("Reset All Data")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(viewModel.currentTheme.colors.danger)

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }

                // About Section
                SettingsSection(title: "About") {
                    AboutView()
                }
            }
            .padding()
        }
        .background(viewModel.currentTheme.colors.bgPrimary)
        .confirmationDialog(
            "Reset All Data?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                viewModel.resetAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all doses, reset medications to defaults, and clear your preferences. This action cannot be undone.")
        }
    }
}

/// Reusable settings section container
struct SettingsSection<Content: View>: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)

            VStack(spacing: 0) {
                content()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.currentTheme.colors.bgCard)
            )
        }
    }
}

/// Name editing row
struct SettingsNameRow: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @State private var name: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .font(.system(size: 16))
                .foregroundColor(viewModel.currentTheme.colors.accent)
                .frame(width: 28)

            TextField("Your name", text: $name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                .focused($isFocused)
                .onAppear { name = viewModel.userName }
                .onChange(of: isFocused) { _, focused in
                    if !focused && !name.isEmpty {
                        viewModel.setUserName(name)
                    }
                }
                .onSubmit {
                    if !name.isEmpty {
                        viewModel.setUserName(name)
                    }
                }
        }
    }
}

/// Schedule configuration view
struct ScheduleSettingsView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var strategy: ScheduleStrategy
    @State private var keyDrugInterval: Int
    @State private var hasChanges = false

    init() {
        _startTime = State(initialValue: ScheduleConfig.default.startTime)
        _endTime = State(initialValue: ScheduleConfig.default.endTime)
        _strategy = State(initialValue: .equalDistribution)
        _keyDrugInterval = State(initialValue: 150)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Wake time
            HStack {
                Image(systemName: "sunrise.fill")
                    .foregroundColor(viewModel.currentTheme.colors.accent)
                    .frame(width: 28)

                Text("Wake Time")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                Spacer()

                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .onChange(of: startTime) { _, _ in hasChanges = true }
            }

            Divider()
                .background(viewModel.currentTheme.colors.border)

            // Sleep time
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(viewModel.currentTheme.colors.accent)
                    .frame(width: 28)

                Text("Sleep Time")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                Spacer()

                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .onChange(of: endTime) { _, _ in hasChanges = true }
            }

            Divider()
                .background(viewModel.currentTheme.colors.border)

            // Strategy picker
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(viewModel.currentTheme.colors.accent)
                        .frame(width: 28)

                    Text("Schedule Strategy")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                }

                Picker("Strategy", selection: $strategy) {
                    ForEach(ScheduleStrategy.allCases, id: \.self) { strat in
                        Text(strat.rawValue).tag(strat)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: strategy) { _, _ in hasChanges = true }

                Text(strategy.description)
                    .font(.system(size: 11))
                    .foregroundColor(viewModel.currentTheme.colors.textMuted)
            }

            // KEY DRUG interval (only for fixed interval)
            if strategy == .fixedInterval {
                Divider()
                    .background(viewModel.currentTheme.colors.border)

                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(viewModel.currentTheme.colors.accent)
                        .frame(width: 28)

                    Text("KEY DRUG Interval")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                    Spacer()

                    Stepper("\(keyDrugInterval) min", value: $keyDrugInterval, in: 90...240, step: 15)
                        .onChange(of: keyDrugInterval) { _, _ in hasChanges = true }
                }
            }

            // Apply button
            if hasChanges {
                Button(action: applyChanges) {
                    Text("Regenerate Schedule")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.currentTheme.colors.accent)
                        )
                }
            }
        }
        .onAppear {
            startTime = viewModel.scheduleConfig.startTime
            endTime = viewModel.scheduleConfig.endTime
            strategy = viewModel.scheduleConfig.strategy
            keyDrugInterval = viewModel.scheduleConfig.keyDrugInterval
        }
    }

    private func applyChanges() {
        let config = ScheduleConfig(
            startTime: startTime,
            endTime: endTime,
            strategy: strategy,
            keyDrugInterval: keyDrugInterval
        )
        viewModel.updateScheduleConfig(config)
        hasChanges = false
    }
}

/// Theme selection row
struct ThemeSettingsRow: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundColor(viewModel.currentTheme.colors.accent)
                    .frame(width: 28)

                Text("Theme")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                Spacer()

                Text(viewModel.currentTheme.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
            }

            HStack(spacing: 16) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button(action: { viewModel.setTheme(theme) }) {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: theme.previewColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(viewModel.currentTheme == theme ? theme.colors.accent : Color.clear, lineWidth: 3)
                                )

                            Text(theme.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

/// Reusable settings button
struct SettingsButton: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void

    init(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(viewModel.currentTheme.colors.accent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(viewModel.currentTheme.colors.textMuted)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.currentTheme.colors.textMuted)
            }
            .padding(.vertical, 8)
        }
    }
}

/// About section with app info
struct AboutView: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Version")
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                Spacer()
                Text("1.0.0 (MVP)")
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)
            }
            .font(.system(size: 14))

            Divider()
                .background(viewModel.currentTheme.colors.border)

            HStack {
                Text("Developer")
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                Spacer()
                Text("PillBack Team")
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)
            }
            .font(.system(size: 14))

            Divider()
                .background(viewModel.currentTheme.colors.border)

            Text("PillBack helps Parkinson's patients track medication timing accuracy for optimal symptom management.")
                .font(.system(size: 12))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PillBackViewModel())
}
