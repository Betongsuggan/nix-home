{ config, pkgs, lib, ... }:
with lib;

{
  options.autorandr = {
    enable = mkEnableOption "Enable Autorandr";

    monitors = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          edid = mkOption {
            type = types.str;
            description = "Monitor EDID fingerprint string";
          };
        };
      });
      default = {};
      description = ''
        Monitor definitions by name. Each monitor has an EDID fingerprint.
        Example:
          monitors.laptop.edid = "00ffffffffffff00...";
          monitors.external.edid = "00ffffffffffff00...";
      '';
      example = {
        laptop = { edid = "00ffffffffffff004d10..."; };
        external = { edid = "00ffffffffffff00410c..."; };
      };
    };

    profiles = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          fingerprint = mkOption {
            type = types.attrsOf types.str;
            description = "Map of output names to EDID fingerprints";
          };
          config = mkOption {
            type = types.attrsOf (types.submodule {
              options = {
                enable = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Whether this output is enabled";
                };
                crtc = mkOption {
                  type = types.nullOr types.int;
                  default = null;
                  description = "CRTC index";
                };
                primary = mkOption {
                  type = types.bool;
                  default = false;
                  description = "Whether this is the primary output";
                };
                position = mkOption {
                  type = types.str;
                  default = "0x0";
                  description = "Position in format XxY";
                };
                mode = mkOption {
                  type = types.str;
                  description = "Resolution in format WIDTHxHEIGHT";
                };
                rate = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Refresh rate";
                };
              };
            });
            description = "Configuration for each output in the profile";
          };
        };
      });
      default = {};
      description = ''
        Autorandr profiles. Each profile specifies fingerprints to match
        and configuration for each matched output.
      '';
      example = {
        laptop = {
          fingerprint = { eDP-1 = "00ffffffffffff00..."; };
          config = {
            eDP-1 = {
              enable = true;
              primary = true;
              position = "0x0";
              mode = "1920x1200";
              rate = "59.95";
            };
          };
        };
      };
    };
  };

  config = mkIf (config.autorandr.enable) {
    programs.autorandr = {
      enable = true;
      profiles = mapAttrs (name: profile: {
        fingerprint = profile.fingerprint;
        config = mapAttrs (output: cfg: {
          inherit (cfg) enable primary position mode;
        } // optionalAttrs (cfg.crtc != null) {
          inherit (cfg) crtc;
        } // optionalAttrs (cfg.rate != null) {
          inherit (cfg) rate;
        }) profile.config;
      }) config.autorandr.profiles;
    };
  };
}
