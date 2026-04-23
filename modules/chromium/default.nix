{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
with lib;

let
  vaDriver =
    if (osConfig.graphics.amd or false) then
      "radeonsi"
    else if (osConfig.graphics.intel.enable or false) then
      (if (osConfig.graphics.intel.generation or "modern") == "legacy" then "i965" else "iHD")
    else
      "iHD";
in
{
  options.chromium = {
    enable = mkEnableOption "Enable Ungoogled Chromium browser";
  };

  config = mkIf config.chromium.enable {
    home.sessionVariables = {
      LIBVA_DRIVER_NAME = vaDriver;
    };

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

        # Hardware acceleration
        "--use-gl=egl"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--ignore-gpu-blocklist"
        "--enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecoder,VaapiVideoEncoder,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE"

        # Privacy
        "--disable-features=MediaRouter,UseChromeOSDirectVideoDecoder"
        "--no-default-browser-check"
        "--disable-breakpad"
        "--disable-domain-reliability"
        "--disable-client-side-phishing-detection"
      ];
    };
  };
}
