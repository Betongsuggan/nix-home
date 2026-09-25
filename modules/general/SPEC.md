# General

The everyday CLI toolset for every user, headless machines included: system monitoring, archives, hardware diagnostics, YubiKey management. Enabled for everyone by the base Home Manager profile.

## Usage

```nix
my.general.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable the everyday CLI toolset |

## Notes

- Enables dconf and sets `XDG_DATA_HOME`.
- Packages: btop, htop, jq, lf, lm_sensors, lshw, pciutils, usbutils, powertop, p7zip, unzip, zip, exfat, gnumake, openssl, silver-searcher, ls-lint, yubikey-manager, dconf.
- GUI apps (gimp, gedit, gparted, imv, okular, vlc, wine) come with the Home Manager `desktop` profile (`modules/profiles/home.nix`); `ryzenadj` is a system package on AMD machines (power-management with `cpuVendor = "amd"`, gaming-station).
