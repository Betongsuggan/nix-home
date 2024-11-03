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
        #terminal.shell = {
        #  program = "${pkgs.bash}/bin/bash";
        #  args = [];
        #};
        colors = {
          primary = {
            background = config.theme.colors.background-dark;
            foreground = config.theme.colors.text-light;
          };
        
          selection = {
            text       = config.theme.colors.text-dark;
            background = config.theme.colors.text-mid;
          };
          normal = {
            black   = config.theme.colors.background-dark;
            red     = config.theme.colors.red-light;
            green   = config.theme.colors.green-light;
            yellow  = config.theme.colors.yellow-light;
            blue    = config.theme.colors.blue-light;
            magenta = config.theme.colors.purple-light;
            cyan    = config.theme.colors.organge-light;
            white   = config.theme.colors.text-light;
          };
        };
      };
    };
  };
}
