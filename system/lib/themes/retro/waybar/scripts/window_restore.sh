#!/usr/bin/env bash
set -euo pipefail

id="${1:-}"
address="${2:-}"

if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
  if [[ -n "$address" && "$address" != "0x0" ]]; then
    hyprctl dispatch setprop "address:$address" "minimized" "0" >/dev/null 2>&1 || true
    hyprctl dispatch focuswindow "address:$address"
  fi
elif [[ -n "${SWAYSOCK:-}" ]] && command -v swaymsg >/dev/null 2>&1; then
  if [[ -n "$id" ]]; then
    swaymsg "[con_id=$id] focus"
  fi
else
  # Fallback: rely on the default Waybar action.
  true
fi

