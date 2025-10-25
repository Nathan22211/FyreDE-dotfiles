#waybar
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
        buildInputs = [
                pkgs.waybar
                pkgs.wofi
                pkgs.cliphist
                pkgs.wl-clipboard
        ];
        shellHook = ''
            if [ -z "$DATA_DIR" ]; then
                export DATA_DIR="$(pwd)/data"
                export PWD=$HOME
            fi
        '';
}
