# De‑Google Migration Plan — `rydback.net`

A private‑life initiative to regain control over where data lives, reduce dependence on US Big Tech, and make any remaining use (e.g. YouTube) a *conscious* choice rather than a default. Work is private only — work devices/accounts stay on Google and are out of scope.

> Track this in git. Tick boxes as you go. Each phase lists its **blockers** so you don't start something that depends on an earlier piece. Suggested cadence: one workstream at a time, no deadline pressure.

---

## 0. Guiding principles

- **Ownership tiers.** Self‑host the crown jewels (passwords, 2FA, eventually mail, files, photos, calendar). Use a *trusted, transparent* third party for less‑critical things, knowing where/how data is stored. Keep a few conscious‑choice conveniences (YouTube, payments).
- **Own your address, not your provider.** Identity = `you@rydback.net`. The backend behind it is swappable. This is the key that makes "try self‑hosting, fall back to Proton" painless.
- **Tailnet‑first.** Self‑hosted services are reachable only inside the Headscale network by default. Public exposure is the exception, used only where unavoidable (inbound mail, sharing with non‑tailnet people).
- **Dependency order.** Password manager and account inventory come *before* detaching any Google SSO. Email comes *last* because it's the recovery anchor for everything else.
- **NixOS everywhere is an asset.** Most of this is declarative: `services.vaultwarden`, `services.nextcloud`, `services.immich`, `services.radicale`, `services.headscale`, `services.kanidm`, `services.restic`, `services.searx`. Keep the whole stack in your flake.

---

## Architecture decisions to lock early

These three forks determine everything downstream. Decide them before building.

- [ ] **Email backend path** — choose A, B, or "decide later behind aliasing":
  - **A. Self‑host on a clean‑IP VPS** (e.g. Hetzner ~€4/mo, port 25 open, rDNS set). Run Stalwart (modern all‑in‑one, mature enough for personal use in 2026) or a bundle like Mailcow/Mailu. You control software + data; the box is rented. Best balance of ownership and deliverability.
  - **B. Privacy provider with your domain** — Proton Mail (Swiss), Tuta or Mailbox.org (German). Point `rydback.net` at them; import via their IMAP/Easy‑Switch tooling. Least effort, EU/Swiss jurisdiction, you still own the address.
  - **Recommended start:** put aliasing in front of your domain *now* (path below), run a VPS Stalwart instance as a trial in parallel with Gmail, and keep Proton as the documented fallback. Switching = DNS only.
- [ ] **Access model** — confirm tailnet‑only for personal services. Note the two friction points (Android VPN slot; sharing with your wife) addressed in the Headscale section.
- [ ] **Backup topology** — 3‑2‑1 using the NUC + summer‑house PC over Headscale as off‑site, plus dedicated hardware (see Backup workstream). **Get this running before putting critical data on the server.**

---

## Phase 0 — Foundations (do first; everything depends on these)

**Blockers:** none.

- [ ] **Stand up backups first** (see Backup workstream). Don't host anything critical on a box with no restore path — you've already lost disks once.
- [x] **Deploy a password manager: Vaultwarden** (Bitwarden‑compatible, `services.vaultwarden` on NixOS, behind Headscale).
  - [x] Bitwarden clients cache an encrypted local copy and work offline, so tailnet‑only is fine day‑to‑day — you only need the server to *sync*. This removes the usual "what if home is down" worry.
  - [ ] Keep an **encrypted emergency export** somewhere offline (e.g. on a USB key in a drawer) as break‑glass recovery.
  - [ ] Install clients on all devices; on /e/OS get the Bitwarden app from F‑Droid/Aurora.
- [ ] **Inventory every account** and flag which use "Sign in with Google."
  - [ ] Google account → Security → "Sign in with Google" / connected accounts gives you the list to work from.
  - [ ] Record each in the password manager as you go.
- [ ] **Move 2FA off Google Authenticator → Aegis** (open source, encrypted, F‑Droid). Re‑enroll TOTP secrets per site; keep encrypted Aegis backups.

---

## Phase 1 — Identity & access plumbing

**Blockers:** Phase 0 password manager.

- [ ] **Decide on a self‑hosted IdP — optional, lower priority.** Reality check: you *cannot* point third‑party consumer sites (Spotify, forums, etc.) at your own IdP — those only accept fixed providers. So de‑Googling consumer SSO = converting each site to email + unique password in Vaultwarden. An IdP only unifies login for services *you* host and apps that speak generic OIDC.
  - [ ] If you want one: **Kanidm** (Rust, has a clean `services.kanidm` NixOS module, lightweight) or **Authentik** (heavier, more features, usually run via container). Kanidm fits your NixOS‑native preference better.
  - [ ] Defer this until you actually have a few self‑hosted services worth unifying.
- [ ] **Harden and finalize Headscale** (see Headscale analysis below). Enroll every personal device.

### Headscale‑only access — analysis

Pros: services never exposed publicly, tiny attack surface, MagicDNS gives you nice hostnames. Watch these:

- [ ] **Android client works, but mind the details.** Use the official Tailscale app from **F‑Droid** (no Play Store needed on /e/OS); in settings set your custom server URL (`https://headscale.rydback.net`). The login‑to‑custom‑server UX has been rough historically and was improved in recent releases — if a login window misbehaves, close it and use the main‑screen Log in, per Headscale's Android docs.
- [ ] **VPN‑slot conflict (important).** Android allows only **one** active VPN. Tailscale uses it; /e/OS **Advanced Privacy "hide my IP"** also uses it. You can't run both at once. Decide: keep Tailscale always‑on for service access and leave Advanced Privacy's IP‑hiding off (tracker blocking via other means), or toggle. Test this early on the phone — it's the most likely day‑to‑day annoyance.
- [ ] **Battery / always‑on.** WireGuard is efficient; always‑on Tailscale is fine, but set it deliberately.
- [ ] **Single point of coordination.** If the box running Headscale is down, *new* connections can't be coordinated (existing peer links may persist). Consider running **Headscale itself on the cheap mail VPS** — it's tiny (~60 MB RAM), gets you a reliable public control plane and clean reachability, and keeps coordination up when home is offline.
- [ ] **MagicDNS** so you reach services by name on all platforms; enable subnet routes for any LAN‑only boxes you want reachable.
- [ ] **Sharing with your wife (and future shared things).** A tailnet‑only service means she must be enrolled on the tailnet to reach it — friction for a non‑technical partner. For the shared calendar specifically, either enroll her device in the tailnet, or expose *just* that one service via an authenticated public endpoint on the VPS. Flagged again in the calendar step.

---

## Phase 2 — Own your email address (then swap the backend)

**Blockers:** Phase 0 (password manager + 2FA moved, since email currently anchors recovery). Do the address move early, the Gmail decommission *last*.

- [ ] **Set up aliasing in front of `rydback.net`** — addy.io or SimpleLogin (both self‑hostable later; start with hosted to move fast). Gives you per‑service aliases and means you never hand out a "real" address again.
- [ ] **Start migrating your identity to `rydback.net`** — change the email on accounts to your domain alias, highest‑value/most‑used first. This is the slow, ongoing part; spread it out.
- [ ] **Stand up the chosen backend:**
  - [ ] *Path A:* clean‑IP VPS, port 25 confirmed open, rDNS = `mail.rydback.net`. Deploy Stalwart (or Mailcow/Mailu). Nail DNS: A/AAAA, MX, **PTR**, SPF, DKIM (2048‑bit), DMARC (start `p=none`), MTA‑STS, TLS‑RPT. Warm slowly; watch Gmail Postmaster Tools.
  - [ ] *Path B:* point `rydback.net` MX/SPF/DKIM/DMARC at Proton/Tuta/Mailbox; use their import tool.
- [ ] **Run in parallel with Gmail.** Forward Gmail → `rydback.net`. Define a **cutover criterion** (e.g. "two weeks of clean delivery to Gmail/Outlook/Fastmail recipients, no spam‑foldering").
- [ ] **Decommission Gmail — last of all.** Only once nothing depends on it for password resets and `rydback.net` is proven. Keep Gmail as a dormant forward‑only fallback for a while before full removal.

---

## Phase 3 — Personal data services (self‑host the crown jewels)

**Blockers:** backups live (Phase 0), Headscale enrolled (Phase 1).

- [ ] **Drive → Nextcloud** (`services.nextcloud`) or Seafile if you want pure file‑sync performance. Nextcloud also covers calendar/contacts/notes in one, simplifying the stack.
- [ ] **Photos → Immich** (`services.immich`). Strong Google Photos replacement: timeline, ML search, faces, mobile auto‑backup app (F‑Droid). Point its uploads at the NUC; make sure photos are in your backup set.
- [ ] **Calendar & Contacts → CalDAV/CardDAV** via Nextcloud or a lightweight Radicale/Baïkal.
  - [ ] On /e/OS, sync with **DAVx5** (F‑Droid).
  - [ ] **Shared calendar with your wife:** simplest is a shared CalDAV calendar she subscribes to. If she's not on the tailnet, expose only the CalDAV endpoint publicly on the VPS behind auth, or enroll her phone in Headscale. Decide per the Headscale sharing note.
- [ ] **Notes (if used)** → Joplin (self‑syncable) or Nextcloud Notes.

---

## Phase 4 — Ancillary services (third‑party OK where transparent)

**Blockers:** none hard; do alongside Phase 3.

- [ ] **Maps → Organic Maps or OsmAnd** (offline OSM, no account, F‑Droid). Zero dependency, good first win.
- [ ] **Search → SearXNG** (`services.searx`/searxng), self‑hosted metasearch behind the tailnet; or use a reputable public instance.
- [ ] **YouTube → conscious choice.** Options, in order of "least Google":
  - [ ] *No login:* NewPipe / FreeTube / Grayjay (F‑Droid). No account, no Google services; subscriptions kept locally. Best privacy, loses real‑account sync.
  - [ ] *Your account, isolated:* on a standard ROM you'd use ReVanced + isolated microG. On /e/OS you already have system microG, so a logged‑in YouTube there *is* phone‑wide by nature — which cuts against your goal. Prefer a no‑login frontend on the phone and save real‑account YouTube for the desktop if you want it.
- [ ] **App sources on /e/OS:** Aurora Store (anonymous Play access) + F‑Droid, so you avoid a Google account for app installs entirely.

---

## Phase 5 — Payments (Google Wallet replacement)

**Blockers:** none. Region: Sweden/EU.

Reality: tap‑to‑pay via Google Wallet does **not** work on /e/OS (Google attestation). Routes that do work:

- [ ] **Curve** — European (EEA+UK) fintech; links your Visa/Mastercard and pays via the phone without Google Pay. Confirmed to work on /e/OS (and /e/OS Advanced Privacy can block its trackers). Pragmatic primary option.
- [ ] **Garmin Pay on a supported Garmin watch** — phone‑independent, works offline, widely the most reliable de‑Googled tap‑to‑pay. Depends on your bank supporting it.
- [ ] **Your bank's own NFC, if any** — region/bank‑dependent; check your Swedish bank's app.
- [ ] **Swish (Sweden)** — app + BankID, ubiquitous for P2P and many merchants; no Google dependency. Covers a large share of real‑world Swedish payments even without card tap‑to‑pay.
- [ ] **Loyalty cards / passes** → Catima (F‑Droid) replaces the Wallet "passes" function.

---

## Phase 6 — Finish line

**Blockers:** all of the above proven.

- [ ] Confirm nothing private depends on the Google account (SSO migrated, mail moved, data moved, 2FA off Authenticator).
- [ ] **Remove the Google account from the phone's microG** (microG Settings → Accounts). This is the milestone.
- [ ] Decide microG posture: keep it for non‑Google push/maps shims, or trim further. (System microG remaining is fine — your account is what you wanted gone.)
- [ ] Final verification: reboot, confirm services reachable over tailnet, confirm mail send/receive, confirm backups ran and a test restore works.

---

## Backup workstream (cross‑cutting — set up in Phase 0, maintain forever)

Your current state: ASUS NUC 14 Essential, 1 TB NVMe (main host); two gaming PCs at two locations (one same residence, one summer house); previous backup box's disks failed. The summer‑house PC over Headscale is a natural **off‑site** copy.

Target: **3‑2‑1** — 3 copies, 2 media types, 1 off‑site.

- [ ] **Engine:** restic or Borg (`services.restic` on NixOS), encrypted, deduplicated, scheduled. Restic plays nicely with multiple destinations.
- [ ] **Copy 1 (primary):** the NUC's working data.
- [ ] **Copy 2 (local, redundant media):** a dedicated box at home with **redundancy** — a small 2‑bay NAS with mirrored disks, or DIY with **ZFS mirror**. Remember: RAID/ZFS is *not* a backup, it's availability; you still need the off‑site copy. (Your last failure is exactly why mirroring matters.)
- [ ] **Copy 3 (off‑site):** restic/Borg repo on the **summer‑house PC** over Headscale. Truly owned, no third party.
- [ ] **Optional cloud off‑site (encrypted):** Hetzner Storage Box or Backblaze B2 if you want a second off‑site without relying on the summer house being powered/online. Client‑side encrypted, so the provider sees ciphertext only.
- [ ] **Dedicated hardware suggestions (resilience):**
  - Small low‑power NAS (2‑bay, mirrored) as the always‑on local redundant target.
  - Or DIY mini‑PC/NAS running NixOS + ZFS mirror — fits your stack, declarative, scrub on schedule.
  - Use **CMR (not SMR)** NAS‑rated drives; buy two from different batches to avoid simultaneous failure.
- [ ] **Test restores quarterly.** An untested backup is a hope, not a backup.

---

## Tracking

- Treat each `[ ]` as a unit of work; commit progress so you have history.
- Keep an `decisions.md` next to this for the forks you lock (email path, IdP choice, exposure rules) so future‑you remembers *why*.
- Re‑evaluate the email backend after a month: if VPS Stalwart is more babysitting than it's worth, switch DNS to Proton — your `@rydback.net` address doesn't change.

## Progress log

### 2026-05-31 — Vaultwarden live; pivoting to backup workstream

- Vaultwarden deployed declaratively on `controller` (`modules/vaultwarden/`). Tailnet-only at the nginx vhost layer (allow `100.64.0.0/10` + `fd7a:115c:a1e0::/48`, deny all), sops-encrypted `ADMIN_TOKEN`, data at `/var/lib/vaultwarden`. Phase 0 password-manager checklist closed at the infra level.
- Two sub-bullets remain *intentionally* unticked as operator habits, not infra work: encrypted emergency export to USB (manual weekly cadence — see `modules/vaultwarden/SPEC.md`), and "clients on all devices" (per-device install, out of repo scope).
- Pivoting next to the **backup workstream**, since the de-Google plan blocks Nextcloud/Immich/etc. on having a working restore path. Interim topology, picked deliberately to avoid stalling on hardware procurement: `restic` pushing from `controller` → `private-desktop` (on-site copy) and `island-stationary` (off-site, summer house) over SFTP-on-tailnet. Receiving side is a chrooted SFTP user per source. Initial path set: `/var/lib/vaultwarden`, `/var/lib/headscale`, `/var/lib/git/nix-vault.git`, `/var/lib/emulation`.
- This does not yet satisfy the 3-2-1 "redundant media" requirement (no mirror at either end). Deferred until dedicated NAS hardware lands; tracked in the Backup workstream section.

### 2026-05-30 — mail trial scaffolded, paused awaiting passport verification

- Mail host (Option A) scaffolded under `hosts/mail/`: NixOS config (`system.nix`), disko layout (`hardware.nix`), and terranix-driven Hetzner resources (`terraform.nix`). Flake evaluates; nothing deployed.
- Decisions locked (record in `decisions.md` when that file lands): Hetzner Cloud as VPS provider (~€4/mo CX22, Falkenstein), terranix co-located with the NixOS host rather than a separate `infra/` tree, Route 53 records remain manual through the trial (IaC for DNS deferred until Option A is proven), encrypted state via sops-nix once provisioned.
- **Paused:** Hetzner account creation requires a passport for identity verification, which isn't on hand. Resume when passport is available — port-25 unblock request and first `tofu apply` are next.
- Pivoting to **Phase 0 → Vaultwarden** in the interim — independent of the mail track and unblocks the rest of the de-Google work since identity migration depends on the password manager being in place first.

### Quick reference — replacement map

| Google service | Self‑host (tier 1) | Trusted 3rd‑party (tier 2) |
|---|---|---|
| Passwords | Vaultwarden | — |
| 2FA | Aegis (local) | — |
| Email | Stalwart/Mailcow on VPS | Proton / Tuta / Mailbox.org |
| Drive | Nextcloud / Seafile | — |
| Photos | Immich | — |
| Calendar/Contacts | Nextcloud / Radicale (+ DAVx5) | — |
| Maps | — | Organic Maps / OsmAnd (offline) |
| Search | SearXNG | public SearXNG instance |
| YouTube | NewPipe / FreeTube / Grayjay | (conscious‑choice logged‑in) |
| Payments | — | Curve / Garmin Pay / Swish / bank app |
| App store | — | Aurora Store + F‑Droid |
| Networking | Headscale (you already run this) | — |
