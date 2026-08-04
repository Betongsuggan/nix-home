{ config, lib, ... }:
with lib;

let
  cfg = config.terminal;
in
{
  config = mkIf cfg.alacritty.enable {
    # Colors, font, and opacity are applied by stylix from config.theme.*
    stylix.targets.alacritty.enable = cfg.colors.useTheme;
    stylix.fonts.sizes.terminal = cfg.font.size;
    stylix.opacity.terminal = cfg.opacity;

    programs.alacritty = {
      enable = true;
      settings = mkMerge [
        # Explicit family override still supported; wins over stylix
        (mkIf (cfg.font.family != null) {
          font.normal.family = mkForce cfg.font.family;
        })
        cfg.alacritty.extraSettings
      ];
    };
  };
}
