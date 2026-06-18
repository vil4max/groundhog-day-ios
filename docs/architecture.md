# Architecture

## Core types

- `CountdownCalculator` — interval math + unit tests
- `EventDateStorage` — `UserDefaults` + optional `NSUbiquitousKeyValueStore`

## Stack notes

SwiftUI, `@Observable`, Swift Concurrency (no Combine).

iCloud sync code is in place but disabled until a paid Apple Developer account. Until then, data stays in local `UserDefaults` only.

## Project layout

```
ios/
├── GroundhogDay.xcodeproj
├── GroundhogDay/
│   ├── Features/Countdown/   # Flip tiles, carousel, main screen
│   ├── Features/Settings/
│   ├── Features/Onboarding/
│   ├── Services/
│   ├── Models/
│   └── Resources/
└── GroundhogDayTests/
```

Xcode project path: `ios/GroundhogDay.xcodeproj`

## Enable iCloud sync (later)

1. Enroll in the [Apple Developer Program](https://developer.apple.com/programs/).
2. Xcode → **GroundhogDay** → Signing & Capabilities → **iCloud** → **Key-value storage**.
3. Use `GroundhogDay.entitlements.icloud` for ubiquity identifier.
4. Set `FeatureFlags.iCloudSyncEnabled = true` in `Config/FeatureFlags.swift`.
5. Verify on two devices with the same Apple ID.

## Build

```bash
cd ios
xcodebuild -project GroundhogDay.xcodeproj -scheme GroundhogDay \
  -destination 'platform=iOS Simulator,name=iPhone 17' build test
```
