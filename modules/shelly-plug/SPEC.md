# Shelly plug

Shelly Plug S Gen3 smart plugs on the home LAN, driven over their local HTTP RPC: no Shelly account, app or cloud. Every tailnet host gets a `plug-<name>` command per registry plug; one host (the one running [[monitoring]]) asserts the plugs' settings from the registry and scrapes them into Grafana. Hosts that are powered through a plug say so in the registry, and the [[fleet-status]] dashboard (Mod+G) shows their power state and switches it.

## Usage

Nothing to set on a host: the commands are on wherever tailscale is, management follows `my.monitoring`. Everything else is the registry (`lib/default.nix`):

```nix
devices.desktop = {
  type = "shelly-plug";
  description = "Desktop host plug";   # written to the plug as its device name
  address = "192.168.50.201";          # a DHCP reservation on the router, keyed by mac
  mac = "48:f6:ee:b6:39:50";
};
hostEntries.desktop.plug = "desktop";   # this host is powered through that plug
```

`lib.plugs` is the derived view: the shelly-plug devices with `owner` (the host whose `plug` names it, or null).

```bash
plug-desktop            # status JSON: output, apower, voltage, current, aenergy, temperature
plug-desktop on|off|toggle
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | tailscale on and the registry has plugs | Install `plug-<name>` for every plug |
| manage | bool | `my.monitoring.enable` | Assert plug settings from the registry on boot, and scrape metrics where monitoring runs. One host per fleet. |
| package | package (read-only) | | The `plug-*` commands, for the fleet dashboard |

## Behaviour

- **Reachability**: controller advertises the home LAN into the tailnet and every member accepts routes, so `plug-*` talks to `http://<address>/rpc/…` directly from anywhere on the tailnet, with a 3 s timeout. No relay, unlike `wake-<host>` (a magic packet is an L2 broadcast). The plugs themselves stay LAN-only.
- **Asserted settings** (`shelly-plug-config.service`, oneshot after network-online, on the managing host): `Sys.SetConfig` the device name from `description` for every plug, and `Switch.SetConfig initial_state = restore_last` for plugs that power a host. Without the latter a plug comes back *off* after a power cut and the host never boots (the factory default is `off`). The unit fails and retries every 5 min while a plug is unreachable, naming it in the journal. Plugs without an owner keep their own `initial_state`.
- **Metrics**: nixpkgs' `json_exporter` on loopback (`services.prometheus.exporters.json`, port 7979) turns each plug's `Switch.GetStatus` into `shelly_switch_on`, `shelly_power_watts`, `shelly_voltage_volts`, `shelly_current_amperes`, `shelly_energy_watthours_total` (counter, Wh since the plug's own reset) and `shelly_temperature_celsius`, labelled `plug` (also `instance`) and `host` for owned plugs. One probe-style job `shelly` through `my.monitoring.scrapeConfigs`, 30 s like everything else.
- **Dashboard** "Smart plugs" (uid `shelly`), generated in Nix: power, relay state, energy per day (one series per plug), total power and total energy per day across all plugs, voltage, temperature.

## Setup and recovery

- **Addresses are DHCP reservations** on the ASUS router (MAC → address), never the plug's own static IP, so the router stays the one DHCP authority. Only reserved addresses belong in the registry.
- **A plug that fell off the WiFi** advertises only Matter commissioning over Bluetooth; Shelly's BLE RPC is off, so the Shelly app would not have helped either. The button holds (5 s reboot, 10 s factory reset) are only accepted **within 60 s of plugging the device in**: pull it, push it back, hold 10 s. The LED flashes blue and the plug runs an open `ShellyPlugSG3-<id>` access point. From a laptop: `nmcli dev wifi connect ShellyPlugSG3-<id>`, then

  ```bash
  curl -G http://192.168.33.1/rpc/WiFi.SetConfig \
    --data-urlencode 'config={"sta":{"ssid":"<home ssid>","pass":"<password>","enable":true}}'
  ```

  Pulling a plug cuts its host: shut the host down first (desktop sleeps most of the time anyway; `ssh controller sudo systemctl poweroff` for controller, which boots again when the relay closes). A factory reset clears the name and `initial_state`; `shelly-plug-config` puts both back on the next boot of the managing host.
- No device password (`auth_en: false`); json_exporter has no digest auth and the LAN is not reachable from outside the tailnet.

## Verification

```bash
# any tailnet host
plug-printer | jq .apower

# managing host (controller)
systemctl status shelly-plug-config
curl -s 'http://192.168.50.201/rpc/Switch.GetConfig?id=0' | jq .initial_state   # "restore_last"
curl -s 'localhost:7979/probe?target=http://192.168.50.200/rpc/Switch.GetStatus?id=0'  # shelly_switch_on 1 + five more
# https://grafana.rydback.net → Smart plugs: three series
```
