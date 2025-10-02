{ pkgs, config, lib, ... }:
with lib;

{
  options.colemak = {
    enable = mkEnableOption "Enable Colemak keyboard layout";
  };

  config = mkIf config.colemak.enable { console.keyMap = "colemak"; };
}
