# Windows launchers outside Steam (Battle.net, ...): each app is a command
# that owns one Wine prefix. Its first run downloads the vendor installer and
# runs it in the prefix; every run after that starts the installed exe. Both
# run Proton-GE's `proton` script directly inside nixpkgs' steam-run FHS, so
# the prefix gets Proton's DXVK/VKD3D and protonfixes like a Steam game would.
# Not umu-run: Proton-GE 11 makes umu download Valve's steamrt4 container at
# run time (and its digest check failed on bits); steam-run comes from Nix.
# The installer is fetched at run time, not by Nix: vendors serve it from an
# unversioned URL, and the launcher updates itself inside the prefix anyway.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.my.games;

  # Apps the module knows; `my.games.wineApps.<preset>.enable = true` is enough
  presets = {
    battlenet = {
      displayName = "Battle.net";
      installer = {
        url = "https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe";
        args = [
          "--lang=enUS"
          "--installpath=C:\\Program Files (x86)\\Battle.net"
        ];
      };
      exe = "Program Files (x86)/Battle.net/Battle.net Launcher.exe";
      # Its embedded Chromium repaints only partly under XWayland (white
      # patches after the first click) and goes black with GPU compositing,
      # so it runs on Wine's Wayland driver with hardware acceleration off.
      # Seeded before the installer too, since the installer starts it.
      # Closing exits instead of hiding: there is no tray to bring it back
      # from (`tray`). That one is per account (<account hash>.config, written
      # at first login), so a new host gets it from the second launch on
      wayland = true;
      preLaunch = ''
        dir="$WINEPREFIX/drive_c/users/steamuser/AppData/Roaming/Battle.net"
        mkdir -p "$dir"
        [ -s "$dir/Battle.net.config" ] || echo '{}' > "$dir/Battle.net.config"
        set_config() {
          jq "$1" "$2" > "$2.tmp"
          mv "$2.tmp" "$2"
        }
        set_config '.Client.HardwareAcceleration = "false"' "$dir/Battle.net.config"
        for account in "$dir"/*.config; do
          [ "$account" = "$dir/Battle.net.config" ] || set_config '.User.Client.HideOnClose = "false"' "$account"
        done
      '';
    };
  };

  # Proton's 32-bit side needs libfreetype.so.6, which steam-run only ships 64-bit
  steamRun = (pkgs.steam.override { extraLibraries = p: [ p.freetype ]; }).run;

  # Presets fill option defaults rather than `config`: a submodule's config
  # keys can't depend on `name` (it's a module argument, so that recurses)
  appModule =
    { name, ... }:
    let
      preset = presets.${name} or { };
      fromPreset =
        path: opt:
        mkOption (
          opt // optionalAttrs (hasAttrByPath path preset) { default = attrByPath path null preset; }
        );
    in
    {
      options = {
        enable = mkEnableOption "the ${name} Wine app";
        displayName = mkOption {
          type = types.str;
          default = preset.displayName or name;
          description = "Name of the desktop entry";
        };
        installer = {
          url = fromPreset [ "installer" "url" ] {
            type = types.str;
            description = "Download URL of the Windows installer, fetched on first launch";
          };
          args = mkOption {
            type = types.listOf types.str;
            default = preset.installer.args or [ ];
            description = "Arguments passed to the installer";
          };
        };
        exe = fromPreset [ "exe" ] {
          type = types.str;
          description = "Installed executable, relative to drive_c";
        };
        wayland = fromPreset [ "wayland" ] {
          type = types.bool;
          default = false;
          description = "Run on Wine's Wayland driver (PROTON_ENABLE_WAYLAND) instead of XWayland";
        };
        tray = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Let Wine show tray icons. No host runs a bar with a tray, so Wine
            would draw its own fallback tray box (a small window per app)
          '';
        };
        preLaunch = fromPreset [ "preLaunch" ] {
          type = types.lines;
          default = "";
          description = "Shell run before every launch (and before the installer), with WINEPREFIX set; jq is on PATH";
        };
        prefix = mkOption {
          type = types.str;
          default = "${config.home.homeDirectory}/Games/${name}";
          defaultText = literalExpression ''"''${config.home.homeDirectory}/Games/<name>"'';
          description = "Proton compat-data directory (STEAM_COMPAT_DATA_PATH); the Wine prefix is its pfx/";
        };
        umuId = mkOption {
          type = types.str;
          default = "umu-default";
          description = "UMU_ID, selects the protonfixes applied to the prefix";
        };
        env = mkOption {
          type = types.attrsOf types.str;
          default = { };
          example = {
            DRI_PRIME = "1";
          };
          description = "Extra environment for the app (e.g. the render GPU on hybrid graphics)";
        };
        proton = mkOption {
          type = types.package;
          default = (head cfg.protonGE.packages).steamcompattool;
          defaultText = literalExpression "(head config.my.games.protonGE.packages).steamcompattool";
          description = "Proton build (a steamcompattool output) the app runs with";
        };
      };
    };

  # Registry the prefix should have; applied with regedit whenever it changes
  registry =
    name: app:
    pkgs.writeText "${name}.reg" ''
      REGEDIT4

      [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer]
      "NoTrayItemsDisplay"=dword:0000000${if app.tray then "0" else "1"}
    '';

  launcher =
    name: app:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        pkgs.curl
        pkgs.jq
      ];
      text = ''
        export STEAM_COMPAT_DATA_PATH=${escapeShellArg app.prefix}
        # Proton insists on a Steam install path; nothing is used from it here
        export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.local/share/Steam"
        export SteamAppId=0 SteamGameId=${escapeShellArg name}
        export UMU_ID=${escapeShellArg app.umuId}
        export WINEPREFIX="$STEAM_COMPAT_DATA_PATH/pfx"
        ${optionalString app.wayland "export PROTON_ENABLE_WAYLAND=1"}
        ${concatStrings (mapAttrsToList (k: v: "export ${k}=${escapeShellArg v}\n") app.env)}
        exe="$WINEPREFIX/drive_c/"${escapeShellArg app.exe}
        # waitforexitandrun, as Steam does: protonfixes only run under that verb
        proton() { ${steamRun}/bin/steam-run ${app.proton}/proton "$@"; }

        # Before preLaunch: this is also what creates the prefix on a new host
        reg=${registry name app}
        stamp="$STEAM_COMPAT_DATA_PATH/.registry-applied"
        if [ "$(cat "$stamp" 2>/dev/null)" != "$reg" ]; then
          mkdir -p "$STEAM_COMPAT_DATA_PATH"
          proton runinprefix regedit /S "Z:''${reg//\//\\}"
          echo "$reg" > "$stamp"
        fi

        ${app.preLaunch}
        if [ -e "$exe" ]; then
          proton waitforexitandrun "$exe" "$@"
          exit
        fi

        # First launch: the installer. Vendor installers start the launcher
        # when done, and Proton returns only once it closes
        cache="''${XDG_CACHE_HOME:-$HOME/.cache}/wine-apps"
        mkdir -p "$cache" "$STEAM_COMPAT_DATA_PATH"
        installer="$cache/${name}-setup.exe"
        curl -fL --retry 3 -o "$installer.part" ${escapeShellArg app.installer.url}
        mv "$installer.part" "$installer"
        proton waitforexitandrun "$installer" ${escapeShellArgs app.installer.args}
        [ -e "$exe" ] || { echo "${name}: installer finished but $exe is missing" >&2; exit 1; }
      '';
    };

  enabled = filterAttrs (_: app: app.enable) cfg.wineApps;
in
{
  options.my.games.wineApps = mkOption {
    type = types.attrsOf (types.submodule appModule);
    default = { };
    example = literalExpression ''
      {
        battlenet.enable = true; # preset
        myapp = {
          enable = true;
          installer.url = "https://example.com/Setup.exe";
          exe = "Program Files/MyApp/MyApp.exe";
        };
      }
    '';
    description = ''
      Windows launchers installed into their own Wine prefix on first launch
      and run with Proton-GE inside steam-run. Known presets: ${concatStringsSep ", " (attrNames presets)}.
    '';
  };

  config = mkIf (cfg.enable && enabled != { }) {
    home.packages = mapAttrsToList launcher enabled;
    # Wine's Wayland driver names windows after the exe. Hyprland stops frame
    # callbacks to hidden windows, so a game on another workspace blocks in
    # its vsync'd present until it's shown again; WoW gets disconnected after
    # a few minutes of that. Keep them rendering (misc:render_unfocused_fps)
    my.window-manager.hyprland.windowRules = [ "render_unfocused on, match:class ^(.*\\.exe)$" ];
    xdg.desktopEntries = mapAttrs (name: app: {
      name = app.displayName;
      exec = name;
      icon = "applications-games";
      categories = [ "Game" ];
    }) enabled;
  };
}
