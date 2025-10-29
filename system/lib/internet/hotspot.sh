#!/bin/bash

# --- Configuration ---
# Try to use ethernet first, then fall back to wlan if not available
if ip link show eth0 &> /dev/null && [[ $(cat /sys/class/net/eth0/operstate 2>/dev/null) == "up" ]]; then
    INTERFACE_UPSTREAM="eth0"
elif ip link show wlan0 &> /dev/null && [[ $(cat /sys/class/net/wlan0/operstate 2>/dev/null) == "up" ]]; then
    INTERFACE_UPSTREAM="wlan0"
else
    echo "No available upstream interface found (tried eth0 and wlan0)."
    exit 1
fi
CONFIG_FILE="$HOME/.config/hotspot.conf"

# Set defaults
INTERFACE_HOTSPOT="wlan0"
HOTSPOT_SSID="MyLinuxHotspot"
HOTSPOT_PASSWORD="MySecurePassword"
CHANNEL="6"
IP_ADDRESS="192.168.10.1"
DHCP_RANGE_START="192.168.10.100"
DHCP_RANGE_END="192.168.10.200"
LEASE_TIME="12h"

# If config file exists, source it to override defaults
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

# --- Functions ---
start_hotspot() {
    echo "Starting Wi-Fi hotspot..."

    # Bring up the hotspot interface with a static IP
    sudo ip addr flush dev "$INTERFACE_HOTSPOT"
    sudo ip link set "$INTERFACE_HOTSPOT" up
    sudo ip addr add "$IP_ADDRESS/24" dev "$INTERFACE_HOTSPOT"

    # Configure hostapd
    echo "interface=$INTERFACE_HOTSPOT" | sudo tee /etc/hostapd/hostapd.conf > /dev/null
    echo "ssid=$HOTSPOT_SSID" | sudo tee -a /etc/hostapd/hostapd.conf > /dev/null
    echo "hw_mode=g" | sudo tee -a /etc/hostapd/hostapd.conf > /dev/null
    echo "channel=$CHANNEL" | sudo tee -a /etc/hostapd/hostapd.conf > /dev/null
    echo "wpa=2" | sudo tee -a /etc/hostapd/hostapd.conf > /dev/null
    echo "wpa_passphrase=$HOTSPOT_PASSWORD" | sudo tee -a /etc/hostapd/hostapd.conf > /dev/null
    echo "wpa_key_mgmt=WPA-PSK" | sudo tee -a /etc/hostapd/hostapd.conf > /dev/null
    echo "rsn_pairwise=CCMP" | sudo tee -a /etc/hostapd/hostapd.conf > /dev/null
    echo "auth_algs=1" | sudo tee -a /etc/hostapd/hostapd.conf > /dev/null

    # Start hostapd in the background
    sudo hostapd /etc/hostapd/hostapd.conf &

    # Configure dnsmasq
    echo "interface=$INTERFACE_HOTSPOT" | sudo tee /etc/dnsmasq.conf > /dev/null
    echo "dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,$LEASE_TIME" | sudo tee -a /etc/dnsmasq.conf > /dev/null
    echo "server=8.8.8.8"   | sudo tee -a /etc/dnsmasq.conf > /dev/null # Google DNS
    echo "server=8.8.4.4"   | sudo tee -a /etc/dnsmasq.conf > /dev/null # Google DNS
    echo "server=1.1.1.1"   | sudo tee -a /etc/dnsmasq.conf > /dev/null # Cloudflare DNS
    echo "server=1.0.0.1"   | sudo tee -a /etc/dnsmasq.conf > /dev/null # Cloudflare DNS

    # Start dnsmasq
    sudo systemctl restart dnsmasq

    # Enable IP forwarding
    sudo sysctl -w net.ipv4.ip_forward=1

    # Setup NAT (Network Address Translation)
    sudo iptables -t nat -A POSTROUTING -o "$INTERFACE_UPSTREAM" -j MASQUERADE
    sudo iptables -A FORWARD -i "$INTERFACE_UPSTREAM" -o "$INTERFACE_HOTSPOT" -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A FORWARD -i "$INTERFACE_HOTSPOT" -o "$INTERFACE_UPSTREAM" -j ACCEPT

    echo "Wi-Fi hotspot '$HOTSPOT_SSID' started on $INTERFACE_HOTSPOT."
}

stop_hotspot() {
    echo "Stopping Wi-Fi hotspot..."

    # Disable IP forwarding
    sudo sysctl -w net.ipv4.ip_forward=0

    # Remove NAT rules
    sudo iptables -t nat -D POSTROUTING -o "$INTERFACE_UPSTREAM" -j MASQUERADE
    sudo iptables -D FORWARD -i "$INTERFACE_UPSTREAM" -o "$INTERFACE_HOTSPOT" -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -D FORWARD -i "$INTERFACE_HOTSPOT" -o "$INTERFACE_UPSTREAM" -j ACCEPT

    # Stop hostapd
    sudo killall hostapd

    # Stop dnsmasq
    sudo systemctl stop dnsmasq

    # Bring down the hotspot interface
    sudo ip link set "$INTERFACE_HOTSPOT" down

    echo "Wi-Fi hotspot stopped."
}

# --- Script Logic ---
case "$1" in
    start)
        start_hotspot
        ;;
    stop)
        stop_hotspot
        ;;
    restart)
        stop_hotspot
        start_hotspot
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac
