# App Store submission checklist

Everything in this folder follows the [fastlane `deliver`](https://docs.fastlane.tools/actions/deliver/)
layout, so `fastlane deliver --metadata_path AppStore/metadata --screenshots_path AppStore/screenshots`
uploads it, but each file is plain text and can be pasted into App Store Connect by hand.

## Already done in the repo

- [x] 1024×1024 App Store icon with no alpha channel (`Brushwise/Resources/Assets.xcassets/AppIcon.appiconset`).
- [x] Launch screen colour matches the in-app dark theme (no light flash on launch).
- [x] Privacy manifest `Brushwise/Resources/PrivacyInfo.xcprivacy` (UserDefaults, reason CA92.1; no tracking; no collected data).
- [x] `ITSAppUsesNonExemptEncryption = NO`, so no export-compliance questions at upload.
- [x] HealthKit usage strings and entitlement; write-only access; nothing read.
- [x] Notification permission is requested in context (after the first routine or a reminder-setting change), not on first launch.
- [x] Privacy policy (`PRIVACY.md`) and support page (`SUPPORT.md`).
- [x] Listing copy in `metadata/en-US`, review notes in `metadata/review_information/notes.txt`.
- [x] 6.9-inch (1320×2868) screenshots in `screenshots/en-US`.

## Before the first upload

1. **Host the privacy policy and support page at a public URL.** The GitHub repo is private, so
   the URLs in `metadata/en-US/privacy_url.txt` and `support_url.txt` will 404 for reviewers until
   the repo is made public or the two Markdown files are published elsewhere (GitHub Pages, a
   personal site). Apple requires a working privacy-policy URL for every app that uses HealthKit
   (guideline 5.1.3). Update the two `.txt` files if the address changes.
2. **App ID capability.** In the Apple Developer portal, the App ID `com.alexcollins.brushwise`
   must have **HealthKit** enabled. Xcode's automatic signing adds it the first time you archive
   while signed in to the team (`6T4RVD5724`).
3. **Create the app record** in App Store Connect: iOS, name `Brushwise`, bundle ID
   `com.alexcollins.brushwise`, SKU `brushwise-ios`, primary language English (U.K. or U.S., to taste).

## In App Store Connect

- **Category:** Health & Fitness (primary), Lifestyle (secondary).
- **Age rating:** answer "None" to every question → 4+.
- **App Privacy:** choose **Data Not Collected**. Brushwise stores routine history and settings
  only on the device, never transmits anything, and HealthKit data written with the user's
  permission is not collected by the developer.
- **Pricing:** Free. No in-app purchases.
- **Content rights:** the app contains no third-party content (all art and sounds are generated in code).
- **Review information:** paste `metadata/review_information/notes.txt`; add your contact
  phone and e-mail. No demo account is needed (there is no sign-in).
- **Screenshots:** upload the 6.9-inch set from `screenshots/en-US`. App Store Connect scales
  them for smaller iPhones. The app is iPhone-only (`TARGETED_DEVICE_FAMILY = 1`), so no iPad set is required.

## Build and upload

```bash
xcodegen generate
xcodebuild -project Brushwise.xcodeproj -scheme Brushwise -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/Brushwise.xcarchive archive \
  -allowProvisioningUpdates
```

Then either **Product → Archive** in Xcode and use the Organizer's *Distribute App → App Store
Connect*, or export with `xcodebuild -exportArchive` and upload with Transporter.

Bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in `project.yml` for each new build
(`CURRENT_PROJECT_VERSION` must increase for every upload of the same marketing version).

## Regenerating screenshots

Boot an iPhone 17 Pro Max simulator, build the Debug app, install it, then use the demo
launch arguments documented in `README.md`, for example:

```bash
xcrun simctl launch <udid> com.alexcollins.brushwise -skipNotifications 1 -demoHistory 1
xcrun simctl io <udid> screenshot AppStore/screenshots/en-US/1-home.png
```
