{ config, lib, pkgs, ... }:

with lib;

let cfg = config.theme;
in {
  options.theme = {
    enable = mkEnableOption "Enable theme";

    wallpaper = mkOption {
      type = types.path;
      description = "Path to wallpaper image";
      default = ../../assets/wallpaper/nix-background.png;
    };

    cursor = {
      package = mkOption {
        type = types.attrs;
        description = "Font package";
        default = pkgs.bibata-cursors;
      };
      name = mkOption {
        type = types.str;
        description = "Name of the cursor theme";
        default = "Bibata-Modern-Classic";
      };
      size = mkOption {
        type = types.int;
        description = "Size of the cursor";
        default = 24;
      };
    };

    font = {
      package = mkOption {
        type = types.attrs;
        description = "Font package";
        default = pkgs.nerd-fonts.hasklug;
      };
      name = mkOption {
        type = types.str;
        description = "Name of the font to use";
        default = "Hasklug Nerd Font Mono";
      };
      style = mkOption {
        type = types.str;
        description = "Style of the font to use";
        default = "Hasklig Medium";
      };
      size = mkOption {
        type = types.number;
        description = "Size of the font";
        default = 11.0;
      };
    };

    colors = {
      primary = {
        background = mkOption {
          type = types.str;
          description = "Primary background color";
          default = "#282828";
        };

        foreground = mkOption {
          type = types.str;
          description = "Primary foreground color";
          default = "#ebdbb2";
        };
      };

      normal = {
        black = mkOption {
          type = types.str;
          description = "Normal black color";
          default = "#282828";
        };

        red = mkOption {
          type = types.str;
          description = "Normal red color";
          default = "#cc241d";
        };

        green = mkOption {
          type = types.str;
          description = "Normal green color";
          default = "#98971a";
        };

        yellow = mkOption {
          type = types.str;
          description = "Normal yellow color";
          default = "#d79921";
        };

        blue = mkOption {
          type = types.str;
          description = "Normal blue color";
          default = "#458588";
        };

        magenta = mkOption {
          type = types.str;
          description = "Normal magenta color";
          default = "#b16286";
        };

        cyan = mkOption {
          type = types.str;
          description = "Normal cyan color";
          default = "#458588";
        };

        white = mkOption {
          type = types.str;
          description = "Normal white color";
          default = "#cccccc";
        };
      };

      bright = {
        black = mkOption {
          type = types.str;
          description = "Bright black color";
          default = "#3c3836";
        };

        red = mkOption {
          type = types.str;
          description = "Bright red color";
          default = "#fb4934";
        };

        green = mkOption {
          type = types.str;
          description = "Bright green color";
          default = "#b8bb26";
        };

        yellow = mkOption {
          type = types.str;
          description = "Bright yellow color";
          default = "#fabd2f";
        };

        blue = mkOption {
          type = types.str;
          description = "Bright blue color";
          default = "#83a598";
        };

        magenta = mkOption {
          type = types.str;
          description = "Bright magenta color";
          default = "#d3869b";
        };

        cyan = mkOption {
          type = types.str;
          description = "Bright cyan color";
          default = "#83a598";
        };

        white = mkOption {
          type = types.str;
          description = "Bright white color";
          default = "#ffffff";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ config.theme.font.name "Noto Color Emoji" ];
        sansSerif = [ "DejaVu Sans" "Noto Color Emoji" ];
        serif = [ "DejaVu Serif" "Noto Color Emoji" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };

    home.packages = with pkgs; [
      papirus-icon-theme
      config.theme.cursor.package
      config.theme.font.package
      noto-fonts-emoji
      glibcLocales
    ];

    home.file.".background-image".source = cfg.wallpaper;

    stylix = {
      image = cfg.wallpaper;
      base16Scheme = {
        base00 = cfg.colors.primary.background;
        base01 = cfg.colors.normal.black;
        base02 = cfg.colors.bright.black;
        base03 = cfg.colors.normal.white;
        base04 = cfg.colors.bright.white;
        base05 = cfg.colors.primary.foreground;
        base06 = cfg.colors.bright.white;
        base07 = cfg.colors.bright.white;
        base08 = cfg.colors.normal.red;
        base09 = cfg.colors.normal.yellow;
        base0A = cfg.colors.normal.yellow;
        base0B = cfg.colors.normal.green;
        base0C = cfg.colors.normal.cyan;
        base0D = cfg.colors.normal.blue;
        base0E = cfg.colors.normal.magenta;
        base0F = cfg.colors.normal.red;
      };

      polarity = "dark";

      targets = {
        alacritty.enable = config.alacritty.enable;
        btop.enable = true;
        firefox.enable = config.firefox.enable;
        font-packages.enable = true;
        fontconfig.enable = true;
        hyprland.enable = config.hyprland.enable;
        hyprpaper.enable = config.hyprland.enable;
        hyprlock.enable = config.hyprland.enable;
        gtk.enable = true;
        qt.enable = true;
        mangohud.enable = true;
        neovim.enable = true;
        starship.enable = true;
      };
    };
  };
}
