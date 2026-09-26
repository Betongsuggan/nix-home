{
  pkgs,
  config,
  lib,
  ...
}:
with lib;

let
  cfg = config.my.game-streaming.server;

  # Script to prepare streaming session
  # Creates virtual monitor, disables physical monitors, and sets up Steam
  prepare-streaming-session = pkgs.writeShellScriptBin "prepare-streaming-session" ''
    #!/usr/bin/env bash
    LOG="/tmp/streaming-session.log"
    WORKSPACE="${toString cfg.workspace}"
    VIRTUAL_MON="${cfg.display}"

    # Use Sunshine's environment variables for resolution, with defaults
    WIDTH=''${SUNSHINE_CLIENT_WIDTH:-1920}
    HEIGHT=''${SUNSHINE_CLIENT_HEIGHT:-1080}
    FPS=''${SUNSHINE_CLIENT_FPS:-60}

    echo "$(date): prepare-streaming-session started" >> "$LOG"
    echo "  Virtual monitor: $VIRTUAL_MON" >> "$LOG"
    echo "  Resolution: ''${WIDTH}x''${HEIGHT}@''${FPS}" >> "$LOG"
    echo "  Target workspace: $WORKSPACE" >> "$LOG"

    # Keep the machine awake for the whole stream: logind's idle suspend
    # doesn't see gamepad input. Released by restore-monitors.
    ${pkgs.systemd}/bin/systemd-run --user --unit=streaming-inhibit --collect \
      ${pkgs.systemd}/bin/systemd-inhibit --what=idle:sleep --who=sunshine \
        --why="Streaming session" --mode=block ${pkgs.coreutils}/bin/sleep infinity \
      >> "$LOG" 2>&1 || true

    # Make sure the virtual monitor exists (it normally does since login)
    ${pkgs.hyprland}/bin/hyprctl output create headless "$VIRTUAL_MON"

    # Turn the physical monitors off for the stream; restore-monitors brings
    # them back from the config
    PHYSICAL_MONITORS=$(${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[].name' | grep -v "^$VIRTUAL_MON$")
    DISABLE_CMD=""
    for mon in $PHYSICAL_MONITORS; do
      DISABLE_CMD="$DISABLE_CMD keyword monitor $mon,disable ;"
      echo "  Disabling monitor: $mon" >> "$LOG"
    done
    ${pkgs.hyprland}/bin/hyprctl --batch "$DISABLE_CMD"

    # Configure virtual monitor resolution using client's requested settings
    ${pkgs.hyprland}/bin/hyprctl keyword monitor "$VIRTUAL_MON,''${WIDTH}x''${HEIGHT}@''${FPS},0x0,1"
    echo "  Set $VIRTUAL_MON to ''${WIDTH}x''${HEIGHT}@''${FPS}" >> "$LOG"

    # Find Steam Big Picture window
    STEAM_WINDOW=$(${pkgs.hyprland}/bin/hyprctl clients -j | ${pkgs.jq}/bin/jq -r '.[] | select(.class == "steam" and (.title | test("Steam Big Picture Mode|Steam"; "i"))) | .address' | head -1)

    if [[ -n "$STEAM_WINDOW" ]]; then
      echo "  Found Steam window: $STEAM_WINDOW" >> "$LOG"
      ${pkgs.hyprland}/bin/hyprctl dispatch movetoworkspacesilent "$WORKSPACE,address:$STEAM_WINDOW"
    else
      echo "  Steam not running, starting..." >> "$LOG"
      ${pkgs.hyprland}/bin/hyprctl dispatch exec "[workspace $WORKSPACE silent] steam -bigpicture"
      sleep 3
    fi

    # Focus the streaming workspace
    ${pkgs.hyprland}/bin/hyprctl dispatch workspace "$WORKSPACE"
    echo "  Focused workspace $WORKSPACE" >> "$LOG"
    echo "  Streaming session ready" >> "$LOG"
  '';

  # Script to restore monitors after streaming ends: reloading the Hyprland
  # config re-applies the declared monitor rules (modes, positions, HDR, VRR,
  # 10-bit) and drops the stream's runtime overrides. The headless monitor is
  # kept: sunshine probes encoders against the live monitor list, and without
  # any output (no physical monitor connected on a headless host) it rejects
  # the next /launch with 503. Its config rule puts it back out of reach.
  restore-monitors = pkgs.writeShellScriptBin "restore-monitors" ''
    #!/usr/bin/env bash
    LOG="/tmp/streaming-session.log"
    echo "$(date): restore-monitors: reloading the Hyprland config" >> "$LOG"
    ${pkgs.systemd}/bin/systemctl --user stop streaming-inhibit.service 2>/dev/null || true
    ${pkgs.hyprland}/bin/hyprctl reload
    ${pkgs.hyprland}/bin/hyprctl dispatch workspace 1
  '';

in
{
  options.my.game-streaming = {
    server = {
      enable = mkOption {
        description = "Enable game streaming server (Sunshine)";
        type = types.bool;
        default = false;
      };
      display = mkOption {
        description = ''
          Display connector to use for streaming.
          Can be a physical display (e.g., 'DP-1') or a virtual monitor name (e.g., 'SUNSHINE').
        '';
        type = types.str;
        default = "DP-1";
        example = "SUNSHINE";
      };
      workspace = mkOption {
        description = "Workspace number dedicated for streaming";
        type = types.int;
        default = 10;
        example = 10;
      };
      user = mkOption {
        description = ''
          User account that runs the streaming session. `services.sunshine`
          installs its unit as a global systemd *user* service, so every
          graphical user otherwise starts its own Sunshine — the loser of the
          race crash-loops on the RTSP port (48010) forever. When set, Sunshine
          and the virtual-monitor oneshot are gated with `ConditionUser` and
          only start in this user's session. `null` keeps the unrestricted
          behavior.
        '';
        type = types.nullOr types.str;
        default = null;
        example = "gamer";
      };
      allowedNetworks = mkOption {
        description = ''
          Source networks allowed to reach Sunshine's streaming ports and web
          UI. Everything else is refused by the firewall, which keeps the admin
          UI off the internet even though Sunshine itself is told to accept
          "wan" origins (so tailnet clients can pair).
        '';
        type = types.listOf types.str;
        default = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "100.64.0.0/10" # Tailscale CGNAT range
          "fe80::/10"
          "fc00::/7" # includes Tailscale's fd7a:115c:a1e0::/48
        ];
      };
      hdr = mkOption {
        description = ''
          Enable HDR streaming support.
          Requires HEVC Main10 or AV1 10-bit encoding capability.
          Note: Virtual monitors may have limited HDR support.
        '';
        type = types.bool;
        default = true;
      };
    };
  };

  config = mkIf config.my.game-streaming.server.enable {
    # Sunshine requires uinput for virtual input devices (keyboard, mouse, gamepad injection)
    boot.kernelModules = [ "uinput" ];
    hardware.uinput.enable = true;

    # Create uinput group and set proper permissions on /dev/uinput
    users.groups.uinput = { };
    services.udev.extraRules = ''
      KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    '';

    # The upstream openFirewall opens these ports to every source; accept them
    # only from cfg.allowedNetworks instead.
    networking.firewall.extraCommands =
      let
        base = config.services.sunshine.settings.port;
        ports = {
          tcp = map (o: base + o) [
            (-5)
            0
            1
            21
          ];
          udp = map (o: base + o) [
            9
            10
            11
            13
            21
          ];
        };
        rule =
          net: proto: port:
          "${
            if hasInfix ":" net then "ip6tables" else "iptables"
          } -w -A nixos-fw -p ${proto} -s ${net} --dport ${toString port} -j nixos-fw-accept";
      in
      concatStringsSep "\n" (
        concatMap (
          net: concatLists (mapAttrsToList (proto: map (rule net proto)) ports)
        ) cfg.allowedNetworks
      );

    # wlroots screencopy portal for Sunshine's capture
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-wlr ];

    services.sunshine = {
      enable = true;
      # Auto-start via graphical-session.target loses a race against the
      # `hypr-virtual-monitors` oneshot below — sunshine would come up
      # before the headless monitor exists and crash-loop. We re-add the
      # WantedBy on the drop-in instead, after ordering against the monitor
      # service.
      autoStart = false;
      # Opened below, restricted to cfg.allowedNetworks
      openFirewall = false;
      capSysAdmin = true; # Required for KMS capture, which is more reliable
      settings = {
        sunshine_name = "betongsuggan station";
        output_name = cfg.display;

        # Codec settings: Enable AV1 + HEVC auto-negotiation
        # RX 9070 XT (VCN5) has excellent AV1/HEVC encoding quality
        hevc_mode = 0; # Auto: Main + Main10 for HDR support
        av1_mode = 0; # Auto: Enable when client supports it (30% better than HEVC)

        # Quality settings optimized for gaming
        qp = 20; # Lower = better quality (default 28, gaming: 18-22)
        min_threads = 4; # Better multi-threading for encoding
        fec_percentage = 10; # Reduced from 20 - WiFi 6 has low packet loss

        # Encryption: Disable on LAN for lower latency
        lan_encryption_mode = 0; # No encryption on trusted LAN
        wan_encryption_mode = 1; # Encrypt WAN streams for security

        # Sunshine classifies a peer as LAN only when its source IP is in
        # RFC1918 / link-local. Tailscale's CGNAT range (100.64/10) is
        # neither, so tailnet clients are seen as WAN — without these the
        # default `pin=pc / web_ui=lan` blocks pairing and the admin UI
        # from any tailnet device.
        origin_pin_allowed = "wan";
        origin_web_ui_allowed = "wan";
        # Never ask the router to forward ports to us
        upnp = "disabled";
      };
      applications = {
        apps = [
          {
            name = "Steam Gaming";
            prep-cmd = [
              {
                do = "${prepare-streaming-session}/bin/prepare-streaming-session";
                undo = "${restore-monitors}/bin/restore-monitors";
              }
            ];
            auto-detach = "true";
          }
        ];
      };
    };

    # Materialize the headless monitor Sunshine captures from. Runs as a
    # systemd-user oneshot ordered before sunshine.service, so the Wayland
    # monitor list is non-empty by the time Sunshine connects to the
    # compositor — without this, Sunshine finds no displays at startup and
    # all encoders (nvenc/vaapi/software) "fail" because there's nothing to
    # capture. Polls hyprctl until the IPC socket is live (Hyprland's
    # exec-once creates the dir asynchronously).
    systemd.user.services.hypr-virtual-monitors = {
      description = "Materialize Hyprland headless monitor(s) for Sunshine";
      after = [ "hyprland-session.target" ];
      bindsTo = [ "hyprland-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      unitConfig = mkIf (cfg.user != null) { ConditionUser = cfg.user; };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -eu
        sig_dir="$XDG_RUNTIME_DIR/hypr"
        for _ in $(seq 1 60); do
          if [ -d "$sig_dir" ]; then
            sig="$(ls "$sig_dir" 2>/dev/null | head -1 || true)"
            if [ -n "''${sig:-}" ] && \
               HYPRLAND_INSTANCE_SIGNATURE="$sig" \
               ${pkgs.hyprland}/bin/hyprctl monitors >/dev/null 2>&1; then
              export HYPRLAND_INSTANCE_SIGNATURE="$sig"
              break
            fi
          fi
          sleep 0.5
        done
        if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
          echo "Hyprland IPC socket never appeared at $sig_dir" >&2
          exit 1
        fi
        # `hyprctl output create headless` is idempotent for our purposes:
        # if a monitor with the same name exists, it returns ok without
        # creating a duplicate.
        ${pkgs.hyprland}/bin/hyprctl output create headless ${cfg.display}
      '';
    };

    # Drop-in: order sunshine after the monitor service and re-add the
    # graphical-session WantedBy that `autoStart = false` removed.
    systemd.user.services.sunshine = {
      wants = [ "hypr-virtual-monitors.service" ];
      after = [ "hypr-virtual-monitors.service" ];
      wantedBy = [ "graphical-session.target" ];
      unitConfig = mkIf (cfg.user != null) { ConditionUser = cfg.user; };
    };

    environment.systemPackages = [
      prepare-streaming-session
      restore-monitors
      pkgs.jq
      pkgs.libva-utils # vainfo for verifying VAAPI encoder capabilities
    ];
  };
}
