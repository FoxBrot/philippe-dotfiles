#!/usr/bin/env bash
# ============================================================
# powermenu.sh — Rofi power menu for Waybar
#   Actions: Shutdown, Reboot, Suspend, Lock, Logout
# Requires: rofi(-wayland), a lock tool (hyprlock), and that
#           your session is managed by systemd + Hyprland
# ============================================================

# Menu entries (icons are Nerd Font glyphs)
shutdown=" Shutdown"
reboot=" Reboot"
suspend=" Suspend"
lock=" Lock"
logout=" Logout"

# Build the menu and pipe to Rofi
chosen=$(printf '%s\n' "$shutdown" "$reboot" "$suspend" "$lock" "$logout" \
    | rofi -dmenu -i -p "Power" -theme-str 'window {width: 200px;}')

case "$chosen" in
    "$shutdown") systemctl poweroff ;;
    "$reboot")   systemctl reboot ;;
    "$suspend")  systemctl suspend ;;
    "$lock")     hyprlock ;;
    "$logout")   hyprctl dispatch exit ;;
esac
