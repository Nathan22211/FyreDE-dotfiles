#!/usr/bin/env bash

cliphist list | wofi --conf "$WOFI_THEME/wofi/config" --style "$WOFI_THEME/wofi/style.css" --dmenu --width 700 --height 400 | cliphist decode | wl-copy
