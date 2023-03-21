{ pkgs, config, lib, ... }:
with lib;

let
  cfg = config.br.kanshi;
in {
  options.br.git = {
    enable = mkOption {
      description = "Enable Kanshi";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    services.kanshi = {
      enable = true;
      profiles.work.WAYLAND1 = [
        {
          mode = "2560x1440";
        }
      ];
    };
  };
}
