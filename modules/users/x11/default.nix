{ pkgs, config, lib, ... }:
with lib;

{
  options.x11 = {
    enable = mkEnableOption "Enable X11";
  };

  config = mkIf config.x11.enable {
    home-manager.users.${config.user}.xsession.enable = true;
    home-manager.users.${config.user}.xresources.extraConfig = ''
      ! -----------------------------------------------------------------------------
      ! File: gruvbox-dark.xresources
      ! Description: Retro groove colorscheme generalized
      ! Author: morhetz <morhetz@gmail.com>
      ! Source: https://github.com/morhetz/gruvbox-generalized
      ! Last Modified: 6 Sep 2014
      ! -----------------------------------------------------------------------------

      ! hard contrast: *background: #1d2021
      *background: #282828
      ! soft contrast: *background: #32302f
      *foreground: #ebdbb2
      ! Black + DarkGrey
      *color0:  #282828
      *color8:  #928374
      ! DarkRed + Red
      *color1:  #cc241d
      *color9:  #fb4934
      ! DarkGreen + Green
      *color2:  #98971a
      *color10: #b8bb26
      ! DarkYellow + Yellow
      *color3:  #d79921
      *color11: #fabd2f
      ! DarkBlue + Blue
      *color4:  #458588
      *color12: #83a598
      ! DarkMagenta + Magenta
      *color5:  #b16286
      *color13: #d3869b
      ! DarkCyan + Cyan
      *color6:  #689d6a
      *color14: #8ec07c
      ! LightGrey + White
      *color7:  #a89984
      *color15: #ebdbb2

      *.color24:  #076678
      *.color66:  #427b58
      *.color88:  #9d0006
      *.color96:  #8f3f71
      *.color100: #79740e
      *.color108: #8ec07c
      *.color109: #83a598
      *.color130: #af3a03
      *.color136: #b57614
      *.color142: #b8bb26
      *.color167: #fb4934
      *.color175: #d3869b
      *.color208: #fe8019
      *.color214: #fabd2f
      *.color223: #ebdbb2
      *.color228: #f2e5bc
      *.color229: #fbf1c7
      *.color230: #f9f5d7
      *.color234: #1d2021
      *.color235: #282828
      *.color236: #32302f
      *.color237: #3c3836
      *.color239: #504945
      *.color241: #665c54
      *.color243: #7c6f64
      *.color244: #928374
      *.color245: #928374
      *.color246: #a89984
      *.color248: #bdae93
      *.color250: #d5c4a1

      Xft*antialias:        true
    '';
  };
}
