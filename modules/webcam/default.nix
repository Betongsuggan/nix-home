{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.webcam;

  cameraType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Identifier used in the generated script name (no spaces).";
        example = "mx-brio";
      };
      vendorId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''USB vendor ID (4 hex digits, e.g. "046d" for Logitech). Omit to match any vendor.'';
        example = "046d";
      };
      productId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''USB product ID (4 hex digits). Omit to match any product.'';
        example = "085b";
      };
      settings = mkOption {
        type = types.attrsOf types.int;
        default = {};
        description = "v4l2-ctl control name → integer value map. Discover controls with: v4l2-ctl --list-ctrls-menus";
        example = literalExpression ''
          {
            brightness = 128;
            contrast   = 128;
            saturation = 100;
          }
        '';
      };
    };
  };

  mkCtrlArg = settings:
    concatStringsSep ","
      (mapAttrsToList (ctrl: val: "${ctrl}=${toString val}") settings);

  mkCameraScript = camera:
    pkgs.writeShellScript "webcam-apply-${camera.name}" ''
      ${pkgs.v4l-utils}/bin/v4l2-ctl \
        --device=/dev/$1 \
        --set-ctrl=${mkCtrlArg camera.settings}
    '';

  mkUdevRule = camera:
    let
      script       = mkCameraScript camera;
      vendorMatch  = optionalString (camera.vendorId  != null) ''ATTRS{idVendor}=="${camera.vendorId}", '';
      productMatch = optionalString (camera.productId != null) ''ATTRS{idProduct}=="${camera.productId}", '';
    in
    # ATTR{index}=="0" targets only the primary capture node, not the metadata node
    # (both appear under video4linux with the same USB IDs)
    ''ACTION=="add", SUBSYSTEM=="video4linux", ATTR{index}=="0", ${vendorMatch}${productMatch}RUN+="${script} %k"'';

  camerasWithSettings = builtins.filter (c: c.settings != { }) cfg.cameras;

in
{
  options.webcam = {
    enable = mkEnableOption "webcam settings management";

    cameras = mkOption {
      type = types.listOf cameraType;
      default = [ ];
      description = "List of cameras whose v4l2 controls are applied on device add.";
      example = literalExpression ''
        [{
          name      = "mx-brio";
          vendorId  = "046d";
          productId = "085b";
          settings  = { brightness = 128; contrast = 128; };
        }]
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.cameractrls-gtk4 # GUI for discovering/adjusting controls interactively (GTK4, Wayland-native)
      pkgs.v4l-utils # CLI: v4l2-ctl, v4l2-compliance
    ];

    services.udev.extraRules =
      concatMapStringsSep "\n" mkUdevRule camerasWithSettings;
  };
}
