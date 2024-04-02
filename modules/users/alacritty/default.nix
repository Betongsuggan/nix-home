{ pkgs, config, lib, ... }:
with lib;

{
  options.alacritty = {
    enable = mkOption {
      description = "Enable Alacritty terminal emulator";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.alacritty.enable {
    home-manager.users.${config.user}.programs.alacritty = {
      enable = true;

      settings = {
        live_config_reload = true;
        font = import ./fonts.nix;
        colors = import ./colors.nix;
      };
    };
  };
}
