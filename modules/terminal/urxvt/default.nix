{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.terminal;

  # Use terminal font family or fall back to theme font
  fontFamily = if cfg.font.family != null
    then cfg.font.family
    else config.theme.font.name;

  # Build font strings for urxvt (xft format)
  fontSize = cfg.font.size;
  fonts = [
    "xft:${fontFamily}:style=Medium,Regular:pixelsize=${toString fontSize}"
    "xft:${fontFamily}:style=Bold:pixelsize=${toString fontSize}"
    "xft:${fontFamily}:style=Italic:pixelsize=${toString fontSize}"
    "xft:${fontFamily}:style=Bold Italic:pixelsize=${toString fontSize}"
  ];

in
{
  config = mkIf config.terminal.urxvt.enable {
    home.sessionVariables = {
      TERMINFO_DIRS = "${pkgs.rxvt-unicode-unwrapped.terminfo.outPath}/share/terminfo";
    };

    programs.urxvt = {
      enable = true;
      iso14755 = false;
      scroll.bar.enable = false;

      extraConfig = recursiveUpdate {
        cursorBlink = true;
        iso14755_52 = false;
      } cfg.urxvt.extraConfig;

      keybindings = cfg.urxvt.keybindings;

      fonts = fonts;
    };
  };
}