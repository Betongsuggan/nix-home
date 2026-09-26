{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.my.home-check;
  home = config.home.homeDirectory;
  dirs = config.xdg.userDirs;

  # Where a stray file belongs, by extension (anything else: Documents)
  destinations = {
    ${dirs.pictures} = [
      "png"
      "jpg"
      "jpeg"
      "gif"
      "webp"
      "svg"
      "heic"
      "bmp"
    ];
    ${dirs.videos} = [
      "mp4"
      "mkv"
      "webm"
      "mov"
      "avi"
    ];
    ${dirs.music} = [
      "mp3"
      "flac"
      "ogg"
      "opus"
      "wav"
      "m4a"
    ];
    ${dirs.download} = [
      "zip"
      "tar"
      "gz"
      "xz"
      "zst"
      "7z"
      "rar"
      "iso"
      "img"
      "deb"
      "rpm"
      "AppImage"
    ];
  };
  extensionCases = concatStrings (
    mapAttrsToList (dir: exts: ''
      ${concatStringsSep "|" exts}) echo ${escapeShellArg dir} ;;
    '') destinations
  );

  # The captures' own folders (window-manager's screenshot and recording)
  screenshots = "${dirs.pictures}/Screenshots";
  recordings = "${dirs.videos}/Recordings";

  check = pkgs.writeShellApplication {
    name = "home-check";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gawk
    ];
    text = ''
      # Reports how ~ drifts from its layout; never moves or deletes anything
      summary=false
      if [ "''${1:-}" = "--summary" ]; then summary=true; fi

      declare -A allowed=()
      for name in ${escapeShellArgs cfg.allowed}; do allowed[$name]=1; done

      destination() {
        case "''${1##*.}" in
          ${extensionCases}
          *) echo ${escapeShellArg dirs.documents} ;;
        esac
      }
      home=${escapeShellArg home}
      pretty() {
        case "$1" in
          "$home"*) echo "~''${1#"$home"}" ;;
          *) echo "$1" ;;
        esac
      }

      count=0
      report() { count=$((count + 1)); $summary || echo "  $1"; }
      section() { $summary || printf '\n%s\n' "$1"; }

      section "Not part of the home layout (move it, or add it to my.home-check.allowed):"
      while IFS= read -r -d "" path; do
        name=''${path##*/}
        [ -n "''${allowed[$name]:-}" ] && continue
        if [ -L "$path" ]; then
          report "$(pretty "$path")  (symlink to $(readlink "$path"))"
        elif [ -d "$path" ]; then
          report "$(pretty "$path")/  -> a folder under $(pretty ${escapeShellArg dirs.documents}), or allow it"
        else
          report "$(pretty "$path")  -> $(pretty "$(destination "$name")")"
        fi
      done < <(find ${escapeShellArg home} -mindepth 1 -maxdepth 1 -not -name '.*' -print0 | sort -z)

      section "Captures outside their folders:"
      while IFS= read -r -d "" path; do
        case "$path" in
          *.mkv|*.mp4|*.webm) target=${escapeShellArg recordings} ;;
          *) target=${escapeShellArg screenshots} ;;
        esac
        report "$(pretty "$path")  -> $(pretty "$target")"
      done < <(find ${
        escapeShellArgs [
          home
          dirs.pictures
          dirs.videos
          dirs.download
          dirs.desktop
        ]
      } -mindepth 1 -maxdepth 1 -type f \
        \( -name '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T*' -o -iname 'screenshot*' \) -print0 2>/dev/null | sort -z)

      section "Downloads older than ${toString cfg.downloadsAge} days:"
      old=$(find ${escapeShellArg dirs.download} -mindepth 1 -maxdepth 1 -mtime +${toString cfg.downloadsAge} 2>/dev/null | wc -l)
      if [ "$old" -gt 0 ]; then
        size=$(find ${escapeShellArg dirs.download} -mindepth 1 -maxdepth 1 -mtime +${toString cfg.downloadsAge} -print0 \
          | du -csh --files0-from=- 2>/dev/null | tail -n 1 | cut -f1)
        report "$old items, $size, in $(pretty ${escapeShellArg dirs.download})"
      fi

      # A build folder's own mtime stays put while its contents change: stale
      # means nothing two levels down changed either
      stale() {
        while IFS= read -r -d "" dir; do
          if [ -z "$(find "$dir" -maxdepth 2 -mtime -${toString cfg.buildOutput.staleAfter} -print -quit 2>/dev/null)" ]; then
            printf '%s\0' "$dir"
          fi
        done
      }

      section "Build output of ${toString cfg.buildOutput.minSize} MB or more, untouched for ${toString cfg.buildOutput.staleAfter} days (regenerable):"
      while IFS=$'\t' read -r mb path; do
        report "$mb MB  $(pretty "$path")"
      done < <(find ${escapeShellArgs cfg.buildOutput.roots} -type d \( ${
        concatMapStringsSep " -o " (n: "-name ${escapeShellArg n}") cfg.buildOutput.names
      } \) -prune -print0 2>/dev/null \
        | stale \
        | du -sm --files0-from=- 2>/dev/null \
        | awk -F'\t' '$1 >= ${toString cfg.buildOutput.minSize}' | sort -rn)

      if $summary; then
        echo "$count"
      elif [ "$count" -eq 0 ]; then
        echo "Home is tidy"
      fi
    '';
  };

  weekly = pkgs.writeShellScript "home-check-notify" ''
    n=$(${getExe check} --summary)
    if [ "$n" -gt 0 ]; then
      ${config.my.notifications.send {
        appName = "Home check";
        icon = "folder";
        summary = "Home check: $n items out of place";
        body = "Run home-check for the list";
      }}
    fi
  '';
in
{
  options.my.home-check = {
    enable = mkOption {
      type = types.bool;
      default = config.my.profiles.desktop.enable;
      defaultText = literalExpression "config.my.profiles.desktop.enable";
      description = ''
        `home-check`: reports what drifts from the home layout (stray entries
        in ~, captures outside their folders, old downloads, stale build
        output), with a destination for each; a weekly notification when it
        finds anything. It never moves or deletes anything.
      '';
    };

    allowed = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "Games"
        "roms"
      ];
      description = ''
        Top-level entries of ~ that belong there, besides the XDG folders and
        the defaults (Development, nix-home, nix-vault).
      '';
    };

    downloadsAge = mkOption {
      type = types.ints.positive;
      default = 30;
      description = "Report downloads older than this many days.";
    };

    buildOutput = {
      roots = mkOption {
        type = types.listOf types.str;
        default = [ "${home}/Development" ];
        description = "Where to look for build output.";
      };
      names = mkOption {
        type = types.listOf types.str;
        default = [
          "target"
          "node_modules"
          ".direnv"
          ".gradle"
          "__pycache__"
          "dist"
          ".next"
          "cdk.out"
        ];
        description = "Directory names that are regenerable build output.";
      };
      minSize = mkOption {
        type = types.ints.positive;
        default = 50;
        description = "Report build output of at least this many MB.";
      };
      staleAfter = mkOption {
        type = types.ints.positive;
        default = 30;
        description = "Report build output not modified for this many days.";
      };
    };
  };

  config = mkIf cfg.enable {
    my.home-check.allowed =
      map baseNameOf (
        filter (d: d != null) (
          with dirs;
          [
            desktop
            documents
            download
            music
            pictures
            publicShare
            templates
            videos
          ]
        )
      )
      ++ [
        "Development"
        "nix-home"
        "nix-vault"
      ];

    home.packages = [ check ];

    systemd.user.services.home-check = {
      Unit.Description = "Report drift from the home layout";
      Service = {
        Type = "oneshot";
        ExecStart = "${weekly}";
      };
    };
    systemd.user.timers.home-check = {
      Unit.Description = "Weekly home layout check";
      Timer = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
