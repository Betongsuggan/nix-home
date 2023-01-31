{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.urxvt;
in
{
  options.br.urxvt = {
    enable = mkEnableOption "Enable urxvt terminal emulator";
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      TERMINFO_DIRS = "${pkgs.rxvt-unicode-unwrapped.terminfo.outPath}/share/terminfo";
    };
    programs.urxvt = {
      enable = true;
      iso14755 = false;
      scroll.bar.enable = false;
      extraConfig = {
        cursorBlink = true;
        iso14755_52 = false;
      };
      keybindings = {
        "Shift-Control-V" = "eval:paste_clipboard";
        "Shift-Control-C" = "eval:selection_to_clipboard";
      };
      fonts = [
        "xft:Hasklug Nerd Font Mono,Hasklig Medium:style=Medium,Regular:pixelsize=15"
        "xft:Hasklug Nerd Font Mono:style=Bold:pixelsize=15"
        "xft:Hasklug Nerd Font Mono:style=Italic:pixelsize=15"
        "xft:Hasklug Nerd Font Mono:style=Bold Italic:pixelsize=15"
      ];
    };
  };
}
