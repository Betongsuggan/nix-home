{ pkgs, config, lib, ... }:
with lib;

{
  options.waydroid = {
    enable = mkOption {
      description = "Enable Waydroid Android container";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.waydroid.enable {
    virtualisation.waydroid.enable = true;
    virtualisation.lxc.enable = true;

    environment.systemPackages = with pkgs; [ waydroid ];
  };
}
