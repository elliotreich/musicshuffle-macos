# MusicShuffle

MusicShuffle is a small native Swift/SwiftUI macOS menubar app for shuffling through a personal Apple Music library, with a compact WidgetKit companion.

This repository is an early dogfood MVP. It is not yet App Store-ready: production distribution still needs Apple Developer signing, MusicKit entitlements, sandbox review, and a release pipeline.

## What this MVP fixes

- No AppleScript string interpolation: playback uses MusicKit directly.
- Authorization is awaited from the SwiftUI task lifecycle instead of racing from initialization.
- Listening history only records a real `Song` after playback succeeds.
- Apple Music library reads are paginated in bounded 50-item pages, with a 250-song MVP cap.
- The UI is a compact Tahoe-inspired widget with a physical iPod Shuffle-style wheel. The front face shows what's playing and surfaces permission, loading, and error states inline; the corner gear flips to a separate settings face where you choose all songs, recently added, or a playlist. The menubar icon's context menu adds Shuffle Now and Stop Playback shortcuts.
- A small WidgetKit extension is bundled with the app. Its dial opens MusicShuffle and triggers a shuffle through the `musicshuffle://shuffle` URL route.

## Build and run

```sh
./Scripts/build_app.sh
./Scripts/launch_dogfood.sh
```

The build script creates a local app bundle under `outputs/` as a generated artifact. That directory is intentionally ignored by Git; the installed dogfood copy lives at `/Applications/MusicShuffle.app`.

The first launch asks macOS for Apple Music access. The app requires a signed-in Apple Music account and MusicKit capability/entitlement in a production Developer ID build; the local unsigned build is intended for personal dogfooding on this Mac.

`Preview/index.html` is a static visual preview of the same panel if you want to inspect the direction without launching the native app.

## Repository status

This project is published under the MIT License at https://github.com/elliotreich/musicshuffle-macos.
