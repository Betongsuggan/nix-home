# dns-filter

A filtering DNS resolver ([blocky](https://0xerr0r.github.io/blocky/)) for the whole home: every device that gets its DNS from the router's DHCP, and every tailnet member through headscale's pushed nameserver. Telemetry, ad and tracker domains answer `0.0.0.0`, so the LG TV, the robot vacuum and the phone on mobile data simply cannot reach them. Upstream queries leave the house encrypted (DNS-over-TLS), so the ISP sees none of them. Every query is logged per client to PostgreSQL and counted in Prometheus; with [[monitoring]] enabled, both arrive in Grafana with blocky's own dashboards.

Nothing is installed on any client.

## Usage

```nix
my.dns-filter = {
  enable = true;
  apiUrl = "https://dns.example.com";   # optional: lets the Grafana dashboard's on/off buttons reach blocky
};

# tailnet members resolve through it too
my.home-network.controller.headscale.nameservers = [ "<this host's tailnet IP>" ];

# optional: the API + /metrics for browsers on the tailnet
my.reverse-proxy.domains = [ "dns.example.com" ];
my.reverse-proxy.vhosts.dns = {
  domain = "dns.example.com";
  upstream = "http://127.0.0.1:4000";
  extraConfig = inputs.self.lib.tailnet.nginxAllowOnly [ ];
};
```

Then on the router (operator steps, see below): hand this host out as the DHCP DNS server and force stray port-53 traffic to it.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Run blocky |
| interfaces | list of str | `[ "tailscale0" ]` + `lib.hosts.<host>.lan.interface` | Interfaces on which port 53 (TCP+UDP) is opened. Blocky binds every address; the firewall decides who may ask. |
| upstreams | list of str | Quad9 + Mullvad over DoT | Resolvers blocky forwards to, blocky `[net:]host[:port]` syntax. Two are queried in parallel, fastest answer wins. |
| bootstrapDns | list of attrs | IPs for the two defaults | How the upstream hostnames and the list URLs get resolved before blocky can resolve anything. Every hostname in `upstreams` needs an entry. |
| router | null or str | `lib.hosts.<host>.lan.gateway` | Asked for reverse lookups so clients show up by DHCP hostname in the log and metrics. |
| reverseZones | list of str | the `in-addr.arpa` zone of `lib.hosts.<host>.lan.subnet` (if a /24) | Reverse zones forwarded to `router`. |
| blocklists | attrs of list of str | hagezi *Multi PRO* + the LG webOS, Samsung, Roku, Amazon and Xiaomi native-tracker lists | Named denylist groups: URLs, local files, or inline domains (`"example.com\n*.example.net"`). |
| allowlists | attrs of list of str | `{ }` | Per-group exceptions. The escape hatch when a list breaks something. |
| clientGroups | attrs of list of str | `{ default = <every blocklist>; }` | Which groups apply to which clients (blocky `clientGroupsBlock`): `default`, a client-name glob (`lg-*`), an IP, or a CIDR. |
| customDomains | attrs of str | `{ }` | Static name → address answers. |
| httpPort | port | 4000 | Loopback port for the HTTP API and `/metrics`. |
| apiUrl | null or str | null | Public (tailnet) URL of the API, baked into the Grafana dashboard's enable/disable buttons. |
| queryLog.enable | bool | true | Log every query to the local PostgreSQL database `blocky`. |
| queryLog.retentionDays | int | 30 | Days of query log kept. |

Anything blocky supports but this module does not expose goes straight into `services.blocky.settings` (it is merged with what the module sets).

## What it blocks, and what it cannot

- **Blocks:** any DNS name on the lists, for any device that asks this resolver. hagezi *Multi PRO* is a broad ads/tracking/telemetry/malware list ("works best if an admin nearby can unblock something"). The vendor *native* lists are small (a few hundred domains each) and target the trackers baked into those devices' firmware. Add more from [hagezi's `wildcard/`](https://github.com/hagezi/dns-blocklists/tree/main/wildcard) (`native.apple`, `native.tiktok`, `native.winoffice`, `native.huawei`, `tif` for pure threat intel, …) as `<name>-onlydomains.txt`.
- **Does not block:** a device that ignores DHCP and asks `8.8.8.8` directly, unless the router redirects port 53 (below). A device using DNS-over-HTTPS, or talking to a hardcoded IP, bypasses DNS entirely; only a per-device firewall rule on the router stops that. The query log is what tells you whether any device does this: a TV that is "quiet" in the log while clearly online is talking around DNS.
- **Does not isolate** IoT devices from the LAN. That is the router's guest network or VLANs.

## Router setup (ASUS, stock firmware)

1. **LAN → DHCP Server → DNS Server 1** = this host's LAN IP; leave DNS Server 2 empty, or devices will fall back to it when they feel like it.
2. **WAN → DNSFilter → Global Filter Mode** = *Custom 1*, with Custom DNS 1 = this host's LAN IP. This DNATs every outbound port-53 packet to the filter, which is what catches TVs with hardcoded resolvers.
3. On the same page, add **this host's MAC with filter mode *No Filtering***. Blocky's own plain-DNS lookups (`router` for reverse zones) would otherwise be redirected back to itself.
4. Renew DHCP on a client (or wait for leases to expire) and check with `nslookup ad.doubleclick.net`: the answer must be `0.0.0.0`.

Phones on the tailnet need nothing: headscale pushes the resolver.

## Notes

- **Serving first, lists second.** `blocking.loading.strategy = fast` starts answering before the lists are downloaded and keeps answering if GitHub is unreachable; lists refresh every 4 h. A list that fails to download is logged and retried, never fatal.
- **Availability.** This resolver is now what the house and every tailnet device uses. If the host is down, LAN clients have no DNS (the router hands out nothing else) and tailnet clients have none either (headscale overrides local DNS, and tailscale races every listed nameserver, so a public fallback would also leak unfiltered answers). That is a deliberate trade: the host is already the single point for everything else. Blocky itself restarts on failure and needs no network to start.
- **Loops.** `bootstrapDns` uses IPs, the upstreams are external, and the host's own resolver may point at `127.0.0.1`; blocky never asks itself. The one loop to avoid is router-side: DNSFilter must exempt this host (step 3).
- **Query log.** PostgreSQL table `log_entries` in database `blocky`, written by the service's dynamic user `blocky` over the socket (peer auth, no password). Blocky starts after `postgresql-setup.service` (which creates the role and database) but does not require it: if the database is unavailable it retries ten times, then logs queries to the journal instead, and DNS keeps working. A `queryLog: query resolved` line in `journalctl -u blocky` is the sign that this fallback is active. With [[monitoring]] enabled a `grafana` role gets `SELECT` on it (`blocky-querylog-grafana-grant.service`, also as default privileges for tables created later). Rows older than `retentionDays` are deleted by blocky. The database is not in the backup set: it is a log.
- **Client names** come from the router's reverse DNS of DHCP leases; a device with no hostname shows as its IP. `services.blocky.settings.clientLookup.clients` can name them by hand.
- **Dashboards.** Two upstream blocky dashboards are fetched pinned (`blocky-grafana.json`, Prometheus; `blocky-query-grafana-postgres.json`, the query log) and handed to [[monitoring]] with their datasource placeholders bound to the uids it provisions (`prometheus`, `blocky-querylog`). The enable/disable-blocking buttons on the first dashboard call `apiUrl` from the browser; without the reverse-proxy vhost they do nothing.
- **Unblocking something.** Prefer `allowlists.<group>` with an inline domain over removing a list. Check the query log first to find the exact name that was blocked (`responseReason` says which group).
