# De-Google — `rydback.net`

A private-life initiative to regain control over where data lives, reduce dependence on US Big Tech, and make any remaining use (e.g. YouTube) a *conscious* choice rather than a default. Work is private only; work devices and accounts stay on Google and are out of scope.

Re-baselined 2026-10-18 against what the repo actually runs. The earlier phase/checkbox layout is gone; this file now holds the decisions that are locked, a status board of what is live, and an ordered backlog. History stays in the progress log at the bottom.

---

## 1. Guiding principles

- **Ownership tiers.** Self-host the crown jewels (passwords, files, calendar, photos). Use a *trusted, transparent* third party where self-hosting buys little ownership for a lot of babysitting (mail, off-site storage). Keep a few conscious-choice conveniences (YouTube, payments).
- **Own the address, not the provider.** Identity is `you@rydback.net`. The backend behind it is swappable by DNS.
- **Tailnet-first.** Self-hosted services are reachable only inside the headscale network. Public exposure is the exception (`rydback.net/wow`, the bootstrap blob), never for personal data.
- **Dependency order.** Password manager before detaching any Google login. Mail last, because it is the recovery anchor for everything else.
- **NixOS everywhere.** Every service is a module under `modules/`, enabled on `controller`, in the restic set, documented in a SPEC.
- **A backup that was never restored is hope, not a backup.** Verification is automated, the runbook is exercised.

---

## 2. Decisions (locked)

Record the *why* here so future-you does not re-litigate.

| Fork | Decision | Why | Revisit when |
|---|---|---|---|
| Mail backend | **Hybrid: hosted provider now (Migadu or mailbox.org) with `rydback.net`; `hosts/mail` self-host parked** | Self-hosting mail buys little ownership (the VPS is rented anyway) at a permanent deliverability + ops cost, and the paused Hetzner trial blocked the identity migration for five months. A provider gives standard IMAP/SMTP, aliases/catch-all, and an SMTP relay for Vaultwarden/Nextcloud on day one. Proton rejected (no plain IMAP). | After Immich and backups are done, if provider policy or price becomes a problem. Switch is MX + IMAP import. |
| Aliasing | **Provider aliases / catch-all on `rydback.net`; no addy.io / SimpleLogin** | Own domain + provider aliases give per-service addresses with no third party. | Never, unless the provider drops aliases. |
| Access model | **Tailnet-only for every personal service** | Tiny attack surface; proven on Linux and both Android devices. | Never for personal data. |
| Partner access | **Second headscale user + her phone on the tailnet + a Nextcloud account** | Enrolling one phone is less risk than exposing `cloud.rydback.net` publicly; the shared calendar lives in Nextcloud either way. | If a non-tailnet person ever needs a share: Nextcloud share links on a public, auth-only endpoint, decided then. |
| Off-site backup | **Hetzner Storage Box (SFTP, restic client-side encrypted)**; `island-stationary` stays as a bonus copy | Always online, EU, ~€4/mo for 1 TB. The summer-house PC is a gaming machine that is off most of the time and controller cannot wake it. | If Hetzner becomes unacceptable: any SFTP/S3 target, same module. |
| Local redundancy | **No NAS.** 3-2-1 is met across copies (controller, desktop, Storage Box, island) rather than by a mirror at one site. | Hardware that would sit idle to protect one copy of data that already has three. | If controller's data outgrows 1 TB. |
| Headscale location | **Stays on controller** | If controller is down, Vaultwarden/Nextcloud are down anyway; a separate control plane does not help. No VPS exists to host it. | Only if a VPS exists for another reason. |
| Photos | **Immich on controller** (`services.immich`) | Best Google Photos replacement (timeline, ML search, faces, auto-upload app). Library < 200 GB fits the 1 TB NVMe. | If the library outgrows the disk. |
| Search | **Native `services.searx` on controller**, tailnet-only | The existing SearXNG is a loopback sidecar for Open WebUI on `desktop`, which sleeps. A user-facing instance belongs on the always-on host. | — |
| Identity provider | **Kanidm on controller at `id.rydback.net`, tailnet-only** (2026-10-21, reverses the earlier deferral) | Five self-hosted logins by now (Nextcloud, Vaultwarden, Grafana, Open WebUI, Deck via app password). Kanidm is the one IdP whose people, groups and OIDC clients are declared in Nix from the registry; passkey/YubiKey login; LDAP for anything without OIDC. First wave: Nextcloud, Grafana, Open WebUI, Vaultwarden; headscale later. Tracked on the Deck **SSO** board. | If a consumer needs SAML or Kanidm's client support proves too narrow. |

---

## 3. Status board (2026-10-18)

Everything below runs on `controller` unless noted. ✅ live and declarative · 🟡 live with a known gap · ❌ not started.

| Area | State | Where |
|---|---|---|
| Passwords — Vaultwarden | 🟡 Live (May 2026). Clients on all devices. No SMTP yet. Encrypted emergency export to USB has no cadence. | `modules/vaultwarden`, `hosts/controller/system.nix` |
| 2FA — Aegis | ❌ TOTP still on Google Authenticator | phone |
| Account inventory | ❌ Not done | Vaultwarden |
| Tailnet — headscale, MagicDNS, DERP, subnet router, bootstrap blob | ✅ Linux hosts + both Android devices (`ayn-thor`, `fairphone`), always-on | `modules/home-network`, `modules/headscale` |
| Android VPN slot (Tailscale vs /e/OS Advanced Privacy IP hiding) | ❌ Not decided | phone |
| Files / Calendar / Contacts / Notes / Tasks — Nextcloud 33 + OnlyOffice | 🟡 Live (June 2026) at `cloud.` / `office.rydback.net`. No SMTP. DAVx5 on the phone not confirmed. | `modules/nextcloud`, `modules/onlyoffice` |
| Photos — Immich | ❌ | — |
| Mail — `@rydback.net` receiving | ❌ Nothing receives for the domain. `hosts/mail` is a parked scaffold. Identity anchors in the repo (`operator.email`, git email, ACME) are still Gmail. | `hosts/mail/SPEC.md`, `lib/default.nix` |
| Backup copy 1 (source) | ✅ restic daily 01:45: `/var/lib/{vaultwarden,headscale,emulation,nextcloud}`, both git bare repos, `/var/backups/postgresql` (pg dumps 01:15) | `modules/restic-backup` |
| Backup copy 2 — `desktop`, on-site | ✅ Chrooted SFTP, WoL-woken by controller before each run | `modules/profiles` (gaming-station), `modules/restic-target` |
| Backup copy 3 — `island-stationary`, off-site | 🟡 Target wired (2026-10-01) but controller cannot wake it (its relay is `island-pi`); runs fail while it sleeps. Best effort. | `hosts/island-stationary/SPEC.md` |
| Backup copy 3 — Hetzner Storage Box | ❌ Decided, not built | backlog 1 |
| `restic check` / restore test | ❌ Never run | backlog 1 |
| Disaster-recovery runbook | ✅ `docs/disaster-recovery.md` (2026-10-18), not yet exercised | — |
| Search — SearXNG | 🟡 Exists only as Open WebUI's loopback sidecar on `desktop` | `modules/ai-server` |
| Home-network telemetry — DNS filter + Grafana | 🟡 Live (2026-10-18): blocky on controller for LAN (DHCP) and tailnet, hagezi + vendor lists, encrypted upstreams, per-client query log, dashboards at `grafana.rydback.net`. Router cannot force hardcoded-DNS devices (102.x firmware has no DNS Filtering); watch the log for bypassing devices before deciding on Merlin | `modules/dns-filter`, `modules/monitoring` |
| Maps, app stores, YouTube frontend | ❌ Not confirmed | phone |
| Payments | ❌ Not started (Swish + bank app cover most of Sweden already) | phone |
| Partner access | ❌ One headscale user (`birger`), allow-all ACL | `hosts/controller/system.nix` |
| Google account removed from microG | ❌ Finish line | phone |
| Identity provider — Kanidm | 🟡 Module written 2026-10-21 (`modules/sso`), not yet deployed; services still use their own logins | `modules/sso`, Deck board SSO |

The original plan said "no critical data on controller before the runbook, an off-site copy and a restore test exist". Nextcloud has held real data since June without any of the three. The runbook now exists; the other two are backlog item 1 and nothing else goes on controller before it is done.

---

## 4. Backlog (ordered; blockers inline)

Each item is one working session. Repo work is named; operator work (phone, provider dashboards, DNS) is marked *op*.

1. **Off-site backup that is always there.** *Blocks everything that adds data to controller.*
   - *op* Hetzner account → Storage Box (BX11, 1 TB) → enable SSH, upload controller's restic public key (`hosts.controller.users.restic.ssh.id_ed25519` in `lib/default.nix`) to the box's `.ssh/authorized_keys` in RFC4716 format.
   - `modules/restic-backup`: add `targets.<name>.sftpPort` (Storage Box speaks SFTP on 23) feeding both the repository URL and the wake probe; pin the box's published host key through `hostKey` (a non-fleet target otherwise falls back to trust-on-first-use). Add a `verify` timer: monthly `restic check --read-data-subset=5%` per target plus a `restore latest --path /var/lib/vaultwarden` smoke into a tmp dir. Update the SPEC.
   - `hosts/controller/system.nix`: add the target. Confirm with `restic-hetzner snapshots`.
   - Run the runbook's **drill** once (see `docs/disaster-recovery.md`) and log the result there.

2. **Mail: `@rydback.net` receives, Gmail becomes a forwarder.**
   - *op* Sign up (Migadu assumed), verify the domain, add MX/SPF/DKIM/DMARC (`p=none` to start) in Route 53. Forward Gmail → `rydback.net`. Send/receive test against Gmail, Outlook, one other.
   - `modules/vaultwarden`: SMTP via the existing `environmentFile` (`SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURITY`, `SMTP_FROM`, `SMTP_USERNAME`, `SMTP_PASSWORD`), so no new secret plumbing. `modules/nextcloud`: `services.nextcloud.settings.mail_*` + `secrets.mail_smtppassword` (see that SPEC's mail note). Nextcloud Mail app pointed at the provider's IMAP.
   - `lib/default.nix`: `operator.email` and `accounts.betongsuggan.git.email` → `@rydback.net` (ACME follows). `hosts/mail/system.nix` comment likewise when it is next touched.
   - *op* Start the long tail: change email-of-record per account, most valuable first, per-service alias each time. Keep a list in Vaultwarden. Gmail stays as a dormant forward-only fallback until nothing depends on it.

3. **Phone hygiene (no repo work).** Aegis with encrypted backups; Organic Maps; Aurora Store + F-Droid as the only sources; NewPipe or Grayjay for YouTube; decide the VPN slot (recommendation: Tailscale always-on, Advanced Privacy IP hiding off, tracker blocking kept); DAVx5 against `cloud.rydback.net`; Catima for passes. Encrypted Vaultwarden export to a USB stick, then a calendar reminder every quarter.

4. **Photos: Immich.** *Blocked by 1.*
   - New `modules/immich/{nixos.nix,SPEC.md}` on the Nextcloud module's pattern: `services.immich`, local PostgreSQL, `/var/lib/immich`, tailnet-only vhost through `lib.tailnet.nginxAllowOnly`, `photos.rydback.net` in `extraDnsRecords`. Add the data dir and DB to the restic set and `postgresqlBackup.databases`. ML stays on controller (CPU; fine for a personal library, can be switched off).
   - *op* Immich app on the phone with background upload over the tailnet. One-time Google Takeout import. Keep Google Photos read-only until the import is verified, then stop uploading there.

5. **Partner access.** One line: a second user in `controller.headscale.users`; *op* enroll her phone with the Tailscale app (`https://vpn.rydback.net`), create her Nextcloud user, share the calendar. Document in `hosts/controller/SPEC.md`.

6. **Search on controller.** `my.searx` (or a plain `services.searx` block) at `search.rydback.net`, tailnet-only, settings from `modules/ai-server/searxng/settings.yml` as the starting point. Set it as the default engine in Firefox/Chromium through the existing modules.

7. **Finish line.** Confirm nothing private depends on the Google account (inventory from Vaultwarden, mail moved, photos moved, 2FA off Authenticator). Remove the account from microG. Reboot, check services over the tailnet, check mail both ways, check the last restic run and the last verify run.

Parked, not deleted: `hosts/mail` (self-host trial; reactivation criteria in its SPEC), Kanidm/Authentik (see Decisions).

---

## 5. Replacement map

| Google service | Self-host (tier 1) | Trusted third party (tier 2) | State |
|---|---|---|---|
| Passwords | Vaultwarden | — | live |
| 2FA | Aegis (local) | — | todo |
| Email | *(parked: Stalwart on a VPS)* | Migadu / mailbox.org with `rydback.net` | todo |
| Drive / Docs | Nextcloud + OnlyOffice | — | live |
| Calendar / Contacts | Nextcloud (+ DAVx5) | — | live, phone unconfirmed |
| Notes / Tasks | Nextcloud Notes / Tasks | — | live |
| Photos | Immich | — | todo |
| Maps | — | Organic Maps / OsmAnd (offline) | todo |
| Search | SearXNG | — | sidecar only |
| YouTube | — | NewPipe / Grayjay (no login) | todo |
| Payments | — | Swish / bank app / Curve / Garmin Pay | todo |
| App store | — | Aurora Store + F-Droid | todo |
| Networking | Headscale | — | live |
| Off-site storage | — | Hetzner Storage Box (ciphertext only) | todo |

---

## 6. Progress log

### 2026-10-21 — project tracker and the identity provider decision

- Nextcloud Deck is the project tracker (`modules/deck` CLI, boards Projects / De-Google / AI lab / nix-home / SSO). This file stays the written source of truth for decisions; the boards hold the work.
- Identity provider un-deferred: Kanidm on controller, `modules/sso` written with persons from the registry and OIDC clients for Nextcloud, Grafana, Open WebUI and Vaultwarden. Not deployed yet (vault secrets pending). Rationale in §2.

### 2026-10-18 (later) — the house resolves through controller

- `modules/dns-filter` (blocky) and `modules/monitoring` (Prometheus + Grafana) live on controller. The router's DHCP hands out controller as DNS; headscale pushes it to every tailnet member, verified on `bits` (LG telemetry names answer `0.0.0.0` over the tailnet path). Upstreams are Quad9 and Mullvad over DNS-over-TLS.
- Found and fixed on the way: PostgreSQL's setup unit had been failing since the 26.05 upgrade (glibc collation version 2.40 → 2.42), so no new database could be created; refreshed by hand and reindexed Nextcloud/OnlyOffice. A declarative `postgresql-collation-refresh` unit is a candidate for the next release upgrade.
- Open: devices with hardcoded resolvers cannot be redirected on the ASUS 3.0.0.6.102 firmware. Read the query log after a day; flash Asuswrt-Merlin (DNS Director) only if a device is provably bypassing.

### 2026-10-18 — re-baseline

- Re-read the plan against the repo. Since the last entry: Nextcloud 33 + OnlyOffice live on controller (June), tailnet subnet routing, Taildrop, git-server with two repos, static site at `rydback.net/wow`, Nextcloud data + Postgres dumps added to the restic set, island-stationary restored as an off-site restic target (2026-10-01).
- Called out what never happened: the DR runbook, any restore test, a reliably reachable off-site copy. Nextcloud has held real data for four months behind a gate that was never closed. Wrote `docs/disaster-recovery.md` today; the off-site copy and verification are now backlog item 1 and gate everything else.
- Locked the mail fork as **hybrid**: hosted provider on `rydback.net` now, self-host parked. The Hetzner trial had been paused since 2026-05-30 on identity verification and had blocked the entire identity migration, which never depended on the backend in the first place. Dropped addy.io/SimpleLogin (provider aliases cover it).
- Dropped the NAS and the headscale-on-VPS items; added the Storage Box, Immich-on-controller, SearXNG-on-controller and the partner-access design. Restructured this file into decisions / status / backlog.

### 2026-05-31 (even later) — tailnet-only emulation stack + Android proven end-to-end

- Migrated 36 GB of emulation data (ROMs/BIOS/saves) from `desktop` to controller's `/var/lib/emulation`. Controller is now the canonical source.
- Made the emulation stack fully tailnet-only: Samba shares exposed only on `tailscale0` + `hosts allow = 100.64.0.0/10`; Syncthing with all discovery/relays off, peers pinned to `<peer>.ts.rydback.net:22000`.
- Declarative client wiring on desktop; Android Syncthing proven end-to-end on `ayn-thor` and `fairphone` over MagicDNS. This is what proved the Android client, always-on battery posture, and MagicDNS items.
- Lib schema refactored: per-user identity bits (SSH + Syncthing) live under `hosts.<h>.users.<u>.{ssh,syncthing}.*`.

### 2026-05-31 (later) — first restic snapshot landed on desktop

- Controller's daily restic timer is active, first push to `desktop.ts.rydback.net` ran cleanly, snapshot contains all expected paths. Receiver side (chrooted SFTP user `restic-controller`) works as designed.
- Copy 2 stayed unticked for "redundant media" (single-disk desktop); copy 3 unticked (island not yet on the tailnet). Next: DR runbook, onboard island-stationary.

### 2026-05-31 — Vaultwarden live; pivoting to backup workstream

- Vaultwarden deployed declaratively on `controller` (`modules/vaultwarden/`), tailnet-only at the nginx vhost, sops-encrypted `ADMIN_TOKEN`, data at `/var/lib/vaultwarden`.
- Interim backup topology chosen to avoid stalling on hardware: restic from controller → desktop (on-site) and island-stationary (off-site) over SFTP-on-tailnet, chrooted SFTP user per source.

### 2026-05-30 — mail trial scaffolded, paused awaiting passport verification

- Mail host (self-host option) scaffolded under `hosts/mail/`: NixOS config, disko layout, terranix-driven Hetzner resources. Flake evaluates; nothing deployed.
- Decisions at the time: Hetzner Cloud CX22 Falkenstein, terranix co-located with the host, Route 53 records manual through the trial, encrypted state via sops-nix once provisioned.
- Paused on Hetzner identity verification. Pivoted to Vaultwarden.
