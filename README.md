# MusicShuffle

A compact SwiftUI Apple Music shuffle wheel for macOS, with a WidgetKit companion.

MusicShuffle is a small native Swift/SwiftUI menubar app for shuffling through a personal Apple Music library — a tactile iPod Shuffle-style wheel with a WidgetKit companion. This repository is an early dogfood MVP.

This project is an early dogfood MVP. It is not yet App Store-ready: production distribution still needs Apple Developer signing, MusicKit entitlements, sandbox review, and a release pipeline.

## What This MVP Fixes

- No AppleScript string interpolation: playback uses MusicKit directly.
- Authorization is awaited from the SwiftUI task lifecycle instead of racing from initialization.
- Listening history only records a real `Song` after playback succeeds.
- Apple Music library reads are paginated in bounded 50-item pages, with a 250-song MVP cap.
- The UI is a compact Tahoe-inspired widget with a physical iPod Shuffle-style wheel. The front face shows what's playing and surfaces permission, loading, and error states inline; the corner gear flips to a separate settings face where you choose all songs, recently added, or a playlist. The menubar icon's context menu adds Shuffle Now and Stop Playback shortcuts.
- A small WidgetKit extension is bundled with the app. Its dial opens MusicShuffle and triggers a shuffle through the `musicshuffle://shuffle` URL route.

## Requirements

- macOS 14+ (Sonoma or later)
- Xcode 16+ or Swift 6+
- Active Apple Music subscription

## Build & Run

```bash
git clone https://github.com/elliotreich/musicshuffle-macos.git
cd musicshuffle-macos

# SwiftPM (verifies the package compiles)
swift build -c release

# Packaged app bundle (preferred dogfood path)
./Scripts/build_app.sh
./Scripts/launch_dogfood.sh
# -> /Applications/MusicShuffle.app

# Or open in Xcode
open Package.swift
```

The build script creates a local app bundle under `outputs/` as a generated artifact. That directory is intentionally ignored by Git; the installed dogfood copy lives at `/Applications/MusicShuffle.app`.

The first launch asks macOS for Apple Music access. The app requires a signed-in Apple Music account and MusicKit capability/entitlement in a production Developer ID build; the local unsigned build is intended for personal dogfooding on this Mac.

`Preview/index.html` is a static visual preview of the same panel if you want to inspect the direction without launching the native app.

## Tests

No automated test suite yet — verification is manual:

- `swift build` checks the package compiles on Swift 6.
- Launch the app and exercise Shuffle Now / Stop, permission states, and the Widget route `musicshuffle://shuffle`.

A future test target could cover the paginated library reads and playback state without needing a real Apple Music account.

## Maintenance

- **Bundle ID / signing:** change the identifier in `Package.swift` / `Scripts/build_app.sh` and sign with your own Apple Developer team before distributing.
- **Widget:** `WidgetSources/MusicShuffleWidget.swift` — shares the same source bundle; rebuild after changes.
- **Updates:** `git pull && ./Scripts/build_app.sh` — no data migration; settings are in `UserDefaults`.

## Repository Status

This project is published under the MIT License at https://github.com/elliotreich/musicshuffle-macos.
