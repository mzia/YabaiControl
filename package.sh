#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="YabaiControl"
VERSION="1.0.0"
DIST_DIR="dist"
APP_BUNDLE="${APP_NAME}.app"

echo "==> [1/3] Building & Bundling ${APP_NAME}..."
./bundle.sh

mkdir -p "${DIST_DIR}"

echo "==> [2/3] Generating macOS Installer Package (.pkg)..."
PKG_FILE="${DIST_DIR}/${APP_NAME}-${VERSION}.pkg"
pkgbuild --install-location "/Applications" \
         --component "${APP_BUNDLE}" \
         --identifier "com.mzia.${APP_NAME}" \
         --version "${VERSION}" \
         "${PKG_FILE}"

echo "    Created: ${PKG_FILE}"

echo "==> [3/3] Generating Drag-and-Drop Disk Image (.dmg)..."
DMG_FILE="${DIST_DIR}/${APP_NAME}-${VERSION}.dmg"
DMG_STAGE="dmg_stage"

rm -rf "${DMG_STAGE}" "${DMG_FILE}"
mkdir -p "${DMG_STAGE}"

# Copy app and create /Applications symlink
cp -R "${APP_BUNDLE}" "${DMG_STAGE}/"
ln -s /Applications "${DMG_STAGE}/Applications"

hdiutil create -volname "${APP_NAME}" \
               -srcfolder "${DMG_STAGE}" \
               -ov \
               -format UDZO \
               "${DMG_FILE}"

rm -rf "${DMG_STAGE}"
echo "    Created: ${DMG_FILE}"

echo "=================================================================="
echo " Packaging Complete! Distributable files in ${DIST_DIR}/:"
ls -lh "${DIST_DIR}"
echo "=================================================================="
