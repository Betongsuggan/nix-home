{ pkgs, config, lib, ... }:
with lib;
{
  options.alacritty = {
    enable = mkOption {
      description = "Enable Alacritty terminal emulator";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.alacritty.enable {
    home-manager.users.${config.user}.programs.alacritty = {
      enable = true;

      settings = {
        font = {
          size = 12;
          normal = {
            family = "monospace";
            style = "Medium,Regular";
          };
          bold = {
            family = "monospace";
            style = "Bold";
          };
          italic = {
            family = "monospace";
            style = "Italic";
          };
          bold_italic = {
            family = "monospace";
            style = "Bold Italic";
          };
        };
        colors = {
          primary = {
            inherit (config.theme.colors.primary) background foreground;
          };

          selection = {
            text = config.theme.colors.bright.black;
            background = config.theme.colors.normal.white;
          };
          normal = {
            inherit (config.theme.colors.normal) black red green yellow blue magenta cyan white;
          };
          bright = {
            inherit (config.theme.colors.bright) black red green yellow blue magenta cyan white;
          };
        };
      };
    };
  };
}
