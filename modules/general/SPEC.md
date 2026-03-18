# General

Installs a collection of general-purpose desktop utilities and tools for everyday use, including system monitoring, file management, media viewing, and hardware diagnostics.

## Usage

```nix
general.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable general desktop programs |

## Notes

- Enables dconf and sets `XDG_DATA_HOME`.
- Installed packages include: btop, htop, gimp, gedit, gparted, vlc, wine, jq, lf, imv, okular, wf-recorder, p7zip, unzip, zip, powertop, ryzenadj, yubikey-manager, and various system utilities.
