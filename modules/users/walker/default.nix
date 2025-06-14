{ config, lib, pkgs, ... }:
with lib;

{
  options.walker = {
    enable = mkEnableOption "Enable Walker application launcher";
    runAsService = mkOption {
      type = types.bool;
      default = true;
      description = "Run Walker as a service for faster startup";
    };
    config = mkOption {
      type = types.attrs;
      default = {};
      description = "Configuration options for Walker";
    };
    style = mkOption {
      type = types.str;
      default = '''';
      description = "Custom CSS styling for Walker";
    };
  };

  config = mkIf config.walker.enable {
    home = {
      packages = with pkgs; [
        unstable.walker
      ];

      # Create configuration directory
      file.".config/walker/config.json".text = builtins.toJSON (recursiveUpdate {
        # Default configuration
        ui = {
          width = 600;
          height = 400;
          border = {
            width = 1;
            radius = 8;
          };
          fullscreen = false;
          monitor = 0;
        };
        search = {
          placeholder = "Search...";
          typeahead = true;
        };
        list = {
          height = 400;
          width = 600;
          icons = true;
          labels = true;
        };
        # Default modules configuration
        applications = {
          cache = true;
          history = true;
        };
        websearch = {
          prefix = "?";
          engine = "google";
        };
        switcher = {
          prefix = "/";
        };
        clipboard = {
          prefix = "!";
          maxEntries = 50;
        };
      } config.walker.config);

      # Create style file
      file.".config/walker/style.css".text = ''
        /* Base styling */
        * {
          color: #dcd7ba;
          font-family: "JetBrainsMono Nerd Font", monospace;
          font-size: 14px;
        }

        #window {
          background-color: rgba(30, 30, 46, 0.95);
          border: 1px solid #7aa2f7;
          border-radius: 8px;
        }

        #search {
          background-color: rgba(40, 40, 56, 0.8);
          border: none;
          border-radius: 4px;
          margin: 10px;
          padding: 8px 12px;
        }

        #list {
          background-color: transparent;
          margin: 0 10px 10px 10px;
        }

        #item {
          border-radius: 4px;
          padding: 6px 8px;
        }

        #item:selected {
          background-color: rgba(122, 162, 247, 0.3);
        }

        #item:hover {
          background-color: rgba(122, 162, 247, 0.2);
        }

        #item-text {
          margin-left: 8px;
        }

        #item-subtext {
          color: #a9b1d6;
          font-size: 12px;
          margin-left: 8px;
        }

        /* Module-specific styling */
        #window.applications #search {
          border-bottom: 2px solid #7aa2f7;
        }

        #window.websearch #search {
          border-bottom: 2px solid #bb9af7;
        }

        #window.clipboard #search {
          border-bottom: 2px solid #9ece6a;
        }

        /* Custom styling */
        ${config.walker.style}
      '';
    };

    # Create autostart entry if running as service
    xdg.configFile = mkIf config.walker.runAsService {
      "autostart/walker.desktop".text = ''
        [Desktop Entry]
        Name=Walker
        Comment=Application Launcher
        Exec=walker --gapplication-service
        Icon=walker
        Terminal=false
        Type=Application
        Categories=Utility;
        StartupNotify=false
        X-GNOME-Autostart-enabled=true
      '';
    };
  };
}
