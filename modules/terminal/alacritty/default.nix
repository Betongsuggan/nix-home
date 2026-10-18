{ config, lib, ... }:
with lib;

let
  cfg = config.my.terminal;
in
{
  config = mkIf cfg.alacritty.enable {
    # Colors, font, and opacity are applied by stylix from config.my.theming.*
    stylix.targets.alacritty.enable = cfg.colors.useTheme;
    stylix.fonts.sizes.terminal = cfg.font.size;
    stylix.opacity.terminal = cfg.opacity;

    programs.alacritty = {
      enable = true;
      settings = mkMerge [
        {
          # Highlighting text is the copy: it lands in the clipboard (Ctrl+V
          # anywhere), not only in the primary selection (middle click).
          # See "Clipboard" in SPEC.md.
          selection.save_to_clipboard = mkDefault true;
        }
        # Explicit family override still supported; wins over stylix
        (mkIf (cfg.font.family != null) {
          font.normal.family = mkForce cfg.font.family;
        })
        cfg.alacritty.extraSettings
      ];
    };
  };
}
