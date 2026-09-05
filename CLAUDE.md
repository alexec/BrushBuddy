# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Brushwise (formerly BrushBuddy) is a free iOS app that walks the user through an oral-hygiene
routine — water flosser → floss → two-minute brush (plus tongue) → mouthwash — with a weekly
toothbrush-health check. It collects no data and uses no network; everything is on-device.
Bundle id `com.alexcollins.brushwise`, iOS 17+, SwiftUI only, no third-party dependencies.

## Commands

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen).
Regenerate it whenever `project.yml` changes or files are added/removed under `Brushwise/`:

```bash
xcodegen generate
```

Build and run the full test suite:

```bash
xcodebuild -project Brushwise.xcodeproj -scheme Brushwise \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Run a single test (add `/<methodName>` to target a single case):

```bash
xcodebuild -project Brushwise.xcodeproj -scheme Brushwise \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BrushwiseTests/RoutineEngineTests test
```

The installed XcodeGen build lacks its `SettingPresets` bundle and prints "No 'base' settings
found" (harmless), which is why `project.yml` spells out `PRODUCT_NAME`, `SDKROOT`, and every
Debug/Release setting explicitly rather than relying on XcodeGen defaults — don't remove those
in favor of the usual shorthand.

Debug builds accept launch arguments that jump straight to a screen/stage/phase, used for manual
testing and App Store screenshots (see `DemoOptions` in `Brushwise/App/BrushwiseApp.swift`):

```bash
xcrun simctl launch booted com.alexcollins.brushwise \
  -skipNotifications 1 -demoHistory 1 -demoScreen routine -demoStage brush
```

`-demoScreen routine|settings`, `-demoStage waterPick|floss|brush|mouthwash` (start the routine
from that stage), `-demoPhase stageComplete|brushCheck|finished`, `-demoHistory 1` (seed a week of
sample sessions in memory), `-skipNotifications 1` (skip the reminder permission prompt).

## Architecture

**`BrushingStage`** (`Models/BrushingStage.swift`) is the source of truth for the routine: the
four-case enum defines `recommendedOrder`, each stage's `steps` (`StageStep`: title, instruction,
duration, mouth `zone`), whether it's timed (`brush`/`mouthwash` count down; `waterPick`/`floss`
are untimed and end on a tap), its color/symbol, and its `tips` (pulled from `DentalAdvice`).
`AppSettings.orderedStages(for:)` filters `recommendedOrder` by the user's per-slot (morning/night)
on/off toggles — the enabled *set* lives in settings, but the *order* always comes from here.

**`RoutineEngine`** (`Store/RoutineEngine.swift`) is the state machine that drives one run through
a list of stages: `Phase` is `.stage → .stageComplete → (repeat) → .brushCheck → .finished`. It
uses wall-clock time via an injected `now: () -> Date` closure (not a display-link timer) so
progress survives the app backgrounding mid-brush, and `tick()` catches up over any number of
steps that elapsed while backgrounded. Timed stages auto-advance to a celebration screen after
finishing, then auto-continue after `autoAdvanceDelay` (4s) — except into `.mouthwash`, which
always waits for a deliberate tap, since the user needs a moment to go pour a cup. Tests construct
it with a fake `Clock` and call `engine.debugTick()` directly rather than waiting on a real timer.

**`Views/Routine/`** mirrors `RoutineEngine.Phase` one view per case, switched over in
`RoutineView`: `StageView` (+ `StageCompleteOverlay`) for `.stage`/`.stageComplete`,
`ToothbrushCheckView` for `.brushCheck`, `RoutineCompleteView` for `.finished`. The toothbrush
check only actually appears once every `AppSettings.brushCheckIntervalDays` (7) days
(`isBrushCheckDue`), so UI text about "what's next" must account for it being skipped most runs
rather than assuming it always follows the last stage.

**`DentalAdvice`** (`Content/DentalAdvice.swift`) centralizes every piece of user-facing guidance
text (tips, disabled-stage recommendations, the routine-order explanation). Every claim is tagged
with a source key (`[NHS-clean]`, `[ADA-brush]`, `[Cochrane]`, etc.) documented in the header
comment block, with a URL and what it supports — new or edited advice should follow the same
citation convention, and specific numbers (durations, amounts, ppm) should be checked against a
real source rather than invented.

**`BrushStore`** (`Store/BrushStore.swift`) owns and persists `AppSettings` (`UserDefaults`,
tolerant `Codable` decoding so new keys default gracefully instead of resetting old settings on
upgrade) and `[BrushingSession]` history (a JSON file in Application Support). `DaySlot` treats
4am–4pm as "morning" and the rest as "night", with the logical day boundary at 4am (`dayKey`) so a
1am brush still counts as the previous day's night routine — history/streak queries
(`BrushStore.status`, `currentStreak`) all go through `dayKey`, never the raw calendar date.

**`Services/`** are small, independent wrappers: `SoundPlayer` synthesizes cues in code (no audio
assets), `Haptics` and `NotificationManager`/`HealthManager` are thin wrappers over their
frameworks — both permission prompts are deliberately deferred to after the first completed
routine rather than requested on launch.

## Release workflow

Brushwise is iPhone-only (`TARGETED_DEVICE_FAMILY = 1`). Don't skip stages of the release
pipeline on your own:

1. Build and test yourself (simulator + `xcodebuild test`).
2. Install and launch the build on the connected physical iPhone so the human can test it by
   hand — do this before any archiving/exporting/upload talk, whenever a change is ready to try,
   not only when explicitly asked to update the device.
3. TestFlight upload is the next stage after that, and is as far as this app currently goes.
4. **The app is not ready for a public App Store release.** Treat "release"/"ship it" as meaning
   TestFlight, not a public listing, unless told otherwise.

Everything for App Store Connect lives in `AppStore/` (fastlane `deliver` layout: `metadata/`,
`screenshots/en-US`, `CHECKLIST.md` with the remaining manual steps). Bump `MARKETING_VERSION` /
`CURRENT_PROJECT_VERSION` in `project.yml` for each new build. Archive with:

```bash
xcodebuild -project Brushwise.xcodeproj -scheme Brushwise -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/Brushwise.xcarchive archive \
  -allowProvisioningUpdates
```
