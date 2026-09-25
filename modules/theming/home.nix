{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.theming;
  schemes = import ./schemes.nix;
in
{
  options.my.theming = {
    enable = mkEnableOption "Enable theme";

    wallpaper = mkOption {
      type = types.path;
      description = "Path to wallpaper image";
      default = ../../assets/wallpaper/zeal.jpg;
    };

    cornerRadius = mkOption {
      type = types.int;
      default = 5;
      description = "Corner radius in pixels for windows, bars and menus.";
    };

    cursor = {
      package = mkOption {
        type = types.package;
        description = "Cursor theme package";
        default = pkgs.banana-cursor;
      };
      name = mkOption {
        type = types.str;
        description = "Name of the cursor theme";
        default = "Banana";
      };
      size = mkOption {
        type = types.int;
        description = "Size of the cursor";
        default = 24;
      };
    };

    font = {
      package = mkOption {
        type = types.package;
        description = "Font package";
        default = pkgs.hasklig;
      };
      name = mkOption {
        type = types.str;
        description = "Name of the font to use";
        default = "Hasklig";
      };
      style = mkOption {
        type = types.str;
        description = "Style of the font to use";
        default = "Medium";
      };
      size = mkOption {
        type = types.number;
        description = "Size of the font";
        default = 11.0;
      };
    };

    scheme = mkOption {
      type = types.enum (attrNames schemes);
      default = "gruvbox";
      description = ''
        The color scheme (schemes.nix): stylix themes apps with its base16
        scheme, the editor uses its colorscheme plugin, and `colors` defaults
        to its terminal palette.
      '';
    };

    # The scheme's terminal palette, for modules stylix doesn't theme
    # (waybar, wofi, polybar, niri, Hyprland borders); override single colors
    # per host if needed
    # (every scheme has the same palette shape; the defaults read the chosen one)
    colors = mapAttrsRecursive (
      path: _:
      mkOption {
        type = types.str;
        default = getAttrFromPath path schemes.${cfg.scheme}.terminal;
        defaultText = literalMD "the ${concatStringsSep "." path} color of `scheme`";
        description = "The ${concatStringsSep " " path} color";
      }
    ) schemes.gruvbox.terminal;
  };

  config = mkIf cfg.enable {
    fonts.fontconfig = {
      enable = true;
      # Primary families come from stylix (targets.fontconfig, inserted at
      # list order 600); these merge in after them as fallbacks.
      defaultFonts.monospace = [
        "Symbols Nerd Font Mono"
        "Noto Color Emoji"
      ];
    };

    home.packages = with pkgs; [
      papirus-icon-theme
      nerd-fonts.symbols-only
    ];

    home.file.".background-image".source = cfg.wallpaper;

    stylix = {
      enable = true;
      # Explicit opt-in per target: app modules enable their own stylix
      # target, so a flake update can't silently start theming new apps.
      autoEnable = false;

      image = cfg.wallpaper;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${schemes.${cfg.scheme}.base16}.yaml";

      polarity = "dark";

      cursor = { inherit (cfg.cursor) name package size; };

      fonts = {
        monospace = { inherit (cfg.font) name package; };
        # sansSerif/serif/emoji keep stylix defaults (DejaVu + Noto Color
        # Emoji), matching the previous manual fontconfig defaults.
        sizes = {
          applications = cfg.font.size;
          desktop = cfg.font.size;
          # popups follows desktop; terminal is set by the terminal module
        };
      };

      targets = {
        gtk.enable = true; # GTK3 apps (thunar): adw-gtk3 + base16 gtk.css
        gnome.enable = true; # dconf color-scheme=prefer-dark (GTK4/libadwaita, firefox)
        fontconfig.enable = true;
        font-packages.enable = true;
      };
    };
  };
}
