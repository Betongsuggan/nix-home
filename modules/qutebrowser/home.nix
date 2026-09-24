{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.my.qutebrowser = {
    enable = mkEnableOption "Enable qutebrowser";
  };

  config = mkIf config.my.qutebrowser.enable {
    programs = {
      qutebrowser = {
        enable = true;
      };
    };
  };
}
