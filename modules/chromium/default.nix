{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.chromium = {
    enable = mkEnableOption "Enable Ungoogled Chromium browser";
  };

  config = mkIf config.chromium.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.ungoogled-chromium;
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
        { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
      ];
      commandLineArgs = [
        # Wayland support
        "--ozone-platform-hint=auto"
        "--enable-features=UseOzonePlatform,WaylandWindowDecorations"
        # Hardware acceleration
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        # Privacy
        "--disable-features=MediaRouter"
        "--no-default-browser-check"
      ];
    };
  };
}
