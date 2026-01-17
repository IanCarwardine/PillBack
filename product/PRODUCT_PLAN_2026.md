# PillBack Product Plan 2026

**Version:** 1.0
**Date:** January 16, 2026
**Author:** Product Management

---

## Executive Summary

This document outlines the product roadmap for PillBack iOS from MVP release through V1.0 feature completion. The plan aligns with the clinical trial requirements at Ottawa Hospital Movement Disorders Clinic while building toward a broader market release.

---

## 1. Product Vision

### Mission Statement
> PillBack helps Parkinson's patients maintain medication adherence through simple reminders and precise timing tracking, enabling better symptom management and clinical outcomes.

### Success Metrics

| Metric | MVP Target | V1 Target |
|--------|------------|-----------|
| Setup completion rate | > 90% | > 95% |
| Daily active usage | > 80% | > 85% |
| Dose confirmation rate | > 75% | > 85% |
| App crashes per session | < 0.1% | < 0.01% |
| User satisfaction (NPS) | > 50 | > 70 |

---

## 2. Release Timeline

```
2026 Timeline
=============

January
├── Week 3-4: MVP Feature Freeze & Testing
│   ├── Device testing matrix
│   ├── Notification validation
│   └── Export format validation

February
├── Week 1-2: Beta Testing
│   ├── TestFlight distribution
│   ├── Clinical team feedback
│   └── Bug fixes
├── Week 3: App Store Submission
│   ├── Final build
│   ├── App Store Connect setup
│   └── Review submission
├── Week 4: MVP Release
│   └── v1.0.0 on App Store

March - May
├── Clinical Trial Period
│   ├── Monitor usage patterns
│   ├── Collect feedback
│   └── Bug fixes as needed

June - August
├── V1.1 Development
│   ├── OCR Scanner integration
│   ├── Easy Mode accessibility
│   └── Enhanced themes

September
├── V1.1 Release
│   └── Feature-complete V1
```

---

## 3. MVP Release Plan (v1.0.0)

### 3.1 Scope Definition

#### Included Features

| Feature | Description | Priority |
|---------|-------------|----------|
| **Onboarding** | 7-step guided setup | Must Have |
| **Schedule Display** | 6-port visual grid | Must Have |
| **Dose Reminders** | Cascade notifications | Must Have |
| **One-Tap Marking** | Tap to confirm dose | Must Have |
| **History View** | Past doses with timing | Must Have |
| **CSV Export** | Clinical data export | Must Have |
| **Streak Tracking** | Adherence motivation | Should Have |
| **Settings** | Basic configuration | Should Have |

#### Hidden Features (Present but not exposed)

| Feature | Reason | V1 Action |
|---------|--------|-----------|
| OCR Scanner | Complexity for MVP | Expose in V1.1 |
| Easy Mode | Testing needed | Expose in V1.1 |
| Audio Feedback | Not in MVP spec | Expose in V1.1 |
| Theme Selector | Simplify MVP UX | Expose in V1.1 |
| Motion Detection | Research feature | Keep hidden |

### 3.2 App Store Preparation

#### Metadata Requirements

| Item | Status | Owner | Deadline |
|------|--------|-------|----------|
| App Name | "PillBack - Medication Timer" | Product | Feb 1 |
| Subtitle | "Parkinson's Adherence Tracker" | Product | Feb 1 |
| Description (Short) | 170 chars | Product | Feb 1 |
| Description (Full) | 4000 chars max | Product | Feb 1 |
| Keywords | 100 chars | Product | Feb 1 |
| Category | Health & Fitness | Product | Feb 1 |
| Privacy Policy URL | Required | Legal | Feb 1 |
| Support URL | Required | Product | Feb 1 |
| Marketing URL | Optional | Marketing | Feb 15 |

#### Visual Assets Required

| Asset | Specs | Status |
|-------|-------|--------|
| App Icon | 1024x1024 PNG | ✅ Complete |
| Screenshots (6.7") | 1290x2796 (6 required) | Pending |
| Screenshots (6.5") | 1284x2778 (6 required) | Pending |
| Screenshots (5.5") | 1242x2208 (6 required) | Pending |
| App Preview Video | 30 sec max (optional) | Not planned |

#### Review Information

| Item | Content |
|------|---------|
| Demo Account | Not required (local data) |
| Notes for Reviewer | "Health app for medication timing. All data stored locally. No backend integration." |
| Contact Info | [TBD] |

### 3.3 Privacy & Compliance

#### Data Handling

| Data Type | Collected | Shared | Purpose |
|-----------|-----------|--------|---------|
| Medication names | Local only | No | Display/reminders |
| Dose times | Local only | No | Adherence tracking |
| User name | Local only | No | Personalization |
| Notification tokens | Local only | No | Reminders |

#### Privacy Nutrition Label

```
Data Not Collected
- We do not collect any data
- All data stored locally on device
- No analytics or tracking
- No backend servers
```

#### Health App Considerations

- [ ] HIPAA not applicable (no PHI transmitted)
- [ ] No HealthKit integration in MVP
- [ ] Privacy policy must state local-only storage
- [ ] Age restriction: 4+ (no objectionable content)

### 3.4 Release Checklist Summary

See detailed checklist in `dev-docs/APP_STORE_CHECKLIST.md`

---

## 4. V1.1 Development Plan

### 4.1 Feature Additions

| Feature | Description | Priority | Effort |
|---------|-------------|----------|--------|
| **OCR Scanner** | Scan medication labels | High | 2 weeks |
| **Easy Mode** | Swipe-to-confirm interface | High | 1 week |
| **Audio Feedback** | Configurable sounds | Medium | 3 days |
| **Theme Selector** | 4 theme options | Medium | 2 days |
| **Widgets** | Home screen widget | Medium | 1 week |

### 4.2 Feature Details

#### 4.2.1 OCR Scanner (High Priority)

**Goal:** Reduce medication entry friction

**Implementation:**
- OCRService already complete
- Complete OCRScannerView integration
- Add "Scan Label" button to medication input
- Parse: Drug name, strength, directions
- Privacy: No storage of label images

**Acceptance Criteria:**
- [ ] Camera permission requested appropriately
- [ ] Photo library fallback available
- [ ] 80%+ accuracy on clear labels
- [ ] Manual edit available after scan
- [ ] No PHI extracted (pharmacy, patient info filtered)

#### 4.2.2 Easy Mode (High Priority)

**Goal:** Accessibility for Parkinson's patients with tremor

**Implementation:**
- EasyModeView already complete
- Add Settings toggle to enable
- Optional onboarding tip for new users
- Triple-tap to exit Easy Mode

**Acceptance Criteria:**
- [ ] Swipe gesture threshold adjustable
- [ ] Large visual feedback during swipe
- [ ] Haptic confirmation
- [ ] VoiceOver compatible
- [ ] Exit method discoverable

#### 4.2.3 Audio Feedback (Medium Priority)

**Goal:** Multi-sensory confirmation

**Implementation:**
- AudioFeedbackService already complete
- Add Settings picker for sound selection
- 5 sound options + silent
- Respect system mute switch

**Acceptance Criteria:**
- [ ] Sounds play on dose confirmation
- [ ] Volume follows system settings
- [ ] Works with haptics enabled/disabled
- [ ] Silent option available

#### 4.2.4 Theme Selector (Medium Priority)

**Goal:** User preference for visual comfort

**Implementation:**
- All 4 themes already implemented
- Add theme picker to Settings
- Preview before selection
- Persist selection

**Acceptance Criteria:**
- [ ] All themes render correctly
- [ ] Immediate preview on selection
- [ ] Selection persists across launches
- [ ] High Contrast meets WCAG AA

#### 4.2.5 Home Screen Widget (Medium Priority)

**Goal:** At-a-glance next dose visibility

**Implementation:**
- New WidgetKit extension
- Small widget: Next dose time
- Medium widget: Next dose + streak
- App Group for data sharing

**Acceptance Criteria:**
- [ ] Widget updates on dose taken
- [ ] Tap opens app to relevant dose
- [ ] Timeline updates correctly
- [ ] Battery efficient

### 4.3 V1.1 Timeline

```
June 2026
├── Week 1-2: OCR Scanner Integration
│   ├── Complete UI views
│   ├── Integration testing
│   └── Label parsing validation

├── Week 3-4: Easy Mode & Audio
│   ├── Settings integration
│   ├── Accessibility testing
│   └── Sound asset finalization

July 2026
├── Week 1-2: Theme Selector & Widgets
│   ├── Settings UI polish
│   ├── WidgetKit extension
│   └── App Group setup

├── Week 3-4: Testing & Release
│   ├── Full regression testing
│   ├── Beta distribution
│   └── App Store update submission

August 2026
├── Week 1: V1.1 Release
```

---

## 5. Future Roadmap (V1.2+)

### 5.1 Planned Features

| Version | Feature | Description | Status |
|---------|---------|-------------|--------|
| V1.2 | Apple Watch | Companion app | Planning |
| V1.2 | HealthKit | Medication adherence data | Planning |
| V1.3 | Clinician Portal | Web dashboard | Research |
| V1.3 | Cloud Backup | iCloud sync | Research |
| V2.0 | Caregiver Alerts | Remote notifications | Research |

### 5.2 Research Items

| Item | Description | Decision Needed |
|------|-------------|-----------------|
| **Backend** | Should PillBack have a backend? | Post-trial feedback |
| **Multi-user** | Family/caregiver accounts | Market research |
| **Insurance** | Integration with pharmacy systems | Partner exploration |
| **Wearables** | Beyond Apple Watch | Market research |

---

## 6. Resource Requirements

### 6.1 MVP Release

| Role | Effort | Notes |
|------|--------|-------|
| iOS Developer | 2 weeks | Testing & polish |
| QA | 1 week | Device testing matrix |
| Product | 3 days | App Store assets |
| Legal | 2 days | Privacy policy |

### 6.2 V1.1 Development

| Role | Effort | Notes |
|------|--------|-------|
| iOS Developer | 6 weeks | Feature development |
| Designer | 1 week | Widget design |
| QA | 2 weeks | Feature testing |
| Product | 1 week | Documentation |

---

## 7. Risk Management

### 7.1 MVP Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| App Store rejection | Low | High | Pre-review checklist, clear privacy |
| Notification failures | Medium | High | Extensive device testing |
| Clinical trial issues | Medium | High | Beta with clinical team |
| Performance issues | Low | Medium | Profiling on older devices |

### 7.2 V1.1 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| OCR accuracy issues | Medium | Medium | Fallback to manual entry |
| Widget reliability | Medium | Low | Timeline testing |
| Accessibility gaps | Low | High | VoiceOver testing |

---

## 8. Success Criteria

### 8.1 MVP Success (Q1 2026)

- [ ] App Store approval within 2 submission attempts
- [ ] Zero critical bugs in first 2 weeks
- [ ] Clinical trial enrollment begins
- [ ] 90%+ onboarding completion rate

### 8.2 V1.1 Success (Q3 2026)

- [ ] OCR accuracy > 80% on clear labels
- [ ] Easy Mode adoption > 30% of users
- [ ] Widget engagement measurable
- [ ] No increase in crash rate

### 8.3 Annual Success (End of 2026)

- [ ] Clinical trial data collection complete
- [ ] Positive feedback from Movement Disorders Clinic
- [ ] Foundation for broader market launch
- [ ] Clear roadmap for V2.0

---

## Appendix A: Competitive Analysis

| Competitor | Strengths | Weaknesses | PillBack Advantage |
|------------|-----------|------------|-------------------|
| Medisafe | Large user base, social features | Complex UI, ads | Simplicity, no ads |
| Pill Reminder | Simple | Limited tracking | Better adherence metrics |
| MyTherapy | Health tracking | Overwhelming features | Focused on timing |
| Round Health | Nice design | No export | Clinical trial focus |

---

## Appendix B: User Personas

### Primary: Clinical Trial Participant

- **Age:** 55-75
- **Condition:** Parkinson's disease
- **Tech Comfort:** Moderate
- **Need:** Precise medication timing
- **Pain Point:** Remembering exact dose times

### Secondary: Caregiver

- **Age:** 40-65
- **Role:** Family caregiver
- **Tech Comfort:** Moderate to high
- **Need:** Peace of mind
- **Pain Point:** Can't always be present

### Tertiary: Clinician

- **Role:** Movement disorders specialist
- **Tech Comfort:** High
- **Need:** Adherence data
- **Pain Point:** Patient self-reporting unreliable

---

**Document Approval**

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product Manager | | | |
| Engineering Lead | | | |
| Clinical Advisor | | | |

---

**Revision History**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Jan 16, 2026 | PM | Initial version |
