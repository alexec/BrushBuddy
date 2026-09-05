# Backlog

Open work items for Brushwise, roughly in priority order. Tick an item off (or delete it) when it
ships; add new items at the bottom of the relevant section.

## Release

- [ ] **Publish to the App Store.** The app currently goes as far as TestFlight; a public listing
  needs the remaining manual steps in [`AppStore/CHECKLIST.md`](AppStore/CHECKLIST.md) plus a
  decision that the app is ready. Known blockers as of 2026-09-05:
  - Xcode on this Mac has no signed-in Apple Account, so `xcodebuild -exportArchive` with
    `destination: upload` fails with "No Accounts" / "Failed to Use Accounts". Either sign in
    under Xcode → Settings → Accounts (team `6T4RVD5724`), or create an App Store Connect API key
    and upload with `xcrun altool --upload-app --apiKey … --apiIssuer …`.
  - Confirm the app record (`com.alexcollins.brushwise`, SKU `brushwise-ios`) exists in
    App Store Connect, and whether build 1.0.0 (2), exported earlier on 2026-09-05, was ever
    uploaded. Bump `CURRENT_PROJECT_VERSION` in `project.yml` past the highest uploaded build.
  - Fill in App Privacy (Data Not Collected), age rating (4+), categories, pricing (Free), and
    review notes in App Store Connect, then upload the screenshot set from `AppStore/screenshots/en-US`.
  - Test the TestFlight build on a physical iPhone before submitting for review.
