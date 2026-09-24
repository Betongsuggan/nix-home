{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  defaultLayout = builtins.readFile ./layouts/default.kdl;
in
{
  options.my.zellij = {
    enable = mkOption {
      description = "Enable Zellij";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.my.zellij.enable {
    home.file.".config/zellij/layouts/default.kdl".text = defaultLayout;
    programs.zellij = {
      enable = true;
      settings = {
        simplified_ui = true;
        pane_frames = false;
        ui = {
          pane_frames = {
            rounded_corners = true;
          };
        };
        layout = "default";
        theme = "gruvbox";
        themes = {
          gruvbox = {
            fg = config.my.theming.colors.text-light;
            bg = config.my.theming.colors.background-dark;
            black = config.my.theming.colors.background-dark;
            red = config.my.theming.colors.background-dark;
            green = config.my.theming.colors.green-dark;
            yellow = config.my.theming.colors.yellow-dark;
            blue = config.my.theming.colors.blue-dark;
            magenta = config.my.theming.colors.purple-dark;
            cyan = config.my.theming.colors.blue-light;
            white = config.my.theming.colors.text-light;
            orange = config.my.theming.colors.orange-dark;
          };
        };
      };
    };
  };
}
