#!/usr/bin/env bash
# ============================================================
# browser.sh — Firefox launcher / focuser for Waybar
#   Firefox running  → open a new tab + focus the window
#   Firefox closed   → launch it
# Requires: jq
# ============================================================

if hyprctl clients -j | jq -e '.[] | select(.class == "firefox")' > /dev/null; then
    # Already running: open a new tab, then focus the window
    firefox --new-tab "about:newtab"
    hyprctl dispatch focuswindow "class:firefox"
else
    # Not running: launch it
    firefox &
fi
