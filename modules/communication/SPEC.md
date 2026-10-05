# Communication

Installs communication applications: Slack always, Discord on request. Enabled by default on the Home Manager `desktop` profile.

## Usage

```nix
my.communication.enable = true;
my.communication.discord = true; # work laptop without the games module
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable communication tooling |
| discord | bool | false | Also install Discord. Hosts with `my.games` get Discord from that module already; this is for hosts without it |
