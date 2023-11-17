{ pkgs, config, lib, ... }:
with lib;

{
  options.flatpak = {
    enable = mkOption {
      description = "Enable Flatpak";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.flatpak.enable {
    services.flatpak.enable = true;
  };
}
