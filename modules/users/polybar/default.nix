{ config, pkgs, lib, ... }:
with lib;

let
  cfg = config.br.polybar;
  theme = import ../theming/theme.nix {};
in
{
  options.br.polybar = {
    enable = mkEnableOption "Enable Polybar";
  };

  config = mkIf (cfg.enable) {
    services.polybar = {
      enable = true;
      package = pkgs.polybar.override {
        i3GapsSupport = true;
        pulseSupport = true;
      };
      config = with builtins; {
        "bar/bottom" = {
          monitor = "eDP-1";
          bottom = true;
          width = "100%";
          height = "2%";
          radius = 0;
          wm-restack = "i3";
          module-margin-left = 1;
          module-margin-right = 1;
          modules-center = "i3";
          modules-right = "date pulseaudio battery backlight";
          modules-left = "cpu memory";
          background = theme.colors.background;
          foreground = theme.colors.utilityText;

          font-0 = "${theme.font.name},${theme.font.style}:size=10";
          font-1 = "${theme.font.name},${theme.font.style}:size=20";
          font-2 = "${theme.font.name},${theme.font.style}:size=18;1";

          tray-position = "right";
          tray-padding = 1;
        };
        "module/i3" = {
          type = "internal/i3";
          label-focused = "%index%";
          label-focused-background = "${theme.colors.utilityText}";
          label-focused-foreground = "${theme.colors.background}";
          label-focused-alignment = "center";
          label-focused-padding = 1;

          label-unfocused = "%index%";
          label-unfocused-background = "${theme.colors.background}";
          label-unfocused-foreground = "${theme.colors.utilityText}";
          label-unfocused-alignment = "center";
          label-unfocused-padding = 1;
        };
        "module/pulseaudio" = {
          type = "internal/pulseaudio";
          sink = "alsa_output.pci-0000_00_1f.3.analog-stereo";
          use-ui-max = false;
          interval = 5;

          label-muted = "ﱝ";
          label-muted-font = 2;
          label-muted-foreground = "#666";

          format-volume = "<ramp-volume>";
          format-volume-font = 2;

          ramp-volume-0 = "";
          ramp-volume-1 = "";
          ramp-volume-2 = "";
        };
        "module/battery" = {
          type = "internal/battery";
          battery = "BAT0";
          adapter = "ADP1";
          full-at = "98";

          format-full-font = 2;
          label-full = "";

          format-discharging = "<ramp-capacity>";
          format-discharging-font = 2;
          ramp-capacity-0 = "";
          ramp-capacity-0-foreground = "${theme.colors.alertText}";
          ramp-capacity-1 = "";
          ramp-capacity-1-foreground = "${theme.colors.utilityText}";
          ramp-capacity-2 = "";
          ramp-capacity-3 = "";
          ramp-capacity-4 = "";
          ramp-capacity-foreground = "${theme.colors.secondaryText}";
          
          format-charging = "<animation-charging>";
          format-charging-font = 2;
          animation-charging-0 = "";
          animation-charging-1 = "";
          animation-charging-2 = "";
          animation-charging-3 = "";
          animation-charging-4 = "";
          animation-charging-foreground = "${theme.colors.secondaryText}";
          animation-charging-framerate = "750";
        };
        "module/backlight" = {
          type = "internal/backlight";
          card = "intel_backlight";
          use-actual-backlight = true;
          format = "<ramp>";
          format-font = 3;

          ramp-0 = "";
          ramp-1 = "";
          ramp-2 = "";
          ramp-3 = "";
          ramp-4 = "";
        };
        "module/date" = {
          type = "internal/date";
          internal = 5;
          date = "%Y-%m-%d";
          time = "%H:%M:%S";
          label = "%date% %time%";
        };
        "module/cpu" = {
          type = "internal/cpu";
          
          interval = "0.5";
          label = ": %percentage%%";
        };
        "module/memory" = {
          type = "internal/memory";
          
          interval = 3;
          format =  "<ramp-used> <label> <ramp-free>";

          label = "%gb_used% | %gb_free%";
          ramp-used-0 = "▁";
          ramp-used-1 = "▂";
          ramp-used-2 = "▃";
          ramp-used-3 = "▄";
          ramp-used-4 = "▅";
          ramp-used-5 = "▆";
          ramp-used-6 = "▇";
          ramp-used-7 = "█";

          label-free = "%gb_free%";
          ramp-free-0 = "▁";
          ramp-free-1 = "▂";
          ramp-free-2 = "▃";
          ramp-free-3 = "▄";
          ramp-free-4 = "▅";
          ramp-free-5 = "▆";
          ramp-free-6 = "▇";
          ramp-free-7 = "█";
        };
      };
      script = import ./launcher.nix { pkgs = pkgs; };
    };
  };
}
