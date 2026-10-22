{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.my.network-manager;

  # Where the dispatcher leaves the portal's URL for the user session, and
  # the marker that says tailnet DNS was switched off for it (both vanish on
  # reboot, so a reboot never leaves the laptop half-configured)
  stateDir = "/run/captive-portal";

  # The laptop's resolver on the tailnet is controller's (headscale overrides
  # local DNS), which a captive portal blocks until the login is done. So the
  # probe asks the network's own DHCP nameserver and connects by address;
  # nothing here goes through the system resolver.
  captiveLogin = pkgs.writeShellApplication {
    name = "captive-login";
    runtimeInputs = with pkgs; [
      curl
      dnsutils
      jq
      networkmanager
      iproute2
      gawk
      systemd
      config.services.tailscale.package
    ];
    text = ''
      # captive-login [open|probe|wait|restore] [nameserver]
      #   open     detect a portal; if there is one, drop tailnet DNS, hand the
      #            page to the user session and wait for the login (default)
      #   probe    print online | portal <url> | offline
      #   restore  tailnet DNS back on, forget the portal
      state=${stateDir}
      host=connectivitycheck.gstatic.com
      verb=''${1:-open}
      # Only probing is harmless as a user; the rest changes tailscale and /run
      [ "$verb" = probe ] || [ "$(id -u)" = 0 ] || exec sudo "$0" "$@"

      # The nameserver the current default-route interface got from DHCP
      network_dns() {
        local dev
        dev=$(ip -4 route show default | awk '{ print $5; exit }')
        [ -n "$dev" ] && nmcli -g IP4.DNS device show "$dev" | head -1 | cut -d'|' -f1
      }
      ns=''${2:-$(network_dns)}

      # "<http code> <redirect url>" of a plain-HTTP 204 endpoint, resolved by
      # the network's nameserver; nothing when the network does not answer
      probe_http() {
        local ip
        [ -n "$ns" ] || return 1
        ip=$(dig +short +time=2 +tries=1 @"$ns" "$host" A | grep -E '^[0-9.]+$' | head -1) || true
        [ -n "$ip" ] || return 1
        curl -s -o /dev/null -m 6 --resolve "$host:80:$ip" -w '%{http_code} %{redirect_url}' "http://$host/generate_204"
      }

      # online | portal <url> | offline
      probe() {
        local answer code url
        answer=$(probe_http) || { echo offline; return; }
        code=''${answer%% *}; url=''${answer#* }
        case $code in
          204) echo online ;;
          # A portal either redirects to its page or serves it in place
          2??|3??) echo "portal ''${url:-http://$host/generate_204}" ;;
          *) echo offline ;;
        esac
      }

      tailnet_dns() {
        systemctl -q is-active tailscaled || return 0
        tailscale set --accept-dns="$1"
      }

      restore() {
        if [ -e "$state/dns-off" ]; then
          tailnet_dns true
          rm -f "$state/dns-off"
        fi
        rm -f "$state/url"
        systemctl -q is-active captive-portal-wait && [ "$verb" != wait ] && systemctl stop captive-portal-wait
        return 0
      }

      case $verb in
        probe) probe ;;
        restore) restore ;;
        wait)
          # Until the login is done or the portal is gone (device down removed the url)
          for _ in $(seq 240); do
            sleep 5
            [ -e "$state/url" ] || exit 0
            [ "$(probe)" = online ] && { restore; exit 0; }
          done
          restore ;;
        open)
          mkdir -p "$state"
          case $(probe) in
            online)
              # Self-heal: a reboot mid-login would leave tailnet DNS off for good
              restore
              if systemctl -q is-active tailscaled && [ "$(tailscale debug prefs | jq -r .CorpDNS)" = false ]; then
                tailnet_dns true
              fi ;;
            portal*)
              url=$(probe); url=''${url#portal }
              if [ ! -e "$state/dns-off" ]; then
                tailnet_dns false
                : > "$state/dns-off"
              fi
              # mv, so the user's path unit sees one complete file
              printf '%s\n' "$url" > "$state/url.tmp"
              chmod 644 "$state/url.tmp"
              mv "$state/url.tmp" "$state/url"
              systemctl -q is-active captive-portal-wait \
                || systemd-run -q --unit captive-portal-wait --collect "$0" wait "$ns"
              echo "portal: $url" ;;
            *) echo offline ;;
          esac ;;
        *) echo "usage: captive-login [open|probe|wait|restore] [nameserver]" >&2; exit 2 ;;
      esac
    '';
  };
in
{
  options.my.network-manager = {
    enable = mkEnableOption "Enable network management";

    captivePortal.enable = mkEnableOption ''
      opening a captive portal's login page when a network needs one, and
      switching tailnet DNS off until the login is done
    '';
  };

  config = mkMerge [
    (mkIf cfg.enable {
      users.users = genAttrs config.my.common.admins (_: {
        extraGroups = [ "networkmanager" ];
      });

      environment.systemPackages = [ pkgs.networkmanager ];
      networking = {
        # iwd with settings to create the interface
        wireless.iwd = {
          enable = true;
          settings = {
            DriverQuirks = {
              DefaultInterface = true; # Creates wlan0 automatically
            };
            Settings = {
              AutoConnect = true;
            };
          };
        };

        # NetworkManager using iwd as wifi backend
        networkmanager = {
          enable = true;
          wifi.backend = "iwd";
        };
      };
    })

    (mkIf (cfg.enable && cfg.captivePortal.enable) {
      environment.systemPackages = [ captiveLogin ];
      systemd.tmpfiles.rules = [ "d ${stateDir} 0755 root root -" ];

      # Every interface that comes up with a DHCP nameserver gets probed;
      # going down forgets the portal and restores tailnet DNS
      networking.networkmanager.dispatcherScripts = [
        {
          type = "basic";
          source = pkgs.writeShellScript "captive-portal" ''
            case $1 in tailscale*|lo) exit 0 ;; esac
            case $2 in
              up) [ -n "''${IP4_NAMESERVERS-}" ] && exec ${getExe captiveLogin} open "''${IP4_NAMESERVERS%% *}" ;;
              down) exec ${getExe captiveLogin} restore ;;
            esac
            exit 0
          '';
        }
      ];

      # The user's half: the dispatcher runs as root with no display, so it
      # leaves the URL in ${stateDir} and the session opens it
      systemd.user.paths.captive-portal = {
        description = "Watch for a captive portal's login page to open";
        wantedBy = [ "default.target" ];
        pathConfig.PathChanged = stateDir;
      };
      systemd.user.services.captive-portal = {
        description = "Open the captive portal's login page";
        serviceConfig.Type = "oneshot";
        script = ''
          [ -f ${stateDir}/url ] || exit 0
          url=$(cat ${stateDir}/url)
          # A user unit gets NixOS's minimal unit PATH, not the session's: the
          # browser and its .desktop file live in the user's profile
          export PATH="/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"
          export XDG_DATA_DIRS="/etc/profiles/per-user/$USER/share:$HOME/.nix-profile/share:/run/current-system/sw/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
          ${pkgs.libnotify}/bin/notify-send -a Network "Wi-Fi login required" "Opening $url"
          exec ${pkgs.xdg-utils}/bin/xdg-open "$url"
        '';
      };
    })
  ];
}
