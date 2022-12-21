{ pkgs, config, lib, ...}:
with lib;

let
  cfg = config.br.colemak;
in {
  options.br.colemak = {
    enable = mkEnableOption "Enable Colemak keyboard layout";
  };

  config = mkIf (cfg.enable) {
    home.keyboard = {
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
