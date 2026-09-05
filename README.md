# Brushwise

A free, friendly iOS app that walks you through a complete oral-hygiene routine and
nudges you toward best practice: water flosser → floss → two-minute brush (plus tongue) → mouthwash,
with a toothbrush-health check at the end.

## Features

- **Four guided stages**, each with its own animated cartoon and rotating "why / how / watch out" advice
  drawn from current NHS, ADA and Oral Health Foundation guidance.
  Every tip carries a source comment in `DentalAdvice.swift` (NHS, ADA, Oral Health Foundation, Cochrane, peer-reviewed trials).
  - Water flosser: untimed — trace the gumline, tap Next when done.
  - Floss: untimed — all four quarters, C-shape technique, tap Next when done.
  - Brush: 30 s per quadrant, then 15 s tongue. Ends with "spit, don't rinse".
  - Mouthwash: 30 s swish, with the honest advice that a separate time of day is better.
- **Distinct sounds and haptics**: a soft pluck per step, a bell arpeggio per stage, a brass fanfare at the end. Timed stages show a short celebration; untimed ones move straight on. Sounds are synthesised in code.
- **Weekly toothbrush check** at the end of a routine (once every seven days): how to spot worn bristles, a 90-day replacement counter.
- **7-day history** of morning and night routines (complete / partial / missed) plus a streak.
- **Per-stage, per-slot settings**: turn any stage off for morning or night. The app respects the choice
  but keeps recommending the full routine.
- **Reminders** at 08:00 and 20:00 by default, adjustable in Settings. The permission prompt appears
  after the first completed routine (or when reminder settings change), never on first launch.
- **Apple Health** (Settings → Apple Health) writes each completed brushing as a Tooth Brushing event with its real start and end time. Needs the HealthKit capability on the App ID for device builds.

## Building

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
xcodegen generate
open Brushwise.xcodeproj
```

Requires Xcode 26 and targets iOS 17 or later. Unit tests live in `BrushwiseTests`:

```bash
xcodebuild -project Brushwise.xcodeproj -scheme Brushwise \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Publishing

Everything needed for App Store Connect lives in `AppStore/`: listing copy and review notes in
the fastlane `deliver` layout, 6.9-inch screenshots, and `CHECKLIST.md` with the remaining
manual steps. `PRIVACY.md` and `SUPPORT.md` are the privacy policy and support page the
listing links to. The app ships a privacy manifest (`Brushwise/Resources/PrivacyInfo.xcprivacy`),
collects no data and uses no network.

## Debug launch arguments

In Debug builds, launch arguments jump straight to a screen (handy for screenshots):

```bash
xcrun simctl launch booted com.alexcollins.brushwise \
  -skipNotifications 1 -demoHistory 1 -demoScreen routine -demoStage brush
```

- `-demoScreen routine|settings`
- `-demoStage waterPick|floss|brush|mouthwash` (start the routine from that stage)
- `-demoPhase stageComplete|brushCheck|finished`
- `-demoHistory 1` seeds a week of sample sessions in memory
- `-skipNotifications 1` skips the reminder permission prompt

## Layout

```
Brushwise/
  App/         entry point, debug options
  Models/      stages, steps, sessions, settings
  Content/     all dental advice text
  Store/       persistence (BrushStore) and the routine timer (RoutineEngine)
  Services/    synthesised sounds, haptics, notifications
  Views/       home, history, settings, routine flow, Canvas animations
  Resources/   asset catalog, privacy manifest
BrushwiseTests/
AppStore/      listing metadata, screenshots, submission checklist
```

Brushwise offers general guidance and is not a substitute for advice from your own dentist.
