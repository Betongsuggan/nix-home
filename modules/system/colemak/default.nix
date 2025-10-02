{ pkgs, config, lib, ... }:
with lib;

{
  options.colemak = {
    enable = mkEnableOption "Enable Colemak keyboard layout";
  };

  config = mkIf config.colemak.enable {
    keyboard = {
      layout = "us,us";
      variant = "colemak,";
      #layout = "us";
      options = [
        "caps:escape"
        "compose:ralt"
        "grp:shifts_toggle"
      ];
    };
  };
}
