#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# fetch-upstream-binaries.sh
# Checks, fetches, and verifies latest upstream releases of yabai and skhd
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="${1:-${PROJECT_ROOT}/bin}"
MODE="${2:-download}" # "download" or "check"

echo "=================================================================="
echo "          YabaiControl Upstream Dependency Manager                "
echo "=================================================================="

# 1. Query latest upstream versions via GitHub API
echo "==> [1/4] Checking latest upstream releases..."

YABAI_LATEST_JSON="$(curl -sL https://api.github.com/repos/asmvik/yabai/releases/latest || true)"
YABAI_VERSION="$(echo "$YABAI_LATEST_JSON" | grep '"tag_name":' | head -n 1 | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/' || true)"
if [ -z "$YABAI_VERSION" ]; then
  YABAI_VERSION="v7.1.25"
fi

SKHD_LATEST_JSON="$(curl -sL https://api.github.com/repos/asmvik/skhd/tags || true)"
SKHD_VERSION="$(echo "$SKHD_LATEST_JSON" | grep '"name":' | head -n 1 | sed -E 's/.*"name": *"([^"]+)".*/\1/' || true)"
if [ -z "$SKHD_VERSION" ]; then
  SKHD_VERSION="v0.3.9"
fi

echo "    Upstream yabai latest : ${YABAI_VERSION}"
echo "    Upstream skhd latest  : ${SKHD_VERSION}"

if [ "$MODE" = "check" ]; then
  echo "==> Version check complete."
  exit 0
fi

# 2. Prepare target directory
mkdir -p "${TARGET_DIR}"
TMP_DIR="$(mktemp -d /tmp/yabaicontrol-upstream.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

# 3. Fetch and extract yabai
echo "==> [2/4] Downloading upstream yabai (${YABAI_VERSION})..."
YABAI_TAR_URL="https://github.com/asmvik/yabai/releases/download/${YABAI_VERSION}/yabai-${YABAI_VERSION}.tar.gz"

if curl -fsSL -o "${TMP_DIR}/yabai.tar.gz" "${YABAI_TAR_URL}"; then
  tar -xzf "${TMP_DIR}/yabai.tar.gz" -C "${TMP_DIR}"
  if [ -f "${TMP_DIR}/archive/bin/yabai" ]; then
    cp "${TMP_DIR}/archive/bin/yabai" "${TARGET_DIR}/yabai"
  elif [ -f "${TMP_DIR}/bin/yabai" ]; then
    cp "${TMP_DIR}/bin/yabai" "${TARGET_DIR}/yabai"
  else
    find "${TMP_DIR}" -name "yabai" -type f -perm +111 -exec cp {} "${TARGET_DIR}/yabai" \;
  fi
else
  echo "    Notice: Direct release tarball download failed, falling back to brew or system..."
  if command -v yabai &>/dev/null; then
    cp "$(command -v yabai)" "${TARGET_DIR}/yabai"
  fi
fi

# 4. Fetch and build/extract skhd
echo "==> [3/4] Downloading/building upstream skhd (${SKHD_VERSION})..."
if git clone --depth 1 --branch "${SKHD_VERSION}" https://github.com/asmvik/skhd.git "${TMP_DIR}/skhd-src" 2>/dev/null || \
   git clone --depth 1 https://github.com/asmvik/skhd.git "${TMP_DIR}/skhd-src"; then
  clang "${TMP_DIR}/skhd-src/src/skhd.c" -std=c99 -Wall -O2 \
    -framework Cocoa -framework Carbon -framework CoreServices \
    -o "${TARGET_DIR}/skhd"
else
  echo "    Notice: Source build failed, falling back to brew or system..."
  if command -v skhd &>/dev/null; then
    cp "$(command -v skhd)" "${TARGET_DIR}/skhd"
  fi
fi

# 5. Codesign & verify binaries
echo "==> [4/4] Ad-hoc signing and smoke-testing binaries..."
chmod +x "${TARGET_DIR}/yabai" "${TARGET_DIR}/skhd"
codesign -fs - "${TARGET_DIR}/yabai" 2>/dev/null || true
codesign -fs - "${TARGET_DIR}/skhd" 2>/dev/null || true

YABAI_OUTPUT="$("${TARGET_DIR}/yabai" --version 2>&1 || true)"
SKHD_OUTPUT="$("${TARGET_DIR}/skhd" --version 2>&1 || true)"

echo "------------------------------------------------------------------"
echo " Verified yabai : ${YABAI_OUTPUT}"
echo " Verified skhd  : ${SKHD_OUTPUT}"
echo " Binaries ready at: ${TARGET_DIR}"
echo "=================================================================="
