#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/outputs/MusicShuffle.app"
TARGET="/Applications/MusicShuffle.app"

if [[ ! -d "$SOURCE" ]]; then
  "$ROOT/Scripts/build_app.sh"
fi

ditto "$SOURCE" "$TARGET"
/usr/bin/xattr -cr "$TARGET" 2>/dev/null || true
codesign --force --deep --sign - "$TARGET"
codesign --verify --deep --strict "$TARGET"
echo "Installed and verified $TARGET"
