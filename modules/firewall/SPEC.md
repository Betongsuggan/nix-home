# Firewall

Enables the NixOS firewall and allows specifying open TCP and UDP ports for incoming traffic.

## Usage

```nix
firewall = {
  enable = true;
  tcpPorts = [ 22 80 443 ];
  udpPorts = [ 53 ];
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable firewall |
| tcpPorts | list of port | [] | Allowed incoming TCP port traffic |
| udpPorts | list of port | [] | Allowed incoming UDP port traffic |
