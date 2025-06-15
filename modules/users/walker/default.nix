{ config, lib, pkgs, inputs, ... }:
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
      default = { };
      description = "Configuration options for Walker";
    };
    style = mkOption {
      type = types.str;
      default = '''';
      description = "Custom CSS styling for Walker";
    };
  };

  config = mkIf config.walker.enable {
    # Install Walker package
    home-manager.users.${config.user} = {
      imports = [ pkgs.walker-module ];
      programs.walker = {
        enable = true;
        runAsService = true;

        # All options from the config.json can be used here.
        config = {
          search.placeholder = "Example";
          ui.fullscreen = true;
          list = {
            height = 200;
          };
          websearch.prefix = "?";
          switcher.prefix = "/";
        };

        # If this is not set the default styling is used.
        #style = ''
        #  * {
        #    color: #dcd7ba;
        #  }
        #'';
      };

      #home = {
      #  packages = with pkgs; [
      #    walker
      #  ];

      #  # Create configuration directory
      #  file.".config/walker/config.json".text = builtins.toJSON (recursiveUpdate
      #    {
      #      # Default configuration
      #      ui = {
      #        width = 600;
      #        height = 400;
      #        border = {
      #          width = 1;
      #          radius = 8;
      #        };
      #        fullscreen = false;
      #        monitor = 0;
      #      };
      #      search = {
      #        placeholder = "Search...";
      #        typeahead = true;
      #      };
      #      list = {
      #        height = 400;
      #        width = 600;
      #        icons = true;
      #        labels = true;
      #      };
      #      # Default modules configuration
      #      applications = {
      #        cache = true;
      #        history = true;
      #      };
      #      websearch = {
      #        prefix = "?";
      #        engine = "google";
      #      };
      #      switcher = {
      #        prefix = "/";
      #      };
      #      clipboard = {
      #        prefix = "!";
      #        maxEntries = 50;
      #      };
      #      theme = "local";
      #    }
      #    config.walker.config);

      #  # Create style file to match Wofi styling
      #  file.".config/walker/themes/local.css".text = ''
      #    /* Base styling to match Wofi */
      #    * {
      #      font-family: ${config.theme.font.name};
      #      font-size: 18px;
      #      color: ${config.theme.colors.text-light};
      #    }

      #    #window {
      #      background-color: ${config.theme.colors.background-dark};
      #      border: 1px solid ${config.theme.colors.border-light};
      #      border-radius: ${config.theme.cornerRadius};
      #    }

      #    #search {
      #      background-color: ${config.theme.colors.background-light};
      #      color: ${config.theme.colors.text-light};
      #      border: none;
      #      margin: 10px;
      #      padding: 0.50em;
      #    }

      #    #list {
      #      background-color: transparent;
      #      margin: 0 10px 10px 10px;
      #    }

      #    #item {
      #      padding: 0.50em;
      #    }

      #    #item:selected {
      #      background-color: ${config.theme.colors.red-dark};
      #    }

      #    #item:hover {
      #      background-color: ${config.theme.colors.red-dark};
      #    }

      #    #item-text {
      #      margin-left: 0.25em;
      #      color: ${config.theme.colors.text-light};
      #    }

      #    #item-text:selected {
      #      color: ${config.theme.colors.text-light};
      #    }

      #    #item-subtext {
      #      color: ${config.theme.colors.text-mid};
      #      font-size: 14px;
      #      margin-left: 0.25em;
      #    }

      #    image, #item-icon {
      #      margin-left: 0.25em;
      #      margin-right: 0.25em;
      #    }

      #    /* Custom styling */
      #    ${config.walker.style}
      #  '';
      #};
      ## Create systemd user service for Walker
      #systemd.user.services.walker = mkIf config.walker.runAsService {
      #  Unit = {
      #    Description = "Walker Application Launcher";
      #    PartOf = [ "graphical-session.target" ];
      #    After = [ "graphical-session-pre.target" ];
      #  };

      #  Service = {
      #    ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
      #    Restart = "on-failure";
      #    RestartSec = 5;
      #  };

      #  Install = {
      #    WantedBy = [ "graphical-session.target" ];
      #  };
      #};

    };
  };
}
