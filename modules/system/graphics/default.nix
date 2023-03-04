{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.graphics;
in {
  options.br.graphics = {
    enable = mkEnableOption "Enable graphics hardware";

    brand = mkOption {
      description = "Graphics card manufacturer";
      type = types.str;
      default = "intel";
    };
  };

  config = mkIf cfg.enable {
    hardware = {
      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
        #setLdLibraryPath = true; 
        #extraPackages32 = [ #with pkgs.pkgsi686Linux; [ 
        #  libva 
        #  pkgs.driversi686Linux.amdvlk
        #];
        extraPackages = with pkgs; [
          rocm-opencl-icd
        ];
      };
      #steam-hardware.enable = true;
    };
    services.xserver.videoDrivers = [ "amdgpu" ];
  };
}
