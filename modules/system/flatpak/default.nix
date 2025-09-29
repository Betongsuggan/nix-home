{ config, lib, ... }:
with lib;

{
  options.flatpakSystem = {
    enable = mkEnableOption "Enable Flatpak system service";
  };

  config = mkIf config.flatpakSystem.enable {
    services.flatpak.enable = true;
  };
}