{ pkgs, config, lib, ... }:
{
  imports = [
    ./alacritty
    ./audio
    ./autorandr
    ./bash
    ./browsers
    ./colemak
    ./communication
    ./development
    ./fonts
    ./games
    ./general
    ./git
    ./i3
    ./neovim
    ./picom
    ./polybar
    ./rofi
    ./sway
    ./urxvt
    ./waybar
    ./x11
  ];
}
