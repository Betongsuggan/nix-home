{ pkgs, config, lib, ... }:
with lib;

{
  options.starship = {
    enable = mkOption {
      description = "Enable starship";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.starship.enable {
    home-manager.users.${config.user}.programs.starship = {
      enable = true;
      enableNushellIntegration = true;
      enableBashIntegration = true;
    };
  };
}
