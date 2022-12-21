{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.br.alacritty;
in {
  options.br.alacritty = {
    enable = mkOption {
      description = "Enable Alacritty terminal emulator";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (cfg.enable) {
    programs.alacritty = {
      enable = true;

      settings = {
        live_config_reload = true;
        font   = import ./fonts.nix;
        colors = import ./colors.nix;
      };
    };
  };
}
