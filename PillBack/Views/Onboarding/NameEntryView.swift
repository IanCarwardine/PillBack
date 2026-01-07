// NameEntryView.swift
// Onboarding screen for entering user's name - v0.4 Design

import SwiftUI

/// Screen for entering user's name during onboarding
struct NameEntryView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.metrics) var metrics
    let onContinue: () -> Void
    let onBack: (() -> Void)?

    @State private var name = ""
    @FocusState private var isFocused: Bool

    init(onContinue: @escaping () -> Void, onBack: (() -> Void)? = nil) {
        self.onContinue = onContinue
        self.onBack = onBack
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress (step 1 of 6 after Welcome)
            OnboardingProgressView(currentStep: 1, totalSteps: 6)
                .padding(.top, 20)

            Spacer()

            // Green circle with person icon
            ZStack {
                Circle()
                    .fill(viewModel.currentTheme.colors.accent)
                    .frame(width: 100, height: 100)

                Image(systemName: "person.fill")
                    .font(.system(size: 44))
                    .foregroundColor(viewModel.currentTheme.colors.bgPrimary)
            }
            .padding(.bottom, 40)

            // Title
            Text("What should we call you?")
                .font(.system(size: metrics.titleSize, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                .padding(.bottom, 32)

            // Name input - tap to focus, tap outside to dismiss
            TextField("Your name", text: $name)
                .font(.system(size: 18))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.currentTheme.colors.bgCard)
                )
                .focused($isFocused)
                .onSubmit {
                    if isValid {
                        saveName()
                    }
                }
                .padding(.horizontal, metrics.horizontalPadding + 16)

            Spacer()
            Spacer()

            // Navigation buttons
            HStack(spacing: 16) {
                // Back button
                if let onBack = onBack {
                    Button(action: {
                        HapticManager.selectionChanged()
                        isFocused = false
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

                // Continue button
                Button(action: saveName) {
                    HStack(spacing: 6) {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(isValid ? .black : viewModel.currentTheme.colors.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isValid
                                  ? viewModel.currentTheme.colors.accent
                                  : viewModel.currentTheme.colors.bgElevated)
                    )
                }
                .disabled(!isValid)
            }
            .padding(.horizontal, metrics.horizontalPadding)
            .padding(.bottom, 50)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Tap outside text field to dismiss keyboard
            isFocused = false
        }
        .onAppear {
            // Load existing name if user navigates back
            if viewModel.userName != "My Name" && !viewModel.userName.isEmpty {
                name = viewModel.userName
            }
        }
    }

    private func saveName() {
        isFocused = false
        HapticManager.impact(.medium)
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty {
            viewModel.setUserName(trimmedName)
        }
        onContinue()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        NameEntryView(
            onContinue: { print("Continue tapped") },
            onBack: { print("Back tapped") }
        )
    }
    .environmentObject(PillBackViewModel())
    .environment(\.metrics, ResponsiveMetrics())
}
