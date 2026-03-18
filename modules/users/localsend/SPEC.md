# LocalSend

Installs LocalSend for LAN-based file sharing between devices. Optionally auto-starts with the desktop session and can include the jocalsend terminal client.

## Usage

```nix
localsend = {
  enable = true;
  autostart = true;
  cli = false;
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable LocalSend for LAN file transfer |
| autostart | bool | true | Automatically start LocalSend with desktop session |
| cli | bool | false | Also install jocalsend terminal client |

## Notes

- When autostart is enabled, LocalSend launches hidden (minimized to tray) via an XDG autostart desktop entry.
