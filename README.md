# MusicShuffle

A macOS menubar app that shuffles tracks from your Apple Music library with a retro click-wheel interface. Unlike Apple Music's built-in shuffle (which repeats tracks and biases toward recent listens), MusicShuffle picks tracks from a defined source — your full library, a single playlist, or a genre — and plays them in a truly random order without repetition until every track in the source has been played.

## How It Works

1. **Pick a source**: Full Library, a specific Playlist, or tracks in a Genre
2. **Load all tracks**: The app loads every track from that source (up to 10,000)
3. **Shuffle**: The entire list is randomized on load
4. **Play through**: Tracks play sequentially from the shuffled list
5. **Loop only when exhausted**: Once every track has played, the list reshuffles and starts over

This gives you a true shuffle experience — no "shuffle bias," no repeats until you've heard everything in your selected source.

## Controls

The click-wheel interface mimics the classic iPod:

| Button | Action |
|---|---|
| Center button | Play / Pause |
| Top (+) | Volume up |
| Bottom (−) | Volume down |
| Left (←) | Previous track |
| Right (→) | Next track |
| Source bar | Opens source picker (Full Library / Playlist / Genre) |

## Music Source Selection

Tap the source bar at the bottom of the player to open the source picker:

- **Full Library**: Shuffles all tracks in your Apple Music library
- **Playlist**: Select from your Apple Music playlists
- **Genre**: Select a genre to shuffle only tracks in that genre

The source selection persists between launches (stored in `UserDefaults`).

## Build & Run

Requires Xcode 14+ and macOS 13+.

### Xcode

```bash
open MusicShuffle.xcodeproj
```

Select your scheme and run (⌘R). The app launches as a menubar-only app with no dock icon.

### Command Line

```bash
xcodebuild -project MusicShuffle.xcodeproj -scheme MusicShuffle build
```

## Permissions

On first launch, the app requests **Apple Music** authorization. Click "Grant Access" to allow MusicKit to read your music library and control playback.

The app uses `NSAppleScript` for volume control, which requires **System Events** access under **System Settings > Privacy & Security > Automation**.

## Tech Stack

- **Language**: Swift (SwiftUI)
- **Framework**: MusicKit (Apple Music integration)
- **UI**: MenubarExtra with custom SwiftUI views
- **Persistence**: UserDefaults (shuffle source selection)
- **Volume control**: AppleScript (`set volume output volume`)
- **Minimum OS**: macOS 13 (Ventura)

## Caveats

- Requires an active Apple Music subscription for MusicKit playback
- Volume control uses AppleScript (System Events permission may be requested)
- Track count is capped at 10,000 items per load
- Quotes/quotes in playlists — MusicKit returns tracks exactly as Apple Music provides them
