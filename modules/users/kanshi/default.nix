{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.br.kanshi;
in {
  options.br.kanshi = {
    enable = mkOption {
      description = "Enable Kanshi";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    services.kanshi = {
      enable = true;
      profiles = {
        work.outputs = [
          {
            criteria = "DP-3";
            mode = "3840x2560";
            scale = 1.25;
          }
          {
            criteria = "eDP-1";
            mode = "1920x1200";
          }
        ];
        home.outputs = [
          {
            criteria = "DP-2";
            mode = "3440x1440@100";
            scale = 1.0;
          }
          {
            criteria = "eDP-1";
            mode = "1920x1200";
          }
        ];
      };
    };
  };
}
