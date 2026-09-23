#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
PROJECT_DIR="$(pwd)"

APP_NAME="YabaiControl"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
BIN_DIR="${RESOURCES_DIR}/bin"

echo "==> [1/4] Building ${APP_NAME} in release mode..."
swift build -c release

echo "==> [2/4] Creating macOS App Bundle (${APP_BUNDLE})..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}" "${BIN_DIR}"

# Copy app executable
cp "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Locate yabai and skhd to bundle
YABAI_SRC=""
SKHD_SRC=""

if [ -f "${PROJECT_DIR}/bin/yabai" ]; then
  YABAI_SRC="${PROJECT_DIR}/bin/yabai"
elif command -v yabai &>/dev/null; then
  YABAI_SRC="$(command -v yabai)"
elif [ -f "/opt/homebrew/bin/yabai" ]; then
  YABAI_SRC="/opt/homebrew/bin/yabai"
elif [ -f "/usr/local/bin/yabai" ]; then
  YABAI_SRC="/usr/local/bin/yabai"
fi

if [ -f "${PROJECT_DIR}/bin/skhd" ]; then
  SKHD_SRC="${PROJECT_DIR}/bin/skhd"
elif command -v skhd &>/dev/null; then
  SKHD_SRC="$(command -v skhd)"
elif [ -f "/opt/homebrew/bin/skhd" ]; then
  SKHD_SRC="/opt/homebrew/bin/skhd"
elif [ -f "/usr/local/bin/skhd" ]; then
  SKHD_SRC="/usr/local/bin/skhd"
fi

echo "==> [3/4] Bundling yabai and skhd binaries into App Bundle..."
if [ -n "$YABAI_SRC" ] && [ -f "$YABAI_SRC" ]; then
  echo "    Embedding yabai from: ${YABAI_SRC}"
  cp "$YABAI_SRC" "${BIN_DIR}/yabai"
  chmod +x "${BIN_DIR}/yabai"
else
  echo "    Warning: yabai binary not found to bundle!"
fi

if [ -n "$SKHD_SRC" ] && [ -f "$SKHD_SRC" ]; then
  echo "    Embedding skhd from: ${SKHD_SRC}"
  cp "$SKHD_SRC" "${BIN_DIR}/skhd"
  chmod +x "${BIN_DIR}/skhd"
else
  echo "    Warning: skhd binary not found to bundle!"
fi

# Create Info.plist
cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.mzia.${APP_NAME}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Ad-hoc code sign for macOS local execution with stable designated requirement
echo "==> [4/4] Ad-hoc signing app bundle and embedded binaries..."
codesign --force --deep --sign - -r='designated => identifier "com.mzia.YabaiControl"' "${APP_BUNDLE}" 2>/dev/null || codesign --force --deep --sign - "${APP_BUNDLE}" 2>/dev/null || true

echo "=================================================================="
echo " Successfully packaged self-contained ${APP_BUNDLE}!"
echo " Embedded binaries:"
ls -lh "${BIN_DIR}"
echo "=================================================================="
echo "Launch with: open ${APP_BUNDLE}"
