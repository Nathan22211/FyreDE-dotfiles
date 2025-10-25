#!/usr/bin/env bash
export PATH="$HOME/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH"
cliphist list | wofi --conf "$DATA_DIR/wofi/config" --style "$DATA_DIR/wofi/style.css" --dmenu --width 700 --height 400 | cliphist decode | wl-copy
