{ pkgs, config, lib, ... }:
{
  imports = [
    ./general
    ./autorandr
    ./audio
    ./i3
    ./git
    ./colemak
    ./communication
    ./development
    ./neovim
    ./bash
    ./alacritty
    ./urxvt
    ./picom
    ./polybar
    ./rofi
    ./x11
    ./fonts
    ./games
    ./browsers
  ];
}
