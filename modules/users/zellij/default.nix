{ pkgs, config, lib, ... }:
with lib;
let defaultLayout = builtins.readFile ./layouts/default.kdl;
in {
  options.zellij = {
    enable = mkOption {
      description = "Enable Zellij";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.zellij.enable {
    home.file.".config/zellij/layouts/default.kdl".text = defaultLayout;
    programs.zellij = {
      enable = true;
      settings = {
        simplified_ui = true;
        pane_frames = false;
        ui = { pane_frames = { rounded_corners = true; }; };
        layout = "default";
        theme = "gruvbox";
        themes = {
          gruvbox = {
            fg = config.theme.colors.text-light;
            bg = config.theme.colors.background-dark;
            black = config.theme.colors.background-dark;
            red = config.theme.colors.background-dark;
            green = config.theme.colors.green-dark;
            yellow = config.theme.colors.yellow-dark;
            blue = config.theme.colors.blue-dark;
            magenta = config.theme.colors.purple-dark;
            cyan = config.theme.colors.blue-light;
            white = config.theme.colors.text-light;
            orange = config.theme.colors.orange-dark;
          };
        };
      };
    };
  };
}
