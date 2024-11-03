{ config, lib, pkgs, ... }:
with lib;

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
            border-radius: ${config.theme.cornerRadius};
            border-color: ${config.theme.colors.border-light};
            background-color: ${config.theme.colors.background-dark};
            color: ${config.theme.colors.text-light};
          }

          #entry {
            padding: 0.50em;
          }

          #entry:selected {
            background-color: ${config.theme.colors.red-dark};
          }

          #text:selected {
            color: ${config.theme.colors.text-light};
          }

          #input {
            background-color: ${config.theme.colors.background-light};
            color: ${config.theme.colors.text-light};
            padding: 0.50em;
          }

          image {
            margin-left: 0.25em;
            margin-right: 0.25em;
          }
        '';
        #input  {
        # color: ${config.theme.colors.background};
        #}
      };
    };
  };
}
