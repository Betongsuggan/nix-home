# Password Manager

The Bitwarden desktop app, set up so the fingerprint (or the password) unlocks the vault. Through the app it also unlocks the Firefox and Chromium extensions, which those modules already install. Linux browsers have no fingerprint authenticator of their own, so this is the way to get biometric unlock in a browser.

## Usage

On by default for admins (`my.common.admins`) with the desktop profile.

```nix
my.password-manager.enable = true;   # any other user
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | admin with `my.profiles.desktop` | Install `bitwarden-desktop` |

## Behaviour

- Home Manager half: installs `bitwarden-desktop`.
- NixOS half: when any user has it on, installs Bitwarden's polkit action `com.bitwarden.Bitwarden.unlock` system-wide (only the policy file, taken from the package). Polkit reads actions only from the system profile, so the app can't register it itself on NixOS.
- The prompt comes from the session's polkit agent (`modules/window-manager`). The polkit-1 PAM service takes the fingerprint or the password (`modules/fingerprint`).

## Setup (once, per user)

1. Open Bitwarden, log in, then go to Settings → Security → **Unlock with system authentication** (it asks polkit once), and Settings → **Allow browser integration**. The app writes the browsers' native-messaging manifests itself, and rewrites them on every start, so they follow app updates.
2. In each browser's Bitwarden extension: Settings → Account security → **Unlock with biometrics**. The desktop app must be running and asks for confirmation the first time.
3. After a restart the vault needs the master password once before system unlock works again (Bitwarden's rule).
