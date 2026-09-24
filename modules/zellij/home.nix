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
    stylix.targets.zellij.enable = true;
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
      };
    };
  };
}
