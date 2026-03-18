{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
with lib;

{
  options.firefox = {
    enable = mkEnableOption "Enable Firefox browser for user";
  };

  config = mkIf config.firefox.enable {

    home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      LIBVA_DRIVER_NAME =
        if (osConfig.graphics.amd or false) then
          "radeonsi"
        else if (osConfig.graphics.intel.enable or false) then
          (if (osConfig.graphics.intel.generation or "modern") == "legacy" then "i965" else "iHD")
        else
          "iHD"; # Default fallback for standalone home-manager
    };
    programs.firefox = {
      enable = true;
      profiles.default = {
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          vimium
          ublock-origin
          bitwarden
          privacy-badger
          decentraleyes
          clearurls
          sponsorblock
        ];

        settings = {
          # Enable custom stylesheets for Stylix theming
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

          # Hardware acceleration
          "media.ffmpeg.vaapi.enabled" = true;
          "media.ffvpx.enabled" = true;
          "media.av1.enabled" = true;
          "gfx.webrender.all" = true;

          # Privacy & Security
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "privacy.donottrackheader.enabled" = true;
          "browser.send_pings" = false;
          "browser.urlbar.speculativeConnect.enabled" = false;
          "dom.event.clipboardevents.enabled" = true;
          "dom.allow_cut_copy" = true;
          "media.navigator.enabled" = true;
          "media.peerconnection.enabled" = true;
          "network.cookie.cookieBehavior" = 1;
          "network.http.referer.XOriginPolicy" = 2;
          "network.http.referer.XOriginTrimmingPolicy" = 2;

          # Performance
          "browser.cache.disk.enable" = false;
          "browser.cache.memory.enable" = true;
          "browser.cache.memory.capacity" = 524288;
          "browser.sessionstore.interval" = 30000;

          # UI/UX improvements
          "browser.download.useDownloadDir" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "extensions.pocket.enabled" = false;
          "browser.toolbars.bookmarks.visibility" = "always";

          # Smooth scrolling
          "general.smoothScroll" = true;
          "mousewheel.default.delta_multiplier_y" = 80;
        };

        search = {
          force = true;
          default = "ddg";
          engines = {
            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
            "NixOS Wiki" = {
              urls = [
                {
                  template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
                }
              ];
              icon = "https://wiki.nixos.org/favicon.ico";
              definedAliases = [ "@nw" ];
            };
            "GitHub" = {
              urls = [ { template = "https://github.com/search?q={searchTerms}"; } ];
              icon = "https://github.com/favicon.ico";
              definedAliases = [ "@gh" ];
            };
          };
        };
      };
    };
  };
}
