{ config, lib, pkgs, ... }:
with lib;

{
  options.graphics = {
    enable = mkEnableOption "Enable graphics hardware";

    brand = mkOption {
      description = "Graphics card manufacturer";
      type = types.str;
      default = "intel";
    };
  };

  config = mkIf config.graphics.enable {
    hardware = {
      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
        extraPackages = with pkgs; [
          intel-media-driver
          mesa
          vaapiVdpau
          libvdpau-va-gl
        ];
      };
    };
  };
}
