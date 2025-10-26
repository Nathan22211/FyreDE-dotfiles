#install
sudo pacman -Sy
sudo pacman -S nix swaync labwc pipwire pipewire-pulse wireplumber playerctl brightnessctl wlr-randr hostapd dnsmasq

sudo cp -r ./nix-modules /opt/
sudo cp -r ./system /opt/
sudo cp -r ./labwc /ect/xdg/

sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs
sudo nix-channel --update -vvvvv

sudo gpasswd -a $USER nixbld
