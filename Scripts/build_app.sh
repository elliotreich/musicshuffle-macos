#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/.build/release"
APP_DIR="$ROOT/outputs/MusicShuffle.app"
ICONSET_DIR="$ROOT/work/MusicShuffle.iconset"
WIDGET_DIR="$APP_DIR/Contents/PlugIns/MusicShuffleWidget.appex"

swift build -c release --package-path "$ROOT"
mkdir -p "$ROOT/work"
swift "$ROOT/Scripts/make_icon.swift" "$ROOT/work/musicshuffle-icon-master.png"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$ROOT/work/musicshuffle-icon-master.png" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" "$ROOT/work/musicshuffle-icon-master.png" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
done
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/MusicShuffle" "$APP_DIR/Contents/MacOS/MusicShuffle"
chmod +x "$APP_DIR/Contents/MacOS/MusicShuffle"
cp "$ROOT/Preview/index.html" "$APP_DIR/Contents/Resources/Preview.html"
iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/AppIcon.icns"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>MusicShuffle</string>
  <key>CFBundleIdentifier</key><string>com.elliotreich.MusicShuffle</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleIconName</key><string>AppIcon</string>
  <key>CFBundleName</key><string>MusicShuffle</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleSupportedPlatforms</key><array><string>MacOSX</string></array>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleURLTypes</key><array><dict>
    <key>CFBundleURLName</key><string>com.elliotreich.MusicShuffle</string>
    <key>CFBundleURLSchemes</key><array><string>musicshuffle</string></array>
  </dict></array>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSAppleMusicUsageDescription</key><string>MusicShuffle needs access to your Apple Music library to find and play your next song.</string>
</dict></plist>
PLIST

mkdir -p "$WIDGET_DIR/Contents/MacOS"
cat > "$WIDGET_DIR/Contents/Info.plist" <<'WIDGET_PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>MusicShuffleWidget</string>
  <key>CFBundleIdentifier</key><string>com.elliotreich.MusicShuffle.widget</string>
  <key>CFBundleName</key><string>MusicShuffleWidget</string>
  <key>CFBundlePackageType</key><string>XPC!</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>NSExtension</key><dict>
    <key>NSExtensionPointIdentifier</key><string>com.apple.widgetkit-extension</string>
    <key>NSExtensionPrincipalClass</key><string>MusicShuffleWidget.MusicShuffleWidgetBundle</string>
  </dict>
</dict></plist>
WIDGET_PLIST

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
swiftc -parse-as-library -target arm64-apple-macosx14.0 -sdk "$SDK_PATH" \
  -module-name MusicShuffleWidget -framework SwiftUI -framework WidgetKit \
  -o "$WIDGET_DIR/Contents/MacOS/MusicShuffleWidget" \
  "$ROOT/WidgetSources/MusicShuffleWidget.swift"
chmod +x "$WIDGET_DIR/Contents/MacOS/MusicShuffleWidget"

/usr/bin/xattr -cr "$APP_DIR" 2>/dev/null || true
codesign --force --deep --sign - "$APP_DIR"
echo "Built $APP_DIR"
