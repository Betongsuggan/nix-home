# De-cloud — `rydback.net`

A private-life initiative to own my data and the services around it: reduce dependence on any cloud I do not control, not only Google, and make every remaining use (YouTube, payments, an AI assistant) a *conscious* choice rather than a default. Work is private only; work devices and accounts are out of scope.

Started 2026 as "De-Google"; widened to all cloud dependencies on 2026-10-22 and renamed. This file holds the decisions that are locked, a status board of what is live, and the ordered backlog. The work itself and the **inventory of every external service** live in Nextcloud Deck (boards **De-cloud** and **Cloud inventory**, `deck` CLI); history stays in the progress log at the bottom.

---

## 1. Guiding principles

- **Inventory before replacement.** Every external service I depend on has a card on the Cloud inventory board, with what data it holds and which decision applies. A card in *Using* with no decision is the debt.
- **Ownership tiers.** Self-host the crown jewels (passwords, files, calendar, photos, identity). Use a *trusted, transparent* third party where self-hosting buys little ownership for a lot of babysitting (mail, off-site storage, DNS). Keep a few conscious-choice conveniences (YouTube, payments, Claude).
- **Own the address, not the provider.** Identity is `you@rydback.net`. The backend behind it is swappable by DNS.
- **Tailnet-first.** Self-hosted services are reachable only inside the headscale network. Public exposure is the exception (`rydback.net/wow`, the bootstrap blob), never for personal data.
- **One login.** Self-hosted services authenticate through the identity provider, not their own user tables.
- **Dependency order.** Password manager before detaching any login. Mail last, because it is the recovery anchor for everything else.
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
| Identity provider | **Kanidm on controller at `id.rydback.net`, tailnet-only** (2026-10-21, reverses the earlier deferral) | Five self-hosted logins by then (Nextcloud, Vaultwarden, Grafana, Open WebUI, Deck via app password). Kanidm is the one IdP whose people, groups and OIDC clients are declared in Nix from the registry; passkey/YubiKey login; LDAP for anything without OIDC. Live for Nextcloud, Grafana, Open WebUI; Vaultwarden postponed; headscale second wave (`sso` label on the De-cloud board). | If a consumer needs SAML or Kanidm's client support proves too narrow. |
| Project tracker | **Nextcloud Deck + the `deck` CLI** (2026-10-21) | Nothing new to host, one login, phone app, backed up with Nextcloud. Vikunja is the reserve if the kanban-only model chafes. | If priorities, cross-board filters or global labels are missed for real. |
| Scope | **All cloud dependencies, private life only** (2026-10-22, was "Google only") | The Google account was the biggest anchor but not the only one: DNS, code hosting, the vault's backup key, subscriptions and the assistant all live elsewhere. Without an inventory the remaining dependencies stay invisible. | — |

Open forks, decided on their inventory cards when they come up: DNS hosting (Route 53 vs a European provider vs zone-as-code), personal code hosting (GitHub mirror vs controller), where the vault's backup age key lives once 1Password is closed.

---

## 3. Status board (2026-10-22)

Everything below runs on `controller` unless noted. ✅ live and declarative · 🟡 live with a known gap · ❌ not started.

| Area | State | Where |
|---|---|---|
| Passwords — Vaultwarden | 🟡 Live (May 2026). Clients on all devices. No SMTP yet. Encrypted emergency export to USB has no cadence. SSO postponed. | `modules/vaultwarden`, `hosts/controller/system.nix` |
| 2FA — Aegis | ❌ TOTP still on Google Authenticator | phone |
| Account inventory | 🟡 Cloud inventory board seeded from the repo 2026-10-22 (26 cards, `confirm` label on the unverified ones); the per-login inventory in Vaultwarden is not done | Deck, Vaultwarden |
| Tailnet — headscale, MagicDNS, DERP, subnet router, bootstrap blob | ✅ Linux hosts + both Android devices (`ayn-thor`, `fairphone`), always-on | `modules/home-network`, `modules/headscale` |
| Android VPN slot (Tailscale vs /e/OS Advanced Privacy IP hiding) | ❌ Not decided | phone |
| Files / Calendar / Contacts / Notes / Tasks / Deck — Nextcloud 33 + OnlyOffice | 🟡 Live (June 2026) at `cloud.` / `office.rydback.net`. No SMTP. DAVx5 on the phone not confirmed. Signs in with Kanidm. | `modules/nextcloud`, `modules/onlyoffice` |
| Identity provider — Kanidm | 🟡 Live 2026-10-21 at `id.rydback.net` (passkey login). Nextcloud, Grafana (no anonymous access any more) and Open WebUI sign in through it. Vaultwarden postponed, headscale second wave | `modules/sso` |
| Photos — Immich | ❌ | — |
| Mail — `@rydback.net` receiving | ❌ Nothing receives for the domain. `hosts/mail` is a parked scaffold. Identity anchors in the repo (`operator.email`, git email, ACME, the Kanidm person) are still Gmail. | `hosts/mail/SPEC.md`, `lib/default.nix` |
| Backup copy 1 (source) | ✅ restic daily 01:45: `/var/lib/{vaultwarden,headscale,emulation,nextcloud}`, both git bare repos, `/var/backups/{postgresql,kanidm}` | `modules/restic-backup` |
| Backup copy 2 — `desktop`, on-site | ✅ Chrooted SFTP, WoL-woken by controller before each run | `modules/profiles` (gaming-station), `modules/restic-target` |
| Backup copy 3 — `island-stationary`, off-site | 🟡 Target wired (2026-10-01) but controller cannot wake it (its relay is `island-pi`); runs fail while it sleeps. Best effort. | `hosts/island-stationary/SPEC.md` |
| Backup copy 3 — Hetzner Storage Box | ❌ Decided, not built | backlog 1 |
| `restic check` / restore test | ❌ Never run | backlog 1 |
| Disaster-recovery runbook | ✅ `docs/disaster-recovery.md` (2026-10-18), not yet exercised | — |
| Search — SearXNG | 🟡 Exists only as Open WebUI's loopback sidecar on `desktop` | `modules/ai-server` |
| Home-network telemetry — DNS filter + Grafana | 🟡 Live (2026-10-18): blocky on controller for LAN (DHCP) and tailnet, hagezi + vendor lists, encrypted upstreams, per-client query log, dashboards at `grafana.rydback.net` (login required). Router cannot force hardcoded-DNS devices (102.x firmware has no DNS Filtering); watch the log for bypassing devices before deciding on Merlin | `modules/dns-filter`, `modules/monitoring` |
| DNS hosting — Route 53 | 🟡 In use, records by hand, no decision | Cloud inventory |
| Code hosting — GitHub | 🟡 `nix-home` and five personal repos; `nix-vault` and `wow-leveling` already on controller | Cloud inventory, `modules/git-server` |
| Maps, app stores, YouTube frontend | ❌ Not confirmed | phone |
| Payments | ❌ Not started (Swish + bank app cover most of Sweden already) | phone |
| Partner access | ❌ One headscale user (`birger`), allow-all ACL | `hosts/controller/system.nix` |
| Google account removed from microG | ❌ Finish line | phone |

The original plan said "no critical data on controller before the runbook, an off-site copy and a restore test exist". Nextcloud has held real data since June without any of the three. The runbook now exists; the other two are backlog item 1 and nothing else goes on controller before it is done.

---

## 4. Backlog (ordered; blockers inline)

The same list as the De-cloud board's Backlog, numbered in order. Each item is one working session. Repo work is named; operator work (phone, provider dashboards, DNS) is marked *op*. Details and progress live on the cards.

1. **Hetzner Storage Box: always-on off-site backup + restic verify.** *Blocks everything that adds data to controller.* Storage Box BX11 with controller's restic key; `modules/restic-backup` gains `sftpPort` and `hostKey` for a non-fleet target and a monthly `restic check --read-data-subset=5%` plus restore smoke test; the DR runbook's drill is run once and logged.
2. **Mail: `@rydback.net` receives, Gmail becomes a forwarder.** Provider signup and DNS records; SMTP for Vaultwarden and Nextcloud through their existing secret files; `operator.email`, git email and the Kanidm person's mail move to the domain; then the long tail of email-of-record changes, one alias per service, listed in Vaultwarden.
3. **Phone hygiene (no repo work).** Aegis; Organic Maps; Aurora + F-Droid only; NewPipe or Grayjay; the VPN slot decision; DAVx5 against `cloud.rydback.net`; Catima; a quarterly encrypted Vaultwarden export.
4. **Photos: Immich.** *Blocked by 1.* `modules/immich` on the Nextcloud module's pattern, restic and pg-dump wiring, phone upload over the tailnet, one-time Takeout import.
5. **Partner access.** Second headscale user, her phone, her Nextcloud (and Kanidm) account, shared calendar.
6. **Search on controller.** `services.searx` at `search.rydback.net`, default engine in the browsers.
7. **Finish line.** Nothing private depends on the Google account; remove it from microG; full check of services, mail, backups.

Also on the board, unordered: the account inventory in Vaultwarden, Vaultwarden SSO (postponed), headscale OIDC login (second wave), and whatever the inventory cards turn into once decided.

Parked, not deleted: `hosts/mail` (self-host trial; reactivation criteria in its SPEC), Authelia/Authentik (Kanidm chosen).

---

## 5. Inventory

The replacement map that used to live here is now the **Cloud inventory** board: one card per external service, stacks *Using* (no decision yet), *Replacing* (decided, in progress), *Replaced* (done, Google copy to delete), *Keep* (conscious choice), labels `data` (holds personal data), `fleet` (this repo depends on it), `account` (just a login), `confirm` (seeded from the repo, not verified by me yet). Read it with `deck board "Cloud inventory"`.

Rules: a new external dependency gets a card the day it appears; a card leaves *Using* only with a decision written on it; a *Replaced* card is closed only after the cloud copy is deleted and the account, where possible, too.

---

## 6. Progress log

### 2026-10-22 — De-Google becomes De-cloud

- Scope widened from the Google account to every cloud dependency; this file renamed from `de-googling.md`. The replacement map became the Cloud inventory board (26 cards seeded from the repo: Google services, Route 53, GitHub, 1Password, Hetzner, Migadu, Let's Encrypt, Anthropic, Apple, Steam, Discord, Signal, Swish/BankID, subscriptions; the ones not verifiable from the repo carry `confirm`).
- Boards consolidated: the SSO work board merged into De-cloud (`sso` label), history kept as comments. Backlog item 1 renamed to name the Storage Box.

### 2026-10-21 — project tracker and the identity provider decision

- Nextcloud Deck is the project tracker (`modules/deck` CLI, boards Projects / De-cloud / AI lab / nix-home / Cloud inventory). This file stays the written source of truth for decisions; the boards hold the work.
- Identity provider un-deferred: Kanidm on controller, `modules/sso` written with persons from the registry and OIDC clients for Nextcloud, Grafana, Open WebUI and Vaultwarden. Rationale in §2.
- Later the same day: Kanidm deployed (first attempt failed on a missing public A record and on overwriting `idm_admins`; both fixed), passkey enrolled, and Nextcloud (`user_oidc`), Grafana (`generic_oauth`, anonymous access removed) and Open WebUI (OIDC with PKCE) switched to it, each keeping its local admin as break-glass. Vaultwarden SSO postponed by choice.

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
