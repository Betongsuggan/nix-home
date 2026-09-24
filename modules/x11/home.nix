{
  pkgs,
  config,
  lib,
  ...
}:
with lib;

{
  options.my.x11 = {
    enable = mkEnableOption "Enable X11";
  };

  config = mkIf config.my.x11.enable {
    xsession.enable = true;
    # Terminal colors from the theme via stylix
    stylix.targets.xresources.enable = true;
  };
}
