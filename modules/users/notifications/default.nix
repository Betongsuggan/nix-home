{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.notifications;

  # Helper to build dunst command
  buildDunstifyCmd = {
    urgency ? "normal"
    , icon ? null
    , appName ? null
    , summary
    , body ? ""
    , hints ? {}
    , timeout ? null
    , replaceTag ? null
  }: let
    urgencyFlag = "-u ${urgency}";
    iconFlag = optionalString (icon != null) "-i ${icon}";
    appNameFlag = optionalString (appName != null) "-a \"${appName}\"";
    timeoutFlag = optionalString (timeout != null) "-t ${toString timeout}";

    # Build hint flags: -h key:value
    hintFlags = concatStringsSep " " (
      mapAttrsToList (k: v: "-h ${k}:${toString v}") hints
    );

    # Stack tag for replacing notifications
    stackTagFlag = optionalString (replaceTag != null)
      "-h string:x-dunst-stack-tag:${replaceTag}";

    summaryArg = "\"${summary}\"";
    bodyArg = optionalString (body != "") "\"${body}\"";

  in "${pkgs.dunst}/bin/dunstify ${urgencyFlag} ${iconFlag} ${appNameFlag} ${timeoutFlag} ${hintFlags} ${stackTagFlag} ${summaryArg} ${bodyArg}";

  # Helper to build mako/notify-send command
  buildNotifySendCmd = {
    urgency ? "normal"
    , icon ? null
    , appName ? null
    , summary
    , body ? ""
    , timeout ? null
    , hints ? {}
    , replaceTag ? null  # notify-send doesn't support this natively
  }: let
    urgencyFlag = "-u ${urgency}";
    iconFlag = optionalString (icon != null) "-i ${icon}";
    appNameFlag = optionalString (appName != null) "-a \"${appName}\"";
    timeoutFlag = optionalString (timeout != null) "-t ${toString timeout}";

    hintFlags = concatStringsSep " " (
      mapAttrsToList (k: v: "-h ${k}:${toString v}") hints
    );

    summaryArg = "\"${summary}\"";
    bodyArg = optionalString (body != "") "\"${body}\"";

  in "${pkgs.libnotify}/bin/notify-send ${urgencyFlag} ${iconFlag} ${appNameFlag} ${timeoutFlag} ${hintFlags} ${summaryArg} ${bodyArg}";

  # Main notification function - delegates to backend
  notifyCmd = args:
    if cfg.backend == "dunst" then buildDunstifyCmd args
    else if cfg.backend == "mako" then buildNotifySendCmd args
    else throw "Unsupported notification backend: ${cfg.backend}";

in {
  imports = [
    ./dunst
    ./mako
  ];

  options.notifications = {
    enable = mkEnableOption "notification system";

    backend = mkOption {
      type = types.enum [ "dunst" "mako" ];
      default = "dunst";
      description = "Which notification daemon to use";
    };

    # Expose the notification function for other modules to use
    send = mkOption {
      type = types.functionTo types.str;
      internal = true;
      readOnly = true;
      description = ''
        Function to generate notification commands.

        Usage:
          config.notifications.send {
            urgency = "low";        # "low", "normal", "critical"
            icon = "battery-low";   # icon name
            appName = "Battery";    # application name
            summary = "Low Battery";
            body = "15% remaining";
            hints = {               # backend-specific hints
              "int:value" = 15;     # progress bar value (dunst)
            };
            timeout = 5000;         # milliseconds
            replaceTag = "battery"; # tag for replacing notifications (dunst)
          }

        Returns a shell command string.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Set the notification function
    notifications.send = notifyCmd;

    # Add papirus icons for better notification visuals
    home.packages = [ pkgs.papirus-icon-theme ];
  };
}