{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.browsers;
in {
  options.br.browsers = {
    enable = mkEnableOption "Enable browser packages";

    defaultBrowser = mkOption {
      description = "Default browser for the system";
      type = types.str;
      default = "firefox";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      firefox
    ];
    home.sessionVariables = {
      BROWSER = cfg.defaultBrowser;
    };
  };
}
