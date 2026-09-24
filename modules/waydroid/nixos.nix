{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.my.waydroid;

  # The Widevine CDM and the ARM translation layer are proprietary blobs that have to be
  # fetched at runtime and unpacked into the container's mutable overlay, so they can't be
  # expressed as Nix derivations. What *can* be pinned declaratively is the procedure --
  # which matters because `waydroid upgrade` replaces system.img/vendor.img and silently
  # discards both blobs, making this a command you re-run rather than a one-time setup.
  drmSetup = pkgs.writeShellApplication {
    name = "waydroid-drm-setup";
    runtimeInputs = with pkgs; [
      git
      python3
      lzip
    ];
    text = ''
      repo=/var/lib/waydroid-script

      if [ "$(id -u)" -ne 0 ]; then
        echo "waydroid-drm-setup patches /var/lib/waydroid and must run as root." >&2
        exit 1
      fi

      if [ -d "$repo/.git" ]; then
        git -C "$repo" pull --ff-only
      else
        git clone --depth 1 https://github.com/casualsnek/waydroid_script "$repo"
      fi
      cd "$repo"

      [ -x venv/bin/python3 ] || python3 -m venv venv
      venv/bin/pip install --quiet --upgrade pip
      venv/bin/pip install --quiet -r requirements.txt

      # The installers rewrite the images, so nothing may be holding them open.
      waydroid session stop 2>/dev/null || true
      systemctl stop waydroid-container

      venv/bin/python3 main.py install widevine
      venv/bin/python3 main.py install libndk

      systemctl start waydroid-container
      echo "Widevine + libndk installed. Start a session with: waydroid-up"
    '';
  };

  # `waydroid session start` talks to an already-running container service and
  # fails outright if it isn't up, so leaving the container off at boot would
  # otherwise turn every launch into a two-step dance. This is the on-demand
  # entry point: bring the container up, then the session.
  waydroidUp = pkgs.writeShellApplication {
    name = "waydroid-up";
    runtimeInputs = with pkgs; [
      systemd
      gnugrep
      coreutils
      config.virtualisation.waydroid.package
    ];
    text = ''
      # `waydroid status` exits non-zero when nothing is up, and this script runs
      # under `set -euo pipefail`, so every probe is wrapped rather than used bare.
      session_running() {
        waydroid status 2>/dev/null | grep -q "Session:.*RUNNING"
      }

      if ! systemctl is-active --quiet waydroid-container; then
        systemctl start waydroid-container
      fi

      if ! session_running; then
        waydroid session start &

        # show-full-ui against a half-started session silently does nothing, so
        # wait for the session to report RUNNING rather than racing it.
        for _ in $(seq 30); do
          if session_running; then
            break
          fi
          sleep 1
        done

        if ! session_running; then
          echo "waydroid session did not come up within 30s" >&2
          exit 1
        fi
      fi

      waydroid show-full-ui
    '';
  };
in
{
  options.my.waydroid = {
    enable = mkEnableOption "Enable Waydroid Android container";

    startOnBoot = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Start the Android container at boot. The container is a full Android
        userspace that is only useful while a session is open, so the default
        leaves it stopped and `waydroid-up` starts it on demand.
      '';
    };

    drmSetup = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Install the waydroid-drm-setup helper, which adds the Widevine CDM and the libndk
        ARM translation layer to the container so DRM-protected apps (Netflix) can play.
        Re-run it after every `waydroid upgrade`.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Kernel 6.16.9 dropped the ip_tables module, which the stock package shells out to;
    # the nftables build is the only one that can bring up waydroid0 on 6.18.
    virtualisation.waydroid = {
      enable = true;
      package = pkgs.waydroid-nftables;
    };

    # The upstream module pins the container to multi-user.target; drop that so
    # it stays stopped until `waydroid-up` (or the DRM setup helper) asks for it.
    systemd.services.waydroid-container.wantedBy = mkIf (!cfg.startOnBoot) (mkForce [ ]);

    environment.systemPackages =
      with pkgs;
      [
        wl-clipboard
        waydroidUp
      ]
      ++ optional cfg.drmSetup drmSetup;
  };
}
