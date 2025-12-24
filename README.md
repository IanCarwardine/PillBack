# PillBack iOS

A medication timing tracker for Parkinson's patients, designed to help track timing accuracy for doses taken from a 6-port pill organizer.

## Features

- **6-Dose Schedule Management** - Track all daily doses with configurable wake/sleep times
- **Timing Accuracy Tracking** - 5-tier scoring system (Perfect, Good, Fair, Poor, Review)
- **KEY DRUG Support** - Special handling for critical Levodopa/Carbidopa timing
- **Visual Timeline** - Collapsible sidebar showing dose status at a glance
- **Adherence Statistics** - Daily accuracy percentages and pattern detection
- **4 Themes** - Clinical, Warm, High Contrast (accessibility), Daylight
- **Onboarding Flow** - Guided setup for new users

## Screenshots

*Screenshots to be added after Xcode project creation*

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository
2. Open `PillBack.xcodeproj` in Xcode (see Setup below)
3. Select your target device/simulator
4. Build and run (Cmd+R)

### Xcode Project Setup

Since this repository contains Swift source files without an Xcode project, you need to create one:

1. Open Xcode → File → New → Project
2. Choose iOS → App
3. Configure:
   - Product Name: `PillBack`
   - Organization Identifier: `com.pillback`
   - Interface: SwiftUI
   - Language: Swift
4. Save to `PillBack_iOS/` directory
5. Delete the auto-generated `ContentView.swift` and `PillBackApp.swift`
6. Add all files from the `PillBack/` folder to the project
7. Add test files from `PillBackTests/` to the test target

## Architecture

The app follows the **MVVM (Model-View-ViewModel)** pattern:

```
PillBack/
├── Models/           # Data models (Dose, Medication, etc.)
├── ViewModels/       # PillBackViewModel - state management
├── Views/
│   ├── Components/   # Reusable UI components
│   ├── Schedule/     # Schedule tab views
│   ├── Timeline/     # Timeline sidebar views
│   ├── Medications/  # Medications tab views
│   ├── Adherence/    # Adherence tab views
│   ├── Settings/     # Settings tab views
│   └── Onboarding/   # Onboarding flow views
├── Services/         # Notification, Export (Phase 2/3)
└── Extensions/       # Color+Hex, etc.
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed architecture documentation.

## Testing

```bash
# Run unit tests
xcodebuild test -scheme PillBack -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Test Coverage

- **DoseTests** - Timing accuracy calculations, categories
- **MedicationTests** - Port parsing, Codable conformance
- **ScheduleConfigTests** - Interval calculations, defaults
- **PillBackViewModelTests** - All public methods

## Configuration

### Schedule Settings

| Setting | Default | Description |
|---------|---------|-------------|
| Wake Time | 8:00 AM | First dose time |
| Sleep Time | 8:30 PM | Last dose cutoff |
| Strategy | Equal Distribution | How doses are spaced |
| KEY DRUG Interval | 150 min | For Fixed Interval strategy |

### Themes

| Theme | Description |
|-------|-------------|
| Clinical | Dark green accent on dark background (default) |
| Warm | Brown/amber on warm dark background |
| High Contrast | Cyan on black (accessibility) |
| Daylight | Green on light background |

## Data Storage

All data is stored locally using `UserDefaults` with keys prefixed `pillback_`:

- `pillback_doses` - Daily dose schedule
- `pillback_medications` - Medication list
- `pillback_config` - Schedule configuration
- `pillback_theme` - Current theme
- `pillback_viewMode` - Full/Timeline mode
- `pillback_userName` - User's name
- `pillback_lastReset` - Midnight reset tracking

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

Proprietary

## Contact

