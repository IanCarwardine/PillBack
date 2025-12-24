# Contributing to PillBack iOS

## Development Setup

1. Clone the repository
2. Create Xcode project (see README.md)
3. Ensure iOS 17.0+ deployment target
4. Run tests to verify setup

## Code Style

### Swift Conventions

- Use Swift 5.9+ features where appropriate
- Follow Apple's Swift API Design Guidelines
- Use `@MainActor` for all view models
- Prefer `struct` over `class` for value types
- Use descriptive variable names

### File Organization

```swift
// ExampleView.swift
// Brief description of the file's purpose

import SwiftUI

/// Documentation comment for the main type
struct ExampleView: View {
    // MARK: - Properties
    @EnvironmentObject var viewModel: PillBackViewModel
    @State private var localState: String = ""

    // MARK: - Body
    var body: some View {
        // View implementation
    }

    // MARK: - Private Methods
    private func helperMethod() {
        // Implementation
    }
}

// MARK: - Preview
#Preview {
    ExampleView()
        .environmentObject(PillBackViewModel())
}
```

### Naming Conventions

- **Views**: `NameView.swift` (e.g., `ScheduleView.swift`)
- **View Models**: `NameViewModel.swift` (e.g., `PillBackViewModel.swift`)
- **Models**: Singular name (e.g., `Dose.swift`, `Medication.swift`)
- **Extensions**: `Type+Functionality.swift` (e.g., `Color+Hex.swift`)

## Git Workflow

### Branch Naming

- `feature/description` - New features
- `fix/description` - Bug fixes
- `refactor/description` - Code improvements
- `docs/description` - Documentation changes

### Commit Messages

Follow conventional commits format:

```
type(scope): brief description

Longer description if needed.

Closes #issue-number
```

Types:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `style` - Formatting (no code change)
- `refactor` - Code restructuring
- `test` - Adding tests
- `chore` - Maintenance

### Pull Request Process

1. Create feature branch from `main`
2. Implement changes with tests
3. Update documentation if needed
4. Submit PR with description
5. Address review feedback
6. Squash and merge when approved

## Testing Requirements

### Unit Tests Required For

- All model calculations (timing accuracy, port parsing)
- ViewModel public methods
- Service layer functions

### Test File Location

```
PillBackTests/
├── Models/
│   ├── DoseTests.swift
│   ├── MedicationTests.swift
│   └── ScheduleConfigTests.swift
└── ViewModels/
    └── PillBackViewModelTests.swift
```

### Running Tests

```bash
# Command line
xcodebuild test -scheme PillBack -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Xcode
Cmd+U
```

## Accessibility Guidelines

All UI components must support:

- **VoiceOver**: Add `.accessibilityLabel()` and `.accessibilityHint()`
- **Dynamic Type**: Use system fonts and `@ScaledMetric`
- **Color Contrast**: Minimum 4.5:1 for text
- **Tap Targets**: Minimum 44x44 points

Example:

```swift
Button(action: action) {
    Text("Take Dose")
}
.accessibilityLabel("Mark Port 1 dose as taken")
.accessibilityHint("Double tap to record this dose")
```

## Theme Support

All colors must use the theme system:

```swift
// Correct
Text("Hello")
    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

// Incorrect - hardcoded color
Text("Hello")
    .foregroundColor(.white)
```

Available theme colors:
- `bgPrimary`, `bgSecondary`, `bgCard`, `bgElevated`
- `textPrimary`, `textSecondary`, `textMuted`
- `accent`, `accentDark`
- `success`, `warning`, `danger`
- `border`

## Issue Tracking

Issues are tracked in `docs/issues/`:

- Each issue has a dedicated markdown file
- Update issue status when starting/completing work
- Reference issues in commit messages

## Code Review Checklist

- [ ] Code follows Swift style guidelines
- [ ] All public methods have documentation
- [ ] Unit tests added for new functionality
- [ ] Accessibility labels added to interactive elements
- [ ] Theme colors used (no hardcoded colors)
- [ ] No compiler warnings
- [ ] Works on iPhone and iPad
