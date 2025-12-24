// NameEntryView.swift
// Onboarding screen for entering user's name

import SwiftUI

/// Screen for entering user's name during onboarding
struct NameEntryView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let onContinue: () -> Void

    @State private var name = ""
    @FocusState private var isFocused: Bool

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(viewModel.currentTheme.colors.bgCard)
                    .frame(width: 120, height: 120)

                Image(systemName: "person.fill")
                    .font(.system(size: 56))
                    .foregroundColor(viewModel.currentTheme.colors.accent)
            }

            // Title
            VStack(spacing: 12) {
                Text("What should we call you?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                Text("This helps personalize your experience")
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
            }

            // Name input
            VStack(spacing: 8) {
                TextField("Enter your name", text: $name)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding()
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
            }
            .padding(.horizontal, 40)

            Spacer()

            // Continue button
            VStack(spacing: 12) {
                Button(action: saveName) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isValid ? viewModel.currentTheme.colors.accent : viewModel.currentTheme.colors.accent.opacity(0.5))
                        )
                }
                .disabled(!isValid)

                Button(action: skipName) {
                    Text("Skip")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(viewModel.currentTheme.colors.textMuted)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .onAppear {
            isFocused = true
        }
    }

    private func saveName() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty {
            viewModel.setUserName(trimmedName)
        }
        onContinue()
    }

    private func skipName() {
        onContinue()
    }
}

#Preview {
    NameEntryView(onContinue: {})
        .environmentObject(PillBackViewModel())
}
