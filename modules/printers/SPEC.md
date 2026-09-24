# Printers

Enables CUPS printing support with drivers for common printer brands (HP, Brother, and others via Gutenprint).

## Usage

```nix
my.printers.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable printers |
| remoteDiscovery | bool | true | Run `cups-browsed` to discover printers shared by other machines on the LAN |

## Notes

- `cupsd` is socket-activated by NixOS (`services.printing.startWhenNeeded` defaults to
  true), so it normally stays stopped until something prints.
- `cups-browsed` defeats that. It is enabled by default whenever Avahi is on, it is wanted
  by `multi-user.target`, and it connects to the CUPS socket as soon as it starts — which
  pulls `cupsd` up at every boot. Setting `remoteDiscovery = false` drops `cups-browsed`
  entirely and lets the socket activation do its job.
- Disabling it does not affect Avahi itself, which other modules use for SMB share
  discovery. Only the discovery of *remote shared printers* is lost; directly configured
  printers are unaffected.
