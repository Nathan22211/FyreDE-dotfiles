#!/bin/bash
export PATH="$HOME/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH"

status=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')
if [ "$status" == "yes" ]; then
    echo ""
else
    echo ""
fi
