#!/usr/bin/env bash
# ============================================================
# update.sh — run a full system update in a terminal
# Triggered by clicking the custom/updates module in Waybar
# ============================================================

# Run the upgrade
sudo pacman -Syu

# Keep the window open so the result is visible
echo ""
echo "Update complete. Press Enter to close."
read -r
