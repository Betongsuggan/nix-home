# Bluetooth

Enables Bluetooth with Blueman applet support. Optionally configures Bluetooth wake-from-suspend functionality, allowing specific Bluetooth devices (e.g. controllers) to wake the system.

## Usage

```nix
bluetooth = {
  enable = true;
  wake = {
    enable = true;
    allowedDevices = [ "AA:BB:CC:DD:EE:FF" ];
  };
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Bluetooth |
| wake.enable | bool | false | Enable Bluetooth wake functionality |
| wake.allowedDevices | list of string | [] | Bluetooth MAC addresses allowed to wake the system |

## Notes

- Bluetooth is set to power on at boot.
- When wake is enabled, the module:
  - Adds udev rules to enable wakeup on btusb and Bluetooth HID devices.
  - Sets kernel parameters to disable USB autosuspend for Bluetooth (`btusb.enable_autosuspend=n`, `usbcore.autosuspend=-1`).
  - Creates a `bluetooth-wake-setup` systemd service that runs before suspend to keep the Bluetooth controller awake.
  - Configures the `bluetooth` systemd service to enable wakeup on `hci0` after start.
