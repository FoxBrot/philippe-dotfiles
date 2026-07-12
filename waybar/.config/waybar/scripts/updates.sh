#!/usr/bin/env bash
# ============================================================
# updates.sh — count available Arch updates for Waybar
# Requires: pacman-contrib (for checkupdates)
# Output: JSON consumed by custom/updates
# ============================================================

updates=$(checkupdates 2>/dev/null | wc -l)

if [ "$updates" -gt 0 ]; then
    printf '{"text": " %s", "tooltip": "%s updates available", "class": "pending"}\n' \
        "$updates" "$updates"
else
    printf '{"text": " 0", "tooltip": "System is up to date", "class": "updated"}\n'
fi
