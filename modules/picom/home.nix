{
  config,
  pkgs,
  lib,
  ...
}:
with lib;

{
  options.my.picom = {
    enable = mkEnableOption "Enable Picom service";
  };

  config = mkIf config.my.picom.enable {
    services.picom = {
      enable = true;
      backend = "glx";
      fade = true;
      fadeSteps = [
        0.1
        0.12
      ];
      vSync = true;
    };
  };
}
