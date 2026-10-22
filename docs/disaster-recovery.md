# Disaster recovery — `controller`

What to do when `controller` is gone: disk dead, box stolen, house burned. Written 2026-10-18 against the live configuration; keep it in step with `hosts/controller/system.nix` and `modules/restic-backup/SPEC.md` whenever the restic path set, a target, or a service's state directory changes.

The three facts this whole document rests on:

1. **Every secret controller needs is in `nix-vault`**, encrypted to the operator's YubiKey. A fresh clone plus the YubiKey decrypts `secrets/controller.yaml`, which holds the restic repo password and the restic SSH private key. Nothing has to be remembered or stored anywhere else.
2. **Every onboarded host has a working copy of `nix-vault`** (desktop, bits, island-stationary, island-pi via its deployer). Clone from one of them; the bare repo on controller is also inside the restic set, but you never need it to start.
3. **The restic repos are plain SFTP directories.** Any machine with `restic`, the password and the key can read them. No wrapper from this flake is required.

If the YubiKey is lost together with controller, see §7 first.

---

## 0. What you are recovering

| Data | Path in the snapshot | Service | Notes |
|---|---|---|---|
| Password vault | `/var/lib/vaultwarden` | Vaultwarden | SQLite DB, attachments, Sends |
| Tailnet control plane | `/var/lib/headscale` | headscale | SQLite DB, noise + DERP private keys |
| Files, calendar, contacts, notes | `/var/lib/nextcloud` | Nextcloud | `data/` and `config/config.php`; the DB is separate |
| Nextcloud + OnlyOffice databases | `/var/backups/postgresql/{nextcloud,onlyoffice}.sql.gz` | PostgreSQL | daily `pg_dump` at 01:15, restic runs 01:45 |
| Emulation data | `/var/lib/emulation` | Syncthing + Samba | 36 GB+; restore last |
| Secrets repo | `/var/lib/git/nix-vault.git` | git-server | bare; a clone on any host is equivalent |
| WoW guide repo | `/var/lib/git/wow-leveling.git` | git-server | bare; also a flake input, so any host's Nix store has the content |

Not in the snapshot, on purpose: TLS certificates (ACME re-issues), the nix store, the OS. Retention is 7 daily / 4 weekly / 12 monthly per target.

Targets, in the order to try them:

| Name | SFTP endpoint | Reachability |
|---|---|---|
| `desktop` | `restic-controller@desktop.ts.rydback.net:/repo` | On-site. Must be awake: WoL from the LAN (`wakeonlan 34:1b:22:84:72:67`) or the power button. |
| `island-stationary` | `restic-controller@island-stationary.ts.rydback.net:/repo` | Off-site, summer house. Wake with `ssh island-pi wake-island-stationary`. May have missed runs while asleep; check `snapshots` dates. |
| Hetzner Storage Box | *(backlog item 1 in `docs/de-cloud.md`; add the endpoint here when it exists)* | Always on |

The tailnet names only resolve while headscale is up, which it is not when controller is dead. Use the LAN IP for desktop (`192.168.50.x`, check the router at `192.168.50.1`) or the public IP of the summer house for island-stationary, or do the restore *on* the target host itself, which is simplest: the repo is a local directory there (`/var/lib/restic-repos/controller/repo`).

---

## 1. Decide the recovery host

- **Same hardware class, same name.** Reinstall as `controller` from `hosts/controller`. Nothing in the fleet changes except controller's SSH host key (§4).
- **Different hardware.** Still install as `controller`: the only hardware-specific lines in `hosts/controller/system.nix` are `boot.initrd.availableKernelModules`, `hardware.cpu.intel.updateMicrocode`, `my.graphics.intel`, the NetworkManager profile for `enp1s0`, and the three `fileSystems`/`swapDevices` UUIDs. Adjust those; keep the name. Renaming the host would ripple through every `hosts.controller` reference in `lib/default.nix`, every peer's `sshFrom`, the restic receivers' user names and the headscale `server_url`. Do not.

Keep the LAN address `192.168.50.5` and the router's port forwards for 80/443 (ACME, headscale) and UDP 3478 (DERP STUN) pointing at it. `rydback.net`'s A record in Route 53 points at the home WAN IP; it does not change unless the ISP connection did.

---

## 2. Install NixOS on the replacement

From any onboarded machine with this repo:

```bash
cd ~/nix-home
# Edit hosts/controller/system.nix: disk UUIDs, kernel modules, NIC name.
# Build-test without nix-vault access:
nix build .#nixosConfigurations.controller.config.system.build.toplevel \
  --override-input nix-vault path:$HOME/nix-vault
```

Install with the normal installer (`nixos-install --flake .#controller --override-input nix-vault path:/path/to/nix-vault` from the live ISO with this repo and a `nix-vault` clone copied onto it), or with `nixos-anywhere` if the box is reachable over SSH from the installer. Controller is the tailnet coordinator, so the `home-network` bootstrap flow does **not** apply to it: it has no tailnet to join yet. Its `my.home-network.mode = "controller"` brings headscale up on first boot.

First boot will fail to activate sops secrets (the new host key is not a recipient yet) and therefore fail to start Vaultwarden, headscale, restic. That is expected; §3 and §4 fix it.

---

## 3. Recover the secrets (YubiKey)

On the recovery workstation, with the YubiKey inserted:

```bash
nix shell nixpkgs#sops nixpkgs#age nixpkgs#age-plugin-yubikey nixpkgs#restic
git clone <any-host>:nix-vault ~/nix-vault      # or copy ~/nix-vault from desktop/bits
cd ~/nix-vault
sops decrypt --extract '["services"]["restic-repo-password"]' secrets/controller.yaml > /tmp/restic.pw
sops decrypt --extract '["services"]["restic-ssh-key"]'       secrets/controller.yaml > /tmp/restic.key
chmod 600 /tmp/restic.pw /tmp/restic.key
```

Touch the YubiKey when it blinks. These two files are everything restic needs.

---

## 4. Re-enroll the new host key in `nix-vault`

The replacement's `/etc/ssh/ssh_host_ed25519_key` is new, so it cannot decrypt `secrets/controller.yaml` until it is a recipient (`modules/sops/SPEC.md`, "Bootstrap"):

```bash
# On the new controller
cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
```

On the workstation, in `~/nix-vault`: replace controller's old `age1…` recipient in `.sops.yaml` with the new one, then

```bash
sops updatekeys secrets/controller.yaml
git commit -am "controller: new host key after rebuild" && git push   # push waits until §6
```

In `nix-home`, update `hosts.controller.ssh.host` in `lib/default.nix` with the new public key. It feeds every peer's `known_hosts`, the restic receivers' `hostKey` pinning for *their* targets (not relevant for controller as a source), and `allSshKeys` on controller's own git server. Commit; push once controller's git server is back (§6), or push to wherever your `nix-home` origin lives.

The restic **user** key (`hosts.controller.users.restic.ssh.id_ed25519`) does not change: its private half comes back from sops, so desktop and island-stationary keep accepting it. Nothing to edit on the receivers.

---

## 5. Restore the data

### 5a. From the recovery workstation over SFTP

One block per target; replace the host with a LAN/WAN IP if MagicDNS is down. Host-key checking is set to `accept-new` because the pinned known_hosts file from the module does not exist off-host; compare the fingerprint against `lib/default.nix` by hand.

```bash
export RESTIC_PASSWORD_FILE=/tmp/restic.pw
SFTP_ARGS='-i /tmp/restic.key -o StrictHostKeyChecking=accept-new'

# desktop (on-site)
restic -r sftp:restic-controller@desktop.ts.rydback.net:/repo -o sftp.args="$SFTP_ARGS" snapshots
restic -r sftp:restic-controller@desktop.ts.rydback.net:/repo -o sftp.args="$SFTP_ARGS" \
  restore latest --target /restore

# island-stationary (off-site)
restic -r sftp:restic-controller@island-stationary.ts.rydback.net:/repo -o sftp.args="$SFTP_ARGS" snapshots
```

`restore latest --target /restore` recreates the original absolute paths under `/restore` (so `/restore/var/lib/vaultwarden`, …). Add `--path /var/lib/vaultwarden` to pull one directory only; do the small ones first and `/var/lib/emulation` last or never.

### 5b. On the target host itself (fastest, no network)

```bash
sudo restic -r /var/lib/restic-repos/controller/repo --password-file /tmp/restic.pw snapshots
sudo restic -r /var/lib/restic-repos/controller/repo --password-file /tmp/restic.pw \
  restore latest --target /restore
```

Then copy `/restore/var/lib/...` to the new controller with `rsync -aHAX --numeric-ids` over SSH (as root; ownership must survive).

### 5c. Put it in place on the new controller

Stop every consumer first, then move the directories in and fix ownership. The system users exist after the first `nixos-rebuild`, so run this after §2 and §4.

```bash
sudo systemctl stop vaultwarden headscale nextcloud-setup phpfpm-nextcloud nginx \
  syncthing samba-smbd postgresql onlyoffice-docservice onlyoffice-converter 2>/dev/null

sudo rsync -aHAX --numeric-ids /restore/var/lib/vaultwarden/ /var/lib/vaultwarden/
sudo rsync -aHAX --numeric-ids /restore/var/lib/headscale/   /var/lib/headscale/
sudo rsync -aHAX --numeric-ids /restore/var/lib/nextcloud/   /var/lib/nextcloud/
sudo rsync -aHAX --numeric-ids /restore/var/lib/git/         /var/lib/git/
sudo rsync -aHAX --numeric-ids /restore/var/lib/emulation/   /var/lib/emulation/   # optional, big

sudo chown -R vaultwarden:vaultwarden /var/lib/vaultwarden
sudo chown -R headscale:headscale     /var/lib/headscale
sudo chown -R nextcloud:nextcloud     /var/lib/nextcloud
sudo chown -R git:git                 /var/lib/git
sudo chown -R betongsuggan:users      /var/lib/emulation
```

`--numeric-ids` keeps the UIDs from the snapshot; NixOS allocates system UIDs deterministically from `ids.nix` only for users with a fixed ID, so the `chown` lines are what actually make it right on a fresh install.

Databases, after `postgresql` is up again (`sudo systemctl start postgresql`); the roles and empty databases are created by the Nextcloud and OnlyOffice modules on activation:

```bash
zcat /restore/var/backups/postgresql/nextcloud.sql.gz  | sudo -u postgres psql nextcloud
zcat /restore/var/backups/postgresql/onlyoffice.sql.gz | sudo -u postgres psql onlyoffice
```

The dump is from 01:15 and the files from 01:45 of the same night; a file uploaded between them exists on disk but not in the DB. `sudo -u nextcloud nextcloud-occ files:scan --all` after the restore reconciles that.

Rebuild and start:

```bash
cd ~/nix-home && sudo nixos-rebuild switch --flake .#controller
```

---

## 6. Service-by-service checks and gotchas

**headscale.** With `/var/lib/headscale` restored, every node, its keys and the DERP identity are back and clients reconnect on their own. `sudo headscale nodes list` should show the fleet. If the state did **not** come back (restore failed, or you chose not to), headscale starts empty: every host's `services/headscale-preauthkey` in `nix-vault` is now invalid. Mint new reusable keys (`sudo headscale preauthkeys create --user birger --reusable --expiration 8760h`), put them in each host's `secrets/<host>.yaml`, rebuild each host, and on each run `sudo tailscale logout && sudo systemctl restart tailscaled-autoconnect`. Phones: log out and back in to `https://vpn.rydback.net`. The embedded DERP gets a new key; clients pick it up from the map.

**Vaultwarden.** Data dir restored, `ADMIN_TOKEN` back via sops. Clients never noticed: they work from their local cache and resync. Confirm `https://vault.rydback.net/admin` opens with the token.

**Nextcloud.** `config/config.php` is in `/var/lib/nextcloud/config` and carries the instance id and the `secret`; because it is restored, existing app passwords and DAVx5 logins keep working. `nextcloud-setup.service` runs on activation and is idempotent against an existing install. Re-check the ONLYOFFICE app's "Document Editing Service address" and secret in the admin UI (`modules/onlyoffice/SPEC.md`).

**git-server.** Bare repos restored; `git-server-init` leaves existing repos alone. Push the `nix-vault` and `nix-home` commits from §4 now.

**TLS.** Do not restore `/var/lib/acme`. Once `rydback.net` resolves to the new box and 80/443 are forwarded, nginx's ACME units issue fresh certs on first start (`journalctl -u acme-rydback.net`). Let's Encrypt rate limits are 50 certs per domain per week, far above what this host needs.

**Restic.** The restored `secrets/controller.yaml` makes the source side work unchanged: same password, same key, same targets. The first run after recovery is just another incremental snapshot. `sudo systemctl start restic-backups-desktop` and read `journalctl -u restic-backups-desktop` to confirm.

**Emulation.** Syncthing's own state is under `~betongsuggan/.config/syncthing` on controller and was *not* in the snapshot; it re-pairs declaratively on rebuild (devices from lib). The folder content is in `/var/lib/emulation`. A fresh config dir means a **new Syncthing device ID** for controller: run `syncthing --device-id` as `betongsuggan`, put it in `hosts.controller.users.betongsuggan.syncthing.id` in `lib/default.nix`, and rebuild desktop (both users) so the peers accept it; the Android devices need the new ID entered by hand.

---

## 7. The real disaster: YubiKey and controller lost together

Honest state as of 2026-10-18: `modules/sops/SPEC.md` says admin recipients are "a YubiKey-backed identity and a software backup", and names 1Password as where that backup key lives. **Verify that the software age key exists and is retrievable** (`nix-vault/.sops.yaml` lists two admin recipients if so). If it does, this scenario reduces to §3 with `SOPS_AGE_KEY_FILE` pointing at the backup key instead of the YubiKey plugin.

If the backup key does not exist or is itself inside Vaultwarden on controller, there is **no** path to the restic password and the backups are ciphertext forever. Open decision, to settle in backlog item 1 of `docs/de-cloud.md`:

- a second YubiKey enrolled as an additional admin recipient, kept in a different building, or
- the software age identity printed (or on a USB stick) in a fireproof safe, and an entry in Vaultwarden is *not* an acceptable place for it since Vaultwarden is what you are recovering.

Either way the restic password should be exportable on its own: `sops decrypt --extract` as in §3, printed, same safe. Two small pieces of paper remove the single point of failure.

---

## 8. Drill

Run once now, then yearly, and after any change to the restic path set. Expected time: 30 minutes without `/var/lib/emulation`.

1. On a workstation with the YubiKey: §3 end to end. Checks that `nix-vault` still decrypts and that the extracted files are non-empty.
2. §5a `snapshots` against **every** target. Record the newest snapshot date per target here. A target whose newest snapshot is older than a week is a finding.
3. `restore latest --path /var/lib/vaultwarden --target /tmp/drill` from one target, then open `/tmp/drill/var/lib/vaultwarden/db.sqlite3` with `sqlite3 ... '.tables'`. Checks that the data is readable, not just that the pack files exist.
4. `zcat` the Nextcloud dump and `grep -c INSERT` it. Checks that the dump is not an empty file from a failed `pg_dump`.
5. `shred -u /tmp/restic.pw /tmp/restic.key; rm -r /tmp/drill`.

Log:

| Date | Who | Targets reachable | Newest snapshot per target | Findings |
|---|---|---|---|---|
| | | | | |
