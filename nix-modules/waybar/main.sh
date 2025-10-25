#!/bin/bash
set -e

# Change to script directory
cd "$(dirname "$(readlink -f "$0")")"

# Export DATA_DIR for scripts
export DATA_DIR="$(pwd)/data"

# Launch waybar in nix-shell
nix-shell ./main.nix --run "waybar -c ./data/waybar/config -s ./data/waybar/style.css" &

# Launch clipboard managers
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &
