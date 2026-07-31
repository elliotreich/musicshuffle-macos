#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/outputs/MusicShuffle.app/Contents/MacOS/MusicShuffle"

if [[ ! -x "$APP" ]]; then
  "$ROOT/Scripts/build_app.sh"
fi

exec "$APP"
