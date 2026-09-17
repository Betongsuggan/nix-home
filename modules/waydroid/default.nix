{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.waydroid;

  # The Widevine CDM and the ARM translation layer are proprietary blobs that have to be
  # fetched at runtime and unpacked into the container's mutable overlay, so they can't be
  # expressed as Nix derivations. What *can* be pinned declaratively is the procedure --
  # which matters because `waydroid upgrade` replaces system.img/vendor.img and silently
  # discards both blobs, making this a command you re-run rather than a one-time setup.
  drmSetup = pkgs.writeShellApplication {
    name = "waydroid-drm-setup";
    runtimeInputs = with pkgs; [ git python3 lzip ];
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
      echo "Widevine + libndk installed. Start a session with: waydroid session start"
    '';
  };
in {
  options.waydroid = {
    enable = mkEnableOption "Enable Waydroid Android container";

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

    environment.systemPackages = with pkgs;
      [ wl-clipboard ] ++ optional cfg.drmSetup drmSetup;
  };
}
