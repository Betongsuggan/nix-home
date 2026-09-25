{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.my.chromium = {
    enable = mkEnableOption "Enable Ungoogled Chromium browser";

    widevine = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Bundle Google's Widevine CDM for DRM streaming (Netflix, Spotify, ...).
        The Widevine build is a full second copy of Chromium (~800 MB in the
        closure); turn it off where another browser handles DRM.
      '';
    };
  };

  config = mkIf config.my.chromium.enable {
    programs.chromium = {
      enable = true;
      # enableWideVine bundles Google's Widevine CDM (extracted from the
      # official Chrome package) so DRM streaming (Netflix, Spotify, ...)
      # works. Prebuilt binary — does not trigger a Chromium source rebuild.
      package = pkgs.ungoogled-chromium.override { enableWideVine = config.my.chromium.widevine; };
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
        { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
      ];
      commandLineArgs = [
        # Wayland support
        "--ozone-platform-hint=auto"

        # Hardware acceleration
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--ignore-gpu-blocklist"
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,VaapiIgnoreDriverChecks,AcceleratedVideoDecodeLinuxGL,CanvasOopRasterization,WebRTCPipeWireCapturer"

        # Privacy
        "--disable-features=MediaRouter"
        "--no-default-browser-check"
        "--disable-breakpad"
        "--disable-domain-reliability"
        "--disable-client-side-phishing-detection"
      ];
    };
  };
}
