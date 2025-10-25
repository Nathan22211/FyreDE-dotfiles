#!/bin/bash
set -euo pipefail

script_dir="$(dirname "$(readlink -f "$0")")"
data_dir="$(cd "$script_dir/../.." && pwd)"
wofi_bin="$(command -v wofi)"

# Determine terminal emulator to use
terminal="${TERMINAL}"

clean_env=(
  HOME="$HOME"
  USER="${USER:-}"
  LOGNAME="${LOGNAME:-${USER:-}}"
  LANG="${LANG:-en_US.UTF-8}"
  LC_ALL="${LC_ALL:-${LANG:-en_US.UTF-8}}"
  XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}"
  WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}"
  DISPLAY="${DISPLAY:-}"
  DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-}"
  XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-}"
  XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-}"
  XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
  FONTCONFIG_FILE="${FONTCONFIG_FILE:-/etc/fonts/fonts.conf}"
  FONTCONFIG_PATH="${FONTCONFIG_PATH:-/etc/fonts}"
  PATH="$HOME/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:${PATH:-}"
)

cd "$HOME"
exec env -i "${clean_env[@]}" "$wofi_bin" \
  --conf "$data_dir/wofi/config" \
  --style "$data_dir/wofi/style.css" \
  --term "$terminal" \
  --show drun "$@"

