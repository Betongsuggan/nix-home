{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib;

let
  cfg = config.my.taildrop;
  dmenu = prompt: config.my.launcher.dmenu { inherit prompt; };
  # A no-op for users without notifications (enabling them from here would
  # recurse: the notification backends read the launcher)
  notify =
    summary: body:
    if !config.my.notifications.enable then
      ":"
    else
      config.my.notifications.send {
        appName = "Taildrop";
        icon = "document-send";
        inherit summary body;
      };

  # Pick a Taildrop target (hosts and phones on the tailnet), then send the
  # clipboard, or the files given as arguments
  send = pkgs.writeShellApplication {
    name = "taildrop-send";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnugrep
      tailscale
      wl-clipboard
    ];
    text = ''
      # `tailscale file cp --targets`: ip<TAB>name[<TAB>state]
      target=$(tailscale file cp --targets \
        | awk -F'\t' '{ print $2 ($3 == "" ? "" : " · " $3) }' \
        | ${dmenu "Send to"}) || exit 0
      target=''${target%% · *}
      [ -n "$target" ] || exit 0

      if [ "$#" -gt 0 ]; then
        what="$# file(s)"
        tailscale file cp "$@" "$target:" || {
          ${notify "Could not send to $target" "$what"}
          exit 1
        }
      else
        # Clipboard: an image as PNG, anything else as text
        name="clipboard-$(date +%Y%m%d-%H%M%S)"
        types=$(wl-paste --list-types 2>/dev/null) || {
          ${notify "Nothing to send" "The clipboard is empty"}
          exit 0
        }
        if grep -qx 'image/png' <<<"$types"; then
          what="clipboard image"
          wl-paste --type image/png | tailscale file cp --name "$name.png" - "$target:"
        else
          what="clipboard text"
          wl-paste --no-newline | tailscale file cp --name "$name.txt" - "$target:"
        fi || {
          ${notify "Could not send to $target" "$what"}
          exit 1
        }
      fi
      ${notify "Sent to $target" "$what"}
    '';
  };

  # Collect incoming files: clipboard-* ones go to the clipboard, the rest to
  # cfg.dir. Files land in a staging folder first, so each one is seen once
  receive = pkgs.writeShellApplication {
    name = "taildrop-receive";
    runtimeInputs = with pkgs; [
      coreutils
      tailscale
      wl-clipboard
    ];
    text = ''
      dir=${escapeShellArg cfg.dir}
      inbox="$dir/.incoming"
      mkdir -p "$inbox"
      while tailscale file get --wait --conflict=rename "$inbox"; do
        for f in "$inbox"/*; do
          [ -e "$f" ] || continue
          name=$(basename "$f")
          case "$name" in
            clipboard-*.png)
              wl-copy --type image/png < "$f"
              rm -f "$f"
              ${notify "Clipboard received" "An image"}
              ;;
            clipboard-*)
              wl-copy --type 'text/plain;charset=utf-8' < "$f"
              preview=$(head -c 80 "$f")
              rm -f "$f"
              ${notify "Clipboard received" "$preview"}
              ;;
            *)
              # A taken name gets a number: photo.jpg -> photo (1).jpg
              base=$name ext=""
              if [[ "$name" == ?*.* ]]; then base=''${name%.*} ext=.''${name##*.}; fi
              dest="$dir/$name" n=1
              while [ -e "$dest" ]; do dest="$dir/$base ($n)$ext"; n=$((n + 1)); done
              mv "$f" "$dest"
              ${notify "Received $name" "In $dir"}
              ;;
          esac
        done
      done
    '';
  };
in
{
  options.my.taildrop = {
    enable = mkOption {
      type = types.bool;
      default =
        config.my.profiles.desktop.enable
        && osConfig.services.tailscale.enable
        && elem config.home.username osConfig.my.common.admins;
      defaultText = literalMD "an admin (`my.common.admins`) with the desktop profile on a tailnet host";
      description = ''
        Send the clipboard or files to tailnet devices (Linux and Android) with
        Taildrop, and receive them. Makes this user the host's tailscale
        operator, so only one user per host can have it.
      '';
    };
    dir = mkOption {
      type = types.str;
      default = "${config.xdg.userDirs.download}/taildrop";
      defaultText = literalExpression ''"''${config.xdg.userDirs.download}/taildrop"'';
      description = "Where received files are put.";
    };
    package = mkOption {
      type = types.package;
      readOnly = true;
      default = send;
      description = "The `taildrop-send` command (for keybinds).";
    };
  };

  config = mkIf cfg.enable {
    # Mod+Shift+S sends the clipboard (modules/window-manager keymap)
    home.packages = [ send ];

    systemd.user.services.taildrop-receive = {
      Unit = {
        Description = "Receive Taildrop files and clipboards";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = getExe receive;
        Restart = "always";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
