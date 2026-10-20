{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.my.shelly-plug;
  plugs = inputs.self.lib.plugs;

  # `plug-<name> [status|on|off|toggle]`: the Shelly Gen2+ RPC over plain
  # HTTP. Every tailnet host reaches the plugs directly (the home LAN is a
  # subnet route), so unlike `wake-<host>` there is no relay.
  plugCli =
    name: p:
    pkgs.writeShellApplication {
      name = "plug-${name}";
      runtimeInputs = [ pkgs.curl ];
      text = ''
        rpc() { curl -sSf -m 3 "http://${p.address}/rpc/$1"; echo; }
        case "''${1:-status}" in
          status) rpc 'Switch.GetStatus?id=0' ;;
          on) rpc 'Switch.Set?id=0&on=true' ;;
          off) rpc 'Switch.Set?id=0&on=false' ;;
          toggle) rpc 'Switch.Toggle?id=0' ;;
          *)
            echo "usage: plug-${name} [status|on|off|toggle]" >&2
            exit 64
            ;;
        esac
      '';
    };

  cli = pkgs.symlinkJoin {
    name = "shelly-plug-cli";
    paths = mapAttrsToList plugCli plugs;
  };

  # json_exporter: one module, the plug's Switch.GetStatus document. Booleans
  # become 1/0; `aenergy.total` is Wh since the plug's counter was last reset.
  exporterConfig = (pkgs.formats.yaml { }).generate "shelly-json-exporter.yaml" {
    modules.default.metrics = [
      {
        name = "shelly_switch_on";
        path = "{ .output }";
        help = "1 while the relay is closed";
      }
      {
        name = "shelly_power_watts";
        path = "{ .apower }";
        help = "Active power";
      }
      {
        name = "shelly_voltage_volts";
        path = "{ .voltage }";
        help = "Supply voltage";
      }
      {
        name = "shelly_current_amperes";
        path = "{ .current }";
        help = "Current";
      }
      {
        name = "shelly_energy_watthours_total";
        path = "{ .aenergy.total }";
        valuetype = "counter";
        help = "Energy since the plug's counter was reset";
      }
      {
        name = "shelly_temperature_celsius";
        path = "{ .temperature.tC }";
        help = "Plug temperature";
      }
    ];
  };
  exporterPort = config.services.prometheus.exporters.json.port;

  # Grafana dashboard, built here rather than exported from the UI (no
  # `${DS_…}` placeholders to substitute). Two panels per row.
  panel =
    i:
    {
      title,
      expr,
      type ? "timeseries",
      unit ? null,
      legend ? "{{plug}}",
      extra ? { },
    }:
    {
      id = i + 1;
      inherit title type;
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      gridPos = {
        x = 12 * (mod i 2);
        y = 8 * (i / 2);
        w = 12;
        h = 8;
      };
      fieldConfig.defaults = optionalAttrs (unit != null) { inherit unit; };
      targets = [
        {
          inherit expr;
          legendFormat = legend;
          refId = "A";
        }
      ];
    }
    // extra;

  dashboard = pkgs.writeText "shelly.json" (
    builtins.toJSON {
      uid = "shelly";
      title = "Smart plugs";
      editable = false;
      schemaVersion = 39;
      refresh = "30s";
      time = {
        from = "now-24h";
        to = "now";
      };
      panels = imap0 panel [
        {
          title = "Power";
          expr = "shelly_power_watts";
          unit = "watt";
        }
        {
          title = "Relay";
          expr = "shelly_switch_on";
          type = "stat";
          extra = {
            fieldConfig.defaults.mappings = [
              {
                type = "value";
                options = {
                  "0" = {
                    text = "off";
                    color = "red";
                  };
                  "1" = {
                    text = "on";
                    color = "green";
                  };
                };
              }
            ];
            options = {
              colorMode = "background";
              reduceOptions.calcs = [ "lastNotNull" ];
            };
          };
        }
        {
          title = "Energy per day";
          expr = "increase(shelly_energy_watthours_total[1d])";
          type = "bargauge";
          unit = "watth";
          extra.options.reduceOptions.calcs = [ "lastNotNull" ];
        }
        {
          title = "Total power";
          expr = "sum(shelly_power_watts)";
          type = "stat";
          unit = "watt";
          legend = "all plugs";
          extra.options.reduceOptions.calcs = [ "lastNotNull" ];
        }
        {
          title = "Total energy per day";
          expr = "sum(increase(shelly_energy_watthours_total[1d]))";
          type = "stat";
          unit = "watth";
          legend = "all plugs";
          extra.options.reduceOptions.calcs = [ "lastNotNull" ];
        }
        {
          title = "Voltage";
          expr = "shelly_voltage_volts";
          unit = "volt";
        }
        {
          title = "Temperature";
          expr = "shelly_temperature_celsius";
          unit = "celsius";
        }
      ];
    }
  );
in
{
  options.my.shelly-plug = {
    enable = mkOption {
      type = types.bool;
      default = plugs != { } && config.services.tailscale.enable;
      defaultText = literalMD "a tailnet member, when the registry has plugs";
      description = ''
        `plug-<name>` for every plug in the registry (`lib.plugs`): status,
        on, off, toggle over the plug's local HTTP RPC. Reachable from any
        tailnet host because the home LAN is a subnet route.
      '';
    };

    manage = mkOption {
      type = types.bool;
      default = config.my.monitoring.enable;
      defaultText = literalExpression "config.my.monitoring.enable";
      description = ''
        This host asserts the plugs' device settings from the registry
        (name; `restore_last` power-on state for plugs that power a host)
        and, when `my.monitoring` runs here, scrapes them into Grafana.
        One host per fleet.
      '';
    };

    package = mkOption {
      type = types.package;
      readOnly = true;
      default = cli;
      description = "The `plug-*` commands (the fleet dashboard runs them).";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cli ];

    # Idempotent; what survives the next factory reset. A plug that is away
    # fails the unit, which retries, so the journal says which one.
    systemd.services.shelly-plug-config = mkIf cfg.manage {
      description = "Assert Shelly plug settings from the registry";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [ pkgs.curl ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "5min";
        DynamicUser = true;
      };
      script = ''
        rc=0
        rpc() {
          local plug=$1 method=$2
          shift 2
          curl -sSf -m 5 -G "http://$plug/rpc/$method" "$@" > /dev/null
        }
      ''
      + concatStrings (
        mapAttrsToList (
          name: p:
          let
            nameConfig = escapeShellArg "config=${builtins.toJSON { device.name = p.description; }}";
            switchConfig = escapeShellArg "config=${builtins.toJSON { initial_state = "restore_last"; }}";
          in
          ''
            rpc ${p.address} Sys.SetConfig --data-urlencode ${nameConfig} \
              || { echo "${name}: Sys.SetConfig failed" >&2; rc=1; }
          ''
          + optionalString (p.owner != null) ''
            rpc ${p.address} Switch.SetConfig --data-urlencode id=0 --data-urlencode ${switchConfig} \
              || { echo "${name}: Switch.SetConfig failed" >&2; rc=1; }
          ''
        ) plugs
      )
      + ''
        exit $rc
      '';
    };

    services.prometheus.exporters.json = mkIf (cfg.manage && config.my.monitoring.enable) {
      enable = true;
      listenAddress = "127.0.0.1";
      configFile = exporterConfig;
    };

    my.monitoring = mkIf (cfg.manage && config.my.monitoring.enable) {
      scrapeConfigs = [
        {
          job_name = "shelly";
          metrics_path = "/probe";
          static_configs = mapAttrsToList (name: p: {
            targets = [ "http://${p.address}/rpc/Switch.GetStatus?id=0" ];
            labels = {
              plug = name;
            }
            // optionalAttrs (p.owner != null) { host = p.owner; };
          }) plugs;
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "plug" ];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = "127.0.0.1:${toString exporterPort}";
            }
          ];
        }
      ];
      dashboards.shelly = dashboard;
    };
  };
}
