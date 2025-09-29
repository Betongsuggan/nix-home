{ config, lib, pkgs, ... }:
with lib;

{
  options.bluetooth = {
    enable = mkEnableOption "Enable Bluetooth";

    wake = {
      enable = mkEnableOption "Enable Bluetooth wake functionality";

      allowedDevices = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description =
          "List of bluetooth device MAC addresses allowed to wake the system";
        example = [ "AA:BB:CC:DD:EE:FF" "11:22:33:44:55:66" ];
      };
    };
  };

  config = mkIf config.bluetooth.enable {
    services.blueman.enable = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = mkIf config.bluetooth.wake.enable {
        General = { Enable = "Source,Sink,Media,Socket"; };
      };
    };

    # Enable bluetooth wake support
    services.udev.extraRules = mkIf config.bluetooth.wake.enable ''
      # Enable wake for bluetooth USB controller and disable autosuspend
      ACTION=="add", SUBSYSTEM=="usb", DRIVER=="btusb", ATTR{power/wakeup}="enabled", ATTR{power/autosuspend}="-1"

      # Enable wake for bluetooth HID devices (controllers)
      ACTION=="add", SUBSYSTEM=="input", KERNEL=="event*", SUBSYSTEMS=="bluetooth", ATTR{power/wakeup}="enabled"

      # Enable wake for specific bluetooth devices
      ${concatMapStringsSep "\n" (device:
        ''
          ACTION=="add", SUBSYSTEM=="bluetooth", ATTR{address}=="${device}", ATTR{power/wakeup}="enabled"'')
      config.bluetooth.wake.allowedDevices}
    '';

    # Add power management configuration
    boot.kernelParams = mkIf config.bluetooth.wake.enable [
      "btusb.enable_autosuspend=n"
      "usbcore.autosuspend=-1"
    ];

    # Configure bluetooth service to maintain connection during suspend
    systemd.services.bluetooth = mkIf config.bluetooth.wake.enable {
      serviceConfig = {
        ExecStartPost = "${pkgs.bash}/bin/bash -c 'sleep 2; echo enabled > /sys/class/bluetooth/hci0/power/wakeup || true'";
      };
    };

    # Add systemd sleep hook to keep bluetooth active
    systemd.services.bluetooth-wake-setup = mkIf config.bluetooth.wake.enable {
      description = "Setup Bluetooth for wake functionality";
      wantedBy = [ "sleep.target" ];
      before = [ "sleep.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = pkgs.writeShellScript "bluetooth-wake-setup" ''
          # Keep bluetooth controller awake during suspend
          if [ -f /sys/class/bluetooth/hci0/power/wakeup ]; then
            echo enabled > /sys/class/bluetooth/hci0/power/wakeup || true
          fi
          
          # Find and configure all USB bluetooth devices
          for device_path in /sys/bus/usb/drivers/btusb/*/; do
            if [ -d "$device_path" ]; then
              # Extract just the device name (e.g., "1-8:1.0")
              device_name=$(basename "$device_path")
              
              # Skip if it's not a device directory (bind, unbind, etc.)
              if [[ "$device_name" =~ ^[0-9]+-[0-9]+:[0-9]+\.[0-9]+$ ]]; then
                # Get the USB device path (parent of the interface)
                usb_device_path=$(dirname $(readlink -f "$device_path"))
                
                # Enable wake and disable autosuspend for the USB device
                if [ -f "$usb_device_path/power/wakeup" ]; then
                  echo enabled > "$usb_device_path/power/wakeup" 2>/dev/null || true
                fi
                if [ -f "$usb_device_path/power/autosuspend" ]; then
                  echo -1 > "$usb_device_path/power/autosuspend" 2>/dev/null || true
                fi
              fi
            fi
          done
        '';
      };
    };

  };
}
