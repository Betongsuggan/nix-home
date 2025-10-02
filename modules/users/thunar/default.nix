{ pkgs, config, lib, ... }:
with lib; {
  options.thunar = {
    enable = mkOption {
      description = "Enable Thunar file explorer";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.thunar.enable {

    home.packages = with pkgs; [
      xfce.thunar
      xfce.thunar-archive-plugin
      xfce.thunar-volman
    ];
  };
}
