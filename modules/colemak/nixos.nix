{
  pkgs,
  config,
  lib,
  ...
}:
with lib;

{
  options.my.colemak = {
    enable = mkEnableOption "Enable Colemak keyboard layout";
  };

  config = mkIf config.my.colemak.enable { console.keyMap = "colemak"; };
}
