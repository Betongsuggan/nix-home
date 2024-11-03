{ pkgs, config, lib, ... }:
with lib;

{
  options.zellij = {
    enable = mkOption {
      description = "Enable Zellij";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.zellij.enable {
    home-manager.users.${config.user}.programs.zellij = {
      enable = true;
      enableBashIntegration = true;
      settings = {
        simplified_ui = true;
        pane_frames = false;
        theme = "gruvbox";
        #themes = {
        #  fg 
        #  bg 40 42 54
        #  black 0 0 0
        #  red 255 85 85
        #  green 80 250 123
        #  yellow 241 250 140
        #  blue 98 114 164
        #  magenta 255 121 198
        #  cyan 139 233 253
        #  white 255 255 255
        #  orange 255 184 108
        #};
      };
    };
  };
}
