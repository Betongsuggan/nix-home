{ config, lib, pkgs, ... }:
with lib;

{
  options.docker = {
    enable = mkEnableOption "Enable Docker";
  };

  config = mkIf config.docker.enable {
    virtualisation.docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };
}
