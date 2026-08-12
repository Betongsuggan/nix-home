{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.notifications;

  # Category presets: one visual identity per kind of notification.
  # Senders pick a category and supply the text; any field can still be
  # overridden per call (e.g. urgency for battery-critical).
  categories = {
    volume     = { appName = "Volume";     icon = "audio-volume-high";        urgency = "low";    replaceTag = "volume";     timeout = 2000; };
    brightness = { appName = "Brightness"; icon = "display-brightness";       urgency = "low";    replaceTag = "brightness"; timeout = 2000; };
    media      = { appName = "Media";      icon = "multimedia-player";        urgency = "low";    replaceTag = "media";      timeout = 5000; };
    battery    = { appName = "Battery";    icon = "battery";                  urgency = "low";    replaceTag = "battery";    };
    network    = { appName = "Network";    icon = "network-wireless";         urgency = "low";    replaceTag = "network";    };
    power      = { appName = "Power";      icon = "system-shutdown";          urgency = "normal"; replaceTag = "power";      timeout = 2000; };
    system     = { appName = "System";     icon = "utilities-system-monitor"; urgency = "low";    replaceTag = "system";     };
    workspace  = { appName = "Workspaces"; icon = "virtual-desktops";         urgency = "low";    replaceTag = "workspace";  timeout = 3000; };
    time       = { appName = "Time";       icon = "clock";                    urgency = "low";    replaceTag = "time";       timeout = 5000; };
    recording  = { appName = "Recording";  icon = "media-record";             urgency = "normal"; replaceTag = "recording";  timeout = 3000; };
  };

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
    , progress ? null
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

    # Progress bar value (rendered as a bar by dunst)
    progressFlag = optionalString (progress != null)
      "-h int:value:${toString progress}";

    summaryArg = "\"${summary}\"";
    bodyArg = optionalString (body != "") "\"${body}\"";

  in "${pkgs.dunst}/bin/dunstify ${urgencyFlag} ${iconFlag} ${appNameFlag} ${timeoutFlag} ${hintFlags} ${stackTagFlag} ${progressFlag} ${summaryArg} ${bodyArg}";

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
    , progress ? null
  }: let
    urgencyFlag = "-u ${urgency}";
    iconFlag = optionalString (icon != null) "-i ${icon}";
    appNameFlag = optionalString (appName != null) "-a \"${appName}\"";
    timeoutFlag = optionalString (timeout != null) "-t ${toString timeout}";

    hintFlags = concatStringsSep " " (
      mapAttrsToList (k: v: "-h ${k}:${toString v}") hints
    );

    progressFlag = optionalString (progress != null)
      "-h int:value:${toString progress}";

    summaryArg = "\"${summary}\"";
    bodyArg = optionalString (body != "") "\"${body}\"";

  in "${pkgs.libnotify}/bin/notify-send ${urgencyFlag} ${iconFlag} ${appNameFlag} ${timeoutFlag} ${hintFlags} ${progressFlag} ${summaryArg} ${bodyArg}";

  # Main notification function - delegates to backend after merging in the
  # category preset (explicit args win over the preset)
  notifyCmd = args:
    let
      preset =
        if args ? category
        then categories.${args.category}
        else { };
      merged = preset // removeAttrs args [ "category" ];
    in
    if cfg.backend == "dunst" then buildDunstifyCmd merged
    else if cfg.backend == "mako" then buildNotifySendCmd merged
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

    windowManager = mkOption {
      type = types.enum [ "hyprland" "niri" "sway" "i3" "generic" ];
      default = "generic";
      description = "Window manager for session integration.";
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
            category = "battery";   # preset: appName, icon, urgency,
                                    # replaceTag, timeout (any overridable)
            summary = "Battery low";
            body = "15% remaining";
            progress = 15;          # progress bar value (0-100)
            urgency = "normal";     # override preset: "low", "normal", "critical"
            icon = "battery-low";   # override preset icon
            appName = "Battery";    # override preset header
            hints = {};             # extra backend-specific hints
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