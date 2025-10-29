if command -v tailscaled &> /dev/null; then
    STATUS=$(systemctl is-active tailscaled)
    if [ "$STATUS" == "active" ]; then
        OPTIONS+="Disconnect Tailscale\n"
    else
        OPTIONS+="Connect Tailscale\n"
    fi
fi

$OPTIONS+="Connect Wi-FI\n"

# Check if a wireless adapter (e.g., wlan0 or any 'wl*' interface) exists
WIFI_IFACE=$(ip link | awk -F: '/^[0-9]+: wl/ {print $2; exit}')

if [ -n "$WIFI_IFACE" ]; then
    if [ "$HOTSPOT_ENABLED" == "true" ]; then
        OPTIONS+="Disable Hotspot\n"
    else
        OPTIONS+="Enable Hotspot\nRestart Hotspot\n"
    fi
fi

$OPTIONS=$(echo -e "$OPTIONS" | wofi -d "Internet: " --style "$WOFI_THEME"/wofi/style.css)
case $OPTIONS in
    "Disconnect Tailscale")
        systemctl stop tailscaled
        ;;
    "Connect Tailscale")
        systemctl start tailscaled
        ;;
    "Connect Wi-FI")
        wofi-wifi-menu.sh
        ;;
    "Disable Hotspot")
        /opt/system/lib/internet/hotspot.sh stop    
        $HOTSPOT_ENABLED="false"
        ;;
    "Enable Hotspot")
        /opt/system/lib/internet/hotspot.sh start
        $HOTSPOT_ENABLED="true"
        ;;
    "Restart Hotspot")
        /opt/system/lib/internet/hotspot.sh restart
        $HOTSPOT_ENABLED="true"
        ;;
esac