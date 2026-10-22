# Controller

Minimal Intel NUC host intended as a controller/server. The long-term goal is to run headless without a desktop environment.

## Key Features

- Headless: no window manager; the Home Manager user gets the shell/CLI base only
- Alacritty terminal with Bash shell and Starship prompt
- Intel integrated graphics
- Audio via PipeWire
- NetworkManager with iwd backend
- OpenSSH server (port 22 reachable only on `tailscale0`)
- Minimal SSH git server (git-shell): `nix-vault.git` (the secrets flake input) and `wow-leveling.git` (the WoW Forever leveling guide, consumed as the `wow-guide` flake input and served at `https://rydback.net/wow/` through `modules/static-sites`)
- Nginx reverse proxy with per-domain Let's Encrypt certs (HTTP-01), auto-renewing; currently `rydback.net` (404 stub + the tailnet bootstrap blob endpoint), `vpn.rydback.net` (proxies to headscale), `vault.rydback.net` (vaultwarden, tailnet-only), `cloud.rydback.net` (Nextcloud, tailnet-only), `office.rydback.net` (OnlyOffice Document Server, tailnet-only), `dns.rydback.net` (blocky API + metrics, tailnet-only), `grafana.rydback.net` (Grafana, tailnet-only), and the AI lab front doors — `chat.rydback.net` (Open WebUI), `llm.rydback.net` (Ollama API), `images.rydback.net` (ComfyUI), `voice.rydback.net` (Speaches), all tailnet-only and fronting the local wake-proxy
- Wake-proxy: a small long-running Go TCP forwarder listening on `tailscale0` and loopback for the four AI ports (11434, 8081, 8188, 8000); sends WoL magic packets to `desktop` when the upstream is unreachable (cached "alive" flag so SPA bursts don't flood), then bridges the connection. See `modules/wake-proxy/SPEC.md`.
- Tailnet subnet router: advertises the home LAN `192.168.50.0/24` so tailnet peers (which run `--accept-routes` via `my.home-network`) can reach LAN devices from anywhere. LAN devices see incoming tailnet traffic SNATed to controller's LAN IP, so no return routes are needed on the router. Fully declarative: the route is applied via `tailscale set` on every daemon start (`my.home-network.advertiseRoutes`) and auto-approved by the headscale policy (`autoApprovedRoutes` is derived from every registry host with a `lan.subnet`: the home LAN here and the summer-place LAN `192.168.1.0/24` advertised by island-pi; it installs an allow-all ACL policy — see `modules/headscale/SPEC.md`). Named LAN devices get `<name>.home.rydback.net` A records via `extraDnsRecords` (currently `router.home.rydback.net` → 192.168.50.1); only DHCP-reserved/static addresses should be added there.
- `home-network` module in `controller` mode: bundles the headscale coordinator at `vpn.rydback.net` (embedded DERP relay, declaratively provisioned users), the rotated YubiKey-encrypted preauth-blob endpoint, and tailscale client membership. See `modules/home-network/SPEC.md` for the full onboarding doctrine. Headscale pushes this host's tailnet IP as the only nameserver, so every member resolves through the DNS filter below
- DNS filter for the house and the tailnet (`my.dns-filter`, blocky): port 53 on `enp1s0` and `tailscale0`, hagezi Multi PRO plus the LG/Samsung/Roku/Amazon/Xiaomi native-tracker lists, upstream over DNS-over-TLS to Quad9 and Mullvad, per-client query log in the local PostgreSQL (`blocky` DB, 30 days). The ASUS router hands this host out as the DHCP DNS server and its DNSFilter redirects stray port-53 traffic here (this host exempted). Controller's own NetworkManager profile resolves via `127.0.0.1`. See `modules/dns-filter/SPEC.md` for the router steps and what DNS filtering cannot catch
- Identity provider (`my.sso`, Kanidm 1.11) at `id.rydback.net`, tailnet-only behind nginx (Kanidm terminates TLS itself on 127.0.0.1:8443 with the vhost's cert, group `kanidm`). Persons from the registry (`operator.login` = `birger`), OIDC clients: `nextcloud` and `grafana` are registered by their own modules, `open-webui` (with the `openwebui_role` claim map and group `openwebui_admins`, since the service runs on desktop) and `vaultwarden` declared in `system.nix`; their secrets are `sso/clients/<name>` in the vault's `common.yaml`, the `admin`/`idm_admin` passwords `services/sso/*` in `controller.yaml`. Nightly Kanidm snapshots in `/var/backups/kanidm` (restic path). See `modules/sso/SPEC.md`
- Monitoring (`my.monitoring`): Prometheus (loopback 9091, 90 days) + Grafana at `grafana.rydback.net` (login required, no anonymous access; sign in with Kanidm via `my.monitoring.sso`, `birger` is Admin through the `grafana_admins` group; local `admin` password and secret key from sops `services/grafana-env`), with blocky's two upstream dashboards and the "Smart plugs" dashboard provisioned. See `modules/monitoring/SPEC.md`
- Smart plugs (`my.shelly-plug`, manages the fleet's three Shelly Plug S Gen3): asserts their names and power-on state on boot and scrapes them for Grafana. This host is itself powered through the `controller` plug (192.168.50.202): `plug-controller` from any tailnet host, and Power on/off in the fleet dashboard. See `modules/shelly-plug/SPEC.md`
- Emulation server: Syncthing for save sync, Samba for read-only ROM/BIOS shares, data at `/var/lib/emulation`; Syncthing/Samba ports exposed only on `enp1s0` (LAN) and `tailscale0` (off-LAN)
- Nextcloud + OnlyOffice as a Google Workspace replacement: file storage / calendar / contacts / mail / notes / tasks / deck (project boards) at `cloud.rydback.net`, collaborative editing backend at `office.rydback.net`. Shared local PostgreSQL (socket auth), per-DB roles. `pkgs.nextcloud33`, pinned major (bump exactly one per upgrade). Login with Kanidm (`my.nextcloud.sso`, client `nextcloud`, user `birger` maps onto the existing account; password form kept). Admin user `betongsuggan`; first-run password and the JWT secret shared with the Nextcloud ONLYOFFICE app live in sops (`services/nextcloud-admin-pass`, `services/onlyoffice-jwt`, `services/onlyoffice-nonce`). OnlyOffice docservice moved off its default port 8000 to 8765 to avoid colliding with `wake-proxy`'s 0.0.0.0:8000 (voice tunnel).
- Restic backup source: pushes encrypted snapshots over SFTP-on-tailnet to `desktop` (on-site; woken over WoL before each run) and `island-stationary` (off-site). island-stationary's WoL relay is `island-pi`, so it is woken through island-pi's `wake` account before each run (needs island-stationary to be WoL-capable on its cabled NIC). Every run ends with a 2 % `restic check`, and `restic-verify-{desktop,island-stationary}` restore `/var/lib/vaultwarden` weekly and fail if the latest snapshot is older than two days. Paths: `/var/lib/{vaultwarden,headscale,emulation,nextcloud}`, `/var/lib/git/{nix-vault,wow-leveling}.git`, and `/var/backups/postgresql` (daily `services.postgresqlBackup` dumps of the Nextcloud + OnlyOffice DBs at 01:15; restic runs at 01:45 to pick up the same-day dump). `keep-daily 7 / keep-weekly 4 / keep-monthly 12` retention. See `modules/restic-backup/SPEC.md`.
- Sleep/suspend/hibernate fully disabled (systemd targets masked + logind ignores lid/power keys and idle)
- Colemak keyboard layout
- Stylix theming with Banana cursor
- Single user: `betongsuggan`

## Notes

- Hardware: Intel NUC (CPU with integrated graphics)
- Kernel: Latest stable Linux kernel
- Boot: systemd-boot
- Timezone: Europe/Stockholm
- Locale: en_GB.UTF-8 with Swedish regional settings
- State version: 25.11

## `nix-vault` enrollment role

Controller is the single source of truth for the `nix-vault.git` bare repository (the `nix-vault` flake input). Access is gated by `my.git-server.authorizedKeys` — a flat SSH pubkey allowlist (see `modules/git-server/SPEC.md`). The allowlist is derived automatically from `lib/default.nix` (`inputs.self.lib.allSshKeys`), plus the operator's YubiKey appended in this host's `system.nix` for bootstrap.

Port 22 is reachable only on `tailscale0` — `nix-vault.git` is cloned over the tailnet. New hosts that are not yet on the tailnet use the `home-network` bootstrap flow (see below) to join first, then proceed with the SSH-based clone.

The operator's YubiKey SSH key (FIDO `ed25519-sk` resident, touch-only) is authorized in **two** places on controller:

- `my.git-server.authorizedKeys` — to clone/push `nix-vault.git` from a fresh installer once it has joined the tailnet, *before* the new host's host SSH key has been added to `lib/default.nix`.
- `users.users.betongsuggan.openssh.authorizedKeys.keys` — to SSH in as `betongsuggan`, edit `nix-vault`, and `nixos-rebuild switch` controller.

One credential, all access. The YubiKey lives in the drawer until the next new-host enrollment.

For everyday admin from any tailnet peer, every admin identity's SSH key is authorized on `betongsuggan` (the fleet SSH mesh, `lib.sshFrom` in `lib/default.nix`). No YubiKey touch required for routine work.

## Onboarding new hosts

The full doctrine — what each mode does, the exact installer-side commands, the post-install `mode = "onboarded"` flip, failure modes and recovery — lives in **`modules/home-network/SPEC.md`**. That is the single source of truth for fleet onboarding.

Quick summary of controller's role in the flow:

- Controller runs the rotated, age-encrypted preauth-blob endpoint at `https://rydback.net/.well-known/tailnet-bootstrap.age`. The blob refreshes every 15 minutes and is decryptable only with the operator's YubiKey.
- New hosts fetch the blob from their installer, decrypt with the YubiKey, and join the tailnet — no preexisting tailnet member required.
- Once on the tailnet, the new host clones `nix-vault.git` from `controller` over SSH (YubiKey-authed), registers its age recipient in `nix-vault/.sops.yaml`, populates its own `secrets/<host>.yaml` (with the host-specific long-lived preauth key generated via `sudo headscale preauthkeys create -u birger --reusable -e 8760h`), and `nixos-install`s.

To later allow a host to clone/pull `nix-vault` itself for unattended `nix flake update`, add that host's `/etc/ssh/ssh_host_ed25519_key.pub` under `hosts.<host>.users.<user>.ssh` in `lib/default.nix`, push, and rebuild controller.
