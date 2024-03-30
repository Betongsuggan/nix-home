{ config, lib, pkgs, ... }:
with lib;

{
  options.wofi = {
    enable = mkEnableOption "Enable Wofi application launcher";
  };

  config = mkIf (config.wofi.enable) {
    home-manager.users.${config.user}.programs.wofi = {
      enable = true;
      settings = {
        allow_images = true;
        image_size = 15;
      };
      style = ''
        * {
          border-radius: ${theme.cornerRadius};
          border: none;
        }

        window {
          font-size: 18px;
          background-color: ${theme.colors.background};
          color: ${theme.colors.mainText};
        }

        #entry {
          padding: 0.50em;
        }

        #entry:selected {
          background-color: ${theme.colors.thirdText};
        }

        #text:selected {
          color: ${theme.colors.background};
        }

        #input {
          background-color: ${theme.colors.utilityText};
          color: ${theme.colors.background};
          padding: 0.50em;
        }

        image {
          margin-left: 0.25em;
          margin-right: 0.25em;
        }
      '';
    };
  };
}
