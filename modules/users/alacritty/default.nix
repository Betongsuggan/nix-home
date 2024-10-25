{ pkgs, config, lib, ... }:
with lib;
let 
  theme = import ../theming/theme.nix { };
in
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
        live_config_reload = true;
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
        shell = {
          program = "${pkgs.nushell}/bin/nu";
          args = [];
        };
        colors = {
          primary = {
            background = theme.colors.background-dark;
            foreground = theme.colors.text-light;
          };
        
          selection = {
            text       = theme.colors.text-dark;
            background = theme.colors.text-mid;
          };
          normal = {
            black   = theme.colors.background-dark;
            red     = theme.colors.red-light;
            green   = theme.colors.green-light;
            yellow  = theme.colors.yellow-light;
            blue    = theme.colors.blue-light;
            magenta = theme.colors.purple-light;
            cyan    = theme.colors.organge-light;
            white   = theme.colors.text-light;
          };
        };
      };
    };
  };
}
