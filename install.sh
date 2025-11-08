#install
sudo pacman -Sy
sudo pacman -S nix swaync labwc pipwire pipewire-pulse wireplumber playerctl brightnessctl wlr-randr hostapd dnsmasq waybar wofi

sudo cp -r ./nix-modules /opt/
sudo cp -r ./system /opt/
sudo cp -r ./labwc /ect/xdg/
