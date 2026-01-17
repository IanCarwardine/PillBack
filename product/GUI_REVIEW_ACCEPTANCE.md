# PillBack GUI Review & Acceptance Criteria

**Document Version:** 1.0
**Date:** January 16, 2026
**Status:** Draft for Review

---

## 1. GUI Component Inventory

### 1.1 Onboarding Views

| Component | File | Status | Design Match |
|-----------|------|--------|--------------|
| WelcomeView | `Views/Onboarding/WelcomeView.swift` | ✅ Complete | See `Onboarding-1-Welcome.png` |
| NameEntryView | `Views/Onboarding/NameEntryView.swift` | ✅ Complete | See `Onboarding-2-username.png` |
| NotificationPermissionView | `Views/Onboarding/NotificationPermissionView.swift` | ✅ Complete | Standard iOS pattern |
| WakingHoursView | `Views/Onboarding/WakingHoursView.swift` | ✅ Complete | See `Onboarding-3-setup-time.png` |
| KeyMedicationView | `Views/Onboarding/KeyMedicationView.swift` | ✅ Complete | See `Onboarding-4a-Key-Medication.png` |
| CompanionMedicationsView | `Views/Onboarding/CompanionMedicationsView.swift` | ✅ Complete | See `Onboarding-4b-Companion-Medications.png` |
| ScheduleSetupView | `Views/Onboarding/ScheduleSetupView.swift` | ✅ Complete | See `Onboarding-5-Summary.png` |
| OnboardingContainerView | `Views/Onboarding/OnboardingContainerView.swift` | ✅ Complete | Navigation wrapper |
| OnboardingProgressView | `Views/Components/OnboardingProgressView.swift` | ✅ Complete | Animated capsules |
| MedicationInputSheet | `Views/Onboarding/MedicationInputSheet.swift` | ✅ Complete | See `3-medication-input.png` |

### 1.2 Main App Views

| Component | File | Status | Design Match |
|-----------|------|--------|--------------|
| HomeView | `Views/Home/HomeView.swift` | ✅ Complete | See `Home-screen.png` |
| PortsView | `Views/Ports/PortsView.swift` | ✅ Complete | 6-port grid layout |
| PortSettingsSheet | `Views/Ports/PortSettingsSheet.swift` | ✅ Complete | Per-port configuration |
| HistoryView | `Views/History/HistoryView.swift` | ✅ Complete | Past doses list |
| SettingsView | `Views/Settings/SettingsView.swift` | ✅ Complete | See `Settings-screen.png` |
| BottomTabBar | `Views/Components/HeaderView.swift` | ✅ Complete | iOS-style tabs |

### 1.3 Supporting Components

| Component | File | Status | Purpose |
|-----------|------|--------|---------|
| DoseCardView | `Views/Schedule/DoseCardView.swift` | ✅ Complete | Individual dose display |
| TimingBadge | `Views/Components/TimingBadge.swift` | ✅ Complete | Timing accuracy indicator |
| StreakBadge | `Views/Components/StreakBadge.swift` | ✅ Complete | Streak display |
| EmptyStateView | `Views/Components/EmptyStateView.swift` | ✅ Complete | No-data state |
| ThemeSelectorView | `Views/Components/ThemeSelectorView.swift` | ✅ Complete | Theme picker |
| PillBackLogo | `Views/Components/PillBackLogo.swift` | ✅ Complete | Brand logo display |

### 1.4 Advanced Features (Beyond MVP)

| Component | File | Status | MVP Action |
|-----------|------|--------|------------|
| EasyModeView | `Views/EasyMode/EasyModeView.swift` | ✅ Complete | Hide via feature flag |
| OCRScannerView | `Views/OCR/OCRScannerView.swift` | ✅ Complete | Hide via feature flag |
| OCRResultView | `Views/OCR/OCRResultView.swift` | ✅ Complete | Hide via feature flag |
| CameraPickerView | `Views/OCR/CameraPickerView.swift` | ✅ Complete | Hide via feature flag |

---

## 2. GUI Review Process

### 2.1 Review Methodology

```
Phase 1: Static Review (Design Comparison)
    └── Compare each view to design mockups
    └── Document visual deviations
    └── Verify brand compliance

Phase 2: Functional Review (User Flows)
    └── Complete each user journey
    └── Verify navigation flows
    └── Test edge cases

Phase 3: Device Review (Responsive Verification)
    └── Test on iPhone SE (small)
    └── Test on iPhone 15 (standard)
    └── Test on iPhone 15 Pro Max (large)

Phase 4: Accessibility Review
    └── VoiceOver navigation
    └── Dynamic Type scaling
    └── Color contrast verification
```

### 2.2 Review Checklist Template

```markdown
## View Review: [View Name]

**Reviewer:** _______________
**Date:** _______________
**Device:** _______________

### Visual Compliance
- [ ] Layout matches design mockup
- [ ] Colors match theme specification
- [ ] Typography follows Typography.swift
- [ ] Spacing follows ResponsiveMetrics
- [ ] Icons/images render correctly

### Functional Compliance
- [ ] All interactive elements respond
- [ ] Navigation works correctly
- [ ] Data displays accurately
- [ ] Error states handled
- [ ] Loading states shown (if applicable)

### Responsive Compliance
- [ ] Works on iPhone SE (375pt width)
- [ ] Works on iPhone 15 (390pt width)
- [ ] Works on iPhone 15 Pro Max (430pt width)
- [ ] Safe areas respected
- [ ] Dynamic Island/notch handled

### Accessibility Compliance
- [ ] VoiceOver labels present
- [ ] Tap targets ≥ 44pt
- [ ] Contrast ratio ≥ 4.5:1
- [ ] Dynamic Type supported
- [ ] Haptic feedback appropriate

### Issues Found
| Issue | Severity | Screenshot |
|-------|----------|------------|
| | | |

### Sign-Off
- [ ] Approved for release
- [ ] Approved with issues
- [ ] Not approved
```

---

## 3. Acceptance Criteria by View

### 3.1 Onboarding Flow

#### WelcomeView Acceptance Criteria

| ID | Criterion | Test Method | Pass/Fail |
|----|-----------|-------------|-----------|
| WV-01 | PillBack logo displays centered | Visual inspection | |
| WV-02 | "Welcome" text visible | Visual inspection | |
| WV-03 | "Get Started" button navigates to NameEntryView | Tap test | |
| WV-04 | Progress capsules show step 1 of 7 | Visual inspection | |
| WV-05 | Theme colors applied correctly | Visual inspection | |

#### NameEntryView Acceptance Criteria

| ID | Criterion | Test Method | Pass/Fail |
|----|-----------|-------------|-----------|
| NE-01 | Text field accepts user input | Input test | |
| NE-02 | Keyboard appears automatically | Interaction test | |
| NE-03 | "Continue" enabled only when name entered | Input test | |
| NE-04 | Name persists after navigation | Data test | |
| NE-05 | Back button returns to WelcomeView | Navigation test | |

#### NotificationPermissionView Acceptance Criteria

| ID | Criterion | Test Method | Pass/Fail |
|----|-----------|-------------|-----------|
| NP-01 | Explanation text clearly describes benefit | Review text | |
| NP-02 | "Allow Notifications" triggers iOS permission | Tap test | |
| NP-03 | "Skip" option available | Visual inspection | |
| NP-04 | Permission result persisted | Settings check | |
| NP-05 | Progress to next step regardless of choice | Navigation test | |

#### WakingHoursView Acceptance Criteria

| ID | Criterion | Test Method | Pass/Fail |
|----|-----------|-------------|-----------|
| WH-01 | Wake time picker functional | Interaction test | |
| WH-02 | Sleep time picker functional | Interaction test | |
| WH-03 | Default times reasonable (7 AM, 10 PM) | Visual inspection | |
| WH-04 | Time range validated (wake < sleep) | Input test | |
| WH-05 | Times persist to ScheduleConfig | Data test | |

#### KeyMedicationView Acceptance Criteria

| ID | Criterion | Test Method | Pass/Fail |
|----|-----------|-------------|-----------|
| KM-01 | "Add Key Medication" button visible | Visual inspection | |
| KM-02 | Medication input sheet appears on tap | Interaction test | |
| KM-03 | Added medication displays as card | Visual inspection | |
| KM-04 | Edit functionality works | Interaction test | |
| KM-05 | Delete functionality works | Interaction test | |
| KM-06 | Cannot proceed without at least one medication | Validation test | |

#### CompanionMedicationsView Acceptance Criteria

| ID | Criterion | Test Method | Pass/Fail |
|----|-----------|-------------|-----------|
| CM-01 | "Add Companion Medication" button visible | Visual inspection | |
| CM-02 | Multiple medications can be added | Input test | |
| CM-03 | List displays all added medications | Visual inspection | |
| CM-04 | Can skip without adding companions | Navigation test | |
| CM-05 | Edit/delete for each medication | Interaction test | |

#### ScheduleSetupView Acceptance Criteria

| ID | Criterion | Test Method | Pass/Fail |
|----|-----------|-------------|-----------|
| SS-01 | 6 dose times displayed | Visual inspection | |
| SS-02 | Times calculated from waking hours | Data test | |
| SS-03 | Each dose time is tappable | Interaction test | |
| SS-04 | PortSettingsSheet opens on tap | Navigation test | |
| SS-05 | "Finish Setup" completes onboarding | Navigation test | |
| SS-06 | Schedule saved to persistence | Data test | |

### 3.2 Main App Views

#### HomeView Acceptance Criteria

| ID | Criterion | Test Method | Pass/Fail |
|----|-----------|-------------|-----------|
| HV-01 | 6-port grid displays | Visual inspection | |
| HV-02 | Current dose highlighted | Visual inspection | |
| HV-03 | Tap on port marks dose taken | Interaction test | |
| HV-04 | Status icons update correctly | State test | |
| HV-05 | Timing accuracy displays | Visual inspection | |
| HV-06 | Responsive layout on all devices | Device test | |

#### PortsView Acceptance Criteria

| ID | Criterion | Test Method | Pass/Fail |
|----|-----------|-------------|-----------|
| PV-01 | 6 ports in 2x3 grid | Visual inspection | |
| PV-02 | Port numbers visible (1-6) | Visual inspection | |
| PV-03 | Medication names displayed | Visual inspection | |
| PV-04 | Tap opens PortSettingsSheet | Interaction test | |
| PV-05 | Visual state matches dose status | State test | |

#### HistoryView Acceptance Criteria

| ID | Criterion | Test Method | Pass/Fail |
|----|-----------|-------------|-----------|
| HI-01 | Past doses listed by date | Visual inspection | |
| HI-02 | Date grouping correct | Data test | |
| HI-03 | Timing accuracy shown per dose | Visual inspection | |
| HI-04 | Export button visible | Visual inspection | |
| HI-05 | Export generates CSV file | Functional test | |
| HI-06 | Share sheet appears on export | Interaction test | |

#### SettingsView Acceptance Criteria

| ID | Criterion | Test Method | Pass/Fail |
|----|-----------|-------------|-----------|
| SE-01 | User name editable | Input test | |
| SE-02 | 24-hour format toggle works | Interaction test | |
| SE-03 | Haptic feedback toggle works | Interaction test | |
| SE-04 | Reset Data option present | Visual inspection | |
| SE-05 | Reset triggers confirmation | Interaction test | |
| SE-06 | Reset clears all data and shows onboarding | Functional test | |

### 3.3 BottomTabBar Acceptance Criteria

| ID | Criterion | Test Method | Pass/Fail |
|----|-----------|-------------|-----------|
| TB-01 | 4 tabs visible (Home, Ports, History, Settings) | Visual inspection | |
| TB-02 | Active tab highlighted | Visual inspection | |
| TB-03 | Tab icons render correctly | Visual inspection | |
| TB-04 | Tab labels readable | Visual inspection | |
| TB-05 | Tap navigates to correct view | Navigation test | |
| TB-06 | Safe area respected (bottom) | Device test | |

---

## 4. Test Procedures

### 4.1 Onboarding Test Procedure

```
TEST CASE: Complete Onboarding Flow
PRECONDITION: Fresh app install or reset data

STEPS:
1. Launch app
   EXPECTED: WelcomeView appears with logo and "Get Started"

2. Tap "Get Started"
   EXPECTED: NameEntryView appears with keyboard

3. Enter name "Test User"
   EXPECTED: "Continue" button enables

4. Tap "Continue"
   EXPECTED: NotificationPermissionView appears

5. Tap "Allow Notifications"
   EXPECTED: iOS permission dialog appears

6. Allow or deny notification permission
   EXPECTED: WakingHoursView appears

7. Set wake time to 8:00 AM
   EXPECTED: Time picker updates

8. Set sleep time to 10:00 PM
   EXPECTED: Time picker updates

9. Tap "Continue"
   EXPECTED: KeyMedicationView appears

10. Tap "Add Key Medication"
    EXPECTED: MedicationInputSheet appears

11. Enter "Sinemet" and tap "Add"
    EXPECTED: Medication card appears

12. Tap "Continue"
    EXPECTED: CompanionMedicationsView appears

13. Tap "Skip" (or add medications)
    EXPECTED: ScheduleSetupView appears

14. Review 6 dose times
    EXPECTED: Times based on waking hours

15. Tap "Finish Setup"
    EXPECTED: HomeView appears with schedule

RESULT: PASS / FAIL
NOTES:
```

### 4.2 Dose Marking Test Procedure

```
TEST CASE: Mark Dose as Taken
PRECONDITION: Onboarding complete, pending doses exist

STEPS:
1. Navigate to HomeView
   EXPECTED: 6-port grid visible

2. Identify port with pending dose
   EXPECTED: Visual indicator shows pending

3. Tap on pending dose port
   EXPECTED: Dose marked as taken

4. Verify timing accuracy displays
   EXPECTED: Badge shows Perfect/Good/Fair/Review

5. Navigate to HistoryView
   EXPECTED: Dose appears in history

6. Verify timestamp accurate
   EXPECTED: Taken time matches current time

RESULT: PASS / FAIL
NOTES:
```

### 4.3 Export Test Procedure

```
TEST CASE: Export History to CSV
PRECONDITION: At least 3 taken doses in history

STEPS:
1. Navigate to HistoryView
   EXPECTED: Doses listed

2. Tap Export/Share button
   EXPECTED: Export format options appear (if applicable)

3. Select CSV format
   EXPECTED: Share sheet appears

4. Choose "Save to Files"
   EXPECTED: File saves successfully

5. Open CSV file
   EXPECTED: Contains correct headers and data

6. Verify data accuracy
   EXPECTED: Dates, times, medications match app

RESULT: PASS / FAIL
NOTES:
```

### 4.4 Responsive Design Test Procedure

```
TEST CASE: Responsive Layout Verification
DEVICES: iPhone SE, iPhone 15, iPhone 15 Pro Max

FOR EACH DEVICE:

1. Launch app
   EXPECTED: No layout clipping

2. Complete onboarding
   EXPECTED: All elements visible and accessible

3. View HomeView
   EXPECTED: Grid layout adapts to screen size

4. View SettingsView
   EXPECTED: All options visible

5. Rotate device (if supported)
   EXPECTED: Layout remains functional

6. Test with Dynamic Type (Accessibility → Larger Text)
   EXPECTED: Text scales without breaking layout

RESULT: PASS / FAIL per device
NOTES:
```

---

## 5. Sign-Off Matrix

### 5.1 Component Sign-Off

| View | Developer | QA | Product | Date |
|------|-----------|-----|---------|------|
| WelcomeView | | | | |
| NameEntryView | | | | |
| NotificationPermissionView | | | | |
| WakingHoursView | | | | |
| KeyMedicationView | | | | |
| CompanionMedicationsView | | | | |
| ScheduleSetupView | | | | |
| HomeView | | | | |
| PortsView | | | | |
| HistoryView | | | | |
| SettingsView | | | | |
| BottomTabBar | | | | |

### 5.2 Final Release Sign-Off

| Criterion | Status | Signed By | Date |
|-----------|--------|-----------|------|
| All views pass acceptance criteria | | | |
| No critical bugs open | | | |
| Performance acceptable | | | |
| Accessibility verified | | | |
| Device matrix tested | | | |
| Export validated with clinical team | | | |

---

## Appendix A: Design Reference Files

| Design File | Location | View(s) |
|-------------|----------|---------|
| Onboarding-1-Welcome.png | design/v0.4/GUI/ | WelcomeView |
| Onboarding-2-username.png | design/v0.4/GUI/ | NameEntryView |
| Onboarding-3-setup-time.png | design/v0.4/GUI/ | WakingHoursView |
| Onboarding-4a-Key-Medication.png | design/v0.4/GUI/ | KeyMedicationView |
| Onboarding-4b-Companion-Medications.png | design/v0.4/GUI/ | CompanionMedicationsView |
| Onboarding-5-Summary.png | design/v0.4/GUI/ | ScheduleSetupView |
| Home-screen.png | design/v0.4/GUI/ | HomeView |
| Settings-screen.png | design/v0.4/GUI/ | SettingsView |

---

## Appendix B: Known Issues Log

| Issue ID | Description | Severity | Status | Target |
|----------|-------------|----------|--------|--------|
| | | | | |

---

**Document Owner:** Product & QA Team
**Review Frequency:** Weekly during release sprint
