# Taildrop

Sends the clipboard, or any files, between tailnet devices (Linux hosts and Android phones) with Tailscale's built-in Taildrop, and collects what arrives. It adds no daemon, pairing or firewall port: Taildrop goes over the tailnet, and headscale allows it between nodes of the same headscale user (every fleet node is `birger`).

## Usage

On by default for an admin (`my.common.admins`) with the desktop profile on a host running tailscale. To turn it off:

```nix
my.taildrop.enable = false;
```

- **Send:** Mod+Shift+S (`taildrop-send`) lists `tailscale file cp --targets` in the launcher and sends the clipboard to the chosen device. An image is sent as `clipboard-<time>.png` and anything else as `clipboard-<time>.txt`. `taildrop-send FILE...` sends files instead.
- **Receive:** the `taildrop-receive` user service waits on the Taildrop inbox. A `clipboard-*` file is put on the clipboard and then deleted. Anything else is moved to `dir` (a taken name gets a ` (n)` suffix). Either way a notification is shown.
- **Android:** to send, share any file (or text, if the app offers it) → Tailscale → pick the host. Files sent to a phone show up in its Downloads through the Tailscale app. A file named `clipboard-*.txt` sent from the phone lands in the Linux clipboard.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | admin + desktop profile + tailscale | Send and receive with Taildrop |
| dir | str | `~/Downloads/taildrop` (XDG download dir) | Where received files are put |
| package | package (read-only) | `taildrop-send` | For keybinds |

## Notes

- `tailscale file get` needs root or the tailscale operator. The NixOS half makes the enabled user the operator (`services.tailscale.extraSetFlags = [ "--operator=<user>" ]`). Tailscale has only one operator, so an assertion allows only one taildrop user per host.
- Incoming files go through `dir/.incoming` before they are handled, so each file is processed once even if it has the same name as an older one.
- Only PNG images and text are sent from the clipboard. Other clipboard types are sent as text.
