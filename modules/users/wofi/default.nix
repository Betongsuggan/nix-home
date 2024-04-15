{ config, lib, pkgs, ... }:
with lib;

let
  theme = import ../theming/theme.nix { };
in
{
  options.wofi = {
    enable = mkEnableOption "Enable Wofi application launcher";
  };

  config = mkIf config.wofi.enable {
    home-manager.users.${config.user} = {
      home.packages = with pkgs; [
        wofi-emoji
      ];
      programs.wofi = {
        enable = true;
        settings = {
          allow_images = true;
          image_size = 15;
        };
        style = ''
          window {
            font-size: 18px;
            border-radius: ${theme.cornerRadius};
            border-color: ${theme.colors.border-light};
            background-color: ${theme.colors.background-dark};
            color: ${theme.colors.text-light};
          }

          #entry {
            padding: 0.50em;
          }

          #entry:selected {
            background-color: ${theme.colors.red-dark};
          }

          #text:selected {
            color: ${theme.colors.text-light};
          }

          #input {
            background-color: ${theme.colors.background-light};
            color: ${theme.colors.text-light};
            padding: 0.50em;
          }

          image {
            margin-left: 0.25em;
            margin-right: 0.25em;
          }
        '';
        #input  {
        # color: ${theme.colors.background};
        #}
      };
    };
  };
}
