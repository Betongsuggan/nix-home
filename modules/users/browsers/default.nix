{ config, lib, pkgs, ... }:
with lib;

{
  options.browsers = {
    enable = mkEnableOption "Enable browser packages";

    defaultBrowser = mkOption {
      description = "Default browser for the system";
      type = types.str;
      default = "firefox";
    };
  };

  config = mkIf config.browsers.enable {
    home-manager.users.${config.user}.packages = with pkgs; [
      firefox
    ];
    home-manager.users.${config.user}.sessionVariables = {
      BROWSER = cfg.defaultBrowser;
    };
  };
}
