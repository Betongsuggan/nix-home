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
        # setLdLibraryPath = true; 
        #        extraPackages32 = with pkgs.pkgsi686Linux; [ 
        #          libva 
        #        ];
        extraPackages = with pkgs; [
          vaapiVdpau
          libvdpau-va-gl
        ];
      };
      #steam-hardware.enable = true;
    };
    environment.systemPackages = [ pkgs.vulkan-validation-layers ];
  };
}
