#!/usr/bin/env bash

# Script to fix remaining user modules with home-manager.users.${config.user} pattern

files=(
    "/home/betongsuggan/nix-home/modules/users/colemak/default.nix"
    "/home/betongsuggan/nix-home/modules/users/flatpak/default.nix"
    "/home/betongsuggan/nix-home/modules/users/neovim/default.nix"
    "/home/betongsuggan/nix-home/modules/users/starship/default.nix"
    "/home/betongsuggan/nix-home/modules/users/general/default.nix"
    "/home/betongsuggan/nix-home/modules/users/rofi/default.nix"
    "/home/betongsuggan/nix-home/modules/users/polybar/default.nix"
    "/home/betongsuggan/nix-home/modules/users/bash/default.nix"
    "/home/betongsuggan/nix-home/modules/users/alacritty/default.nix"
    "/home/betongsuggan/nix-home/modules/users/fish/default.nix"
    "/home/betongsuggan/nix-home/modules/users/i3/default.nix"
    "/home/betongsuggan/nix-home/modules/users/qutebrowser/default.nix"
    "/home/betongsuggan/nix-home/modules/users/communication/default.nix"
    "/home/betongsuggan/nix-home/modules/users/autorandr/default.nix"
    "/home/betongsuggan/nix-home/modules/users/kanshi/default.nix"
    "/home/betongsuggan/nix-home/modules/users/nushell/default.nix"
)

for file in "${files[@]}"; do
    echo "Fixing $file..."
    
    # Replace the home-manager.users.${config.user} pattern with just the direct configuration
    sed -i 's/home-manager\.users\.\${config\.user}\.//' "$file"
    
    echo "Fixed $file"
done

echo "All remaining modules fixed!"