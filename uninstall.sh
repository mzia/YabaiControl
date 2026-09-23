#!/usr/bin/env bash
set -euo pipefail

echo "=================================================================="
echo "           Uninstalling YabaiControl, yabai, and skhd            "
echo "=================================================================="

# 1. Stop running processes
echo "==> [1/4] Stopping background daemons and application..."
pkill -x "YabaiControl" 2>/dev/null || true
pkill -x "yabai" 2>/dev/null || true
pkill -x "skhd" 2>/dev/null || true

# 2. Unload and remove launchd LaunchAgents
echo "==> [2/4] Removing LaunchAgents..."
if [ -f "$HOME/Library/LaunchAgents/com.asmvik.yabai.plist" ]; then
  launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.asmvik.yabai.plist" 2>/dev/null || true
  rm -f "$HOME/Library/LaunchAgents/com.asmvik.yabai.plist"
fi

if [ -f "$HOME/Library/LaunchAgents/com.koekeishiya.skhd.plist" ]; then
  launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.koekeishiya.skhd.plist" 2>/dev/null || true
  rm -f "$HOME/Library/LaunchAgents/com.koekeishiya.skhd.plist"
fi

# 3. Remove ~/.local/bin symlinks
echo "==> [3/4] Removing CLI symlinks in ~/.local/bin..."
rm -f "$HOME/.local/bin/yabai" "$HOME/.local/bin/skhd"

# 4. Remove the application bundle from /Applications
echo "==> [4/4] Removing /Applications/YabaiControl.app..."
rm -rf "/Applications/YabaiControl.app"
rm -rf "$HOME/Applications/YabaiControl.app"

# Optional: Clean up configs if specified with --all
if [ "${1:-}" = "--all" ]; then
  echo "==> Removing ~/.yabairc and ~/.skhdrc configurations..."
  rm -f "$HOME/.yabairc" "$HOME/.skhdrc"
fi

echo "=================================================================="
echo " Uninstallation Complete! All services and apps have been removed."
echo " Native macOS window management is fully restored."
echo "=================================================================="
