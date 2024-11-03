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
    };
  };
}
