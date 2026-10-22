# restic-backup

Push-mode restic backups from this host to one or more SFTP receivers. Pairs with the `restic-target` module on the receiving end. One systemd timer is generated per target — each target is an independent repo with its own snapshot history.

## Usage

```nix
my.restic-backup = {
  enable = true;

  paths = [
    "/var/lib/vaultwarden"
    "/var/lib/headscale"
    "/var/lib/git/nix-vault.git"
    "/var/lib/emulation"
  ];

  excludes = [
    "**/.cache/**"
    "**/.thumbnails/**"
  ];

  passwordFile = config.sops.secrets."restic-repo-password".path;
  sshKeyFile = config.sops.secrets."restic-ssh-key".path;

  targets = {
    desktop = {
      sftpUser = "restic-controller";
      # sftpPath defaults to /repo (post-chroot path on the receiver)
    };
    island-stationary = {
      sftpUser = "restic-controller";
    };
  };
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable push-mode restic backups. |
| paths | list of paths | `[ ]` | Paths included in every job; same set pushed to every target. |
| excludes | list of strings | `[ ]` | Restic exclude patterns, one `--exclude <pat>` arg per entry. |
| passwordFile | path | (required) | File holding the repo password. Typically sops-decrypted. |
| sshKeyFile | path | (required) | Private SSH key for SFTP auth. Typically sops-decrypted. |
| targets | attrset of submodule | `{ }` | Named targets; one `services.restic.backups.<name>` job each. |
| targets.&lt;name&gt;.hostKey | null or string | `lib.hosts.<name>.ssh.host` or `null` | Receiver's SSH host key; connections are checked strictly against it. `null` falls back to trust-on-first-use (`accept-new`, remembered in `/var/lib/restic/known_hosts`). |
| targets.&lt;name&gt;.sftpHost | string | `lib.tailnet.fqdn <name>` | Receiver hostname; defaults to the tailnet FQDN of the fleet host the target is named after. |
| targets.&lt;name&gt;.sftpUser | string | (required) | Username on the receiver. Convention: `restic-<this-source>`. |
| targets.&lt;name&gt;.sftpPath | path | `"/repo"` | Path *inside* the receiver's chroot. Default matches `restic-target`'s writable subdir. |
| verify.enable | bool | true | `restic check --read-data-subset` after every run plus a weekly restore test (`restic-verify-<target>.timer`). |
| verify.onCalendar | string | `"weekly"` | Schedule of the restore test. |
| verify.readDataSubset | string | `"2%"` | Share of pack data the post-run check reads; 2% a day covers the repo in about seven weeks. |
| verify.maxSnapshotAgeDays | int | 2 | The restore test fails when the latest snapshot is older. |
| verify.restorePath | path | `head paths` | Path restored (with `--verify`) into a scratch dir under `/var/lib/restic`. Keep it small. |
| timerOnCalendar | string | `"daily"` | systemd OnCalendar expression. |
| pruneOpts | list of strings | `--keep-daily 7 --keep-weekly 4 --keep-monthly 12` | `forget --prune` options applied after each run. |

## Secrets handling

**Restic credentials are machine-to-machine — sops is the single source of truth. They never get duplicated into Vaultwarden.**

The reason Vaultwarden exists is operator convenience for credentials a human types into a UI. Nothing about the restic flow involves a human:

- The systemd-managed `restic-backups-<target>.service` reads `passwordFile` directly from disk (sops-decrypted to a root-only path).
- The same service uses `sshKeyFile` to authenticate to the receiver — also sops-decrypted, also never typed.

Adding these to Vaultwarden would create a second copy of the same secret that the operator now has to keep in sync, with zero security benefit.

The public half of the SSH key goes in `lib/default.nix` under `hosts.<source>.users.restic.ssh.<keyname>` — see the `restic-target` SPEC for how receivers consume it.

## Per-host vs shared password

Default: **one repo per source, one password per source.** Each target is a separate restic repo, and the password file lives in the source host's per-host sops secret file (e.g. `nix-vault/secrets/controller.yaml`). This isolates blast radius — compromise of one source doesn't grant access to another source's repo.

When does this need to change? Only if you add a **second source** that has heavily overlapping data with the first (the only reason to share a repo is restic's cross-source deduplication). The upgrade path is:

1. Add `nix-vault/secrets/common.yaml` with a `creation_rules` entry in `.sops.yaml` encrypting it to every source host's age recipient.
2. Move the password under that file.
3. Point both sources' `passwordFile = config.sops.secrets."<name>".path` at the now-shared key.

There is no `common.yaml` convention in this repo today — don't introduce one preemptively for one source.

## Disaster recovery

If the source host is wiped and the local copy of sops material is lost:

1. On any recovery system, install `sops-nix`'s prerequisites (`age`, `age-plugin-yubikey`), plug in the operator's YubiKey.
2. Clone `nix-vault.git` (the bare repo on controller is itself in the backup set, but you can also clone from any host that has a working copy — every onboarded host has one).
3. `sops decrypt nix-vault/secrets/<source-host>.yaml` — the YubiKey is the only thing needed.
4. Use the recovered password to restore from any target with `restic -r sftp:restic-<source>@<target>.ts.rydback.net:/var/lib/restic-repos/<source> restore latest --target /restore`.

The repo password never needs to live outside sops because nix-vault is itself the off-source secret store.

## Restore recipe

```bash
# On the source host (controller). services.restic.backups.<target> generates
# a wrapper named `restic-<target>` that pre-injects --repo, --password-file
# and sftp.args from this module's config — no need to repeat them.
restic-desktop snapshots
restic-island-stationary snapshots

# Restore the most recent snapshot of /var/lib/vaultwarden into a sandbox:
restic-desktop restore latest --target /tmp/restore --path /var/lib/vaultwarden
```

Off-host / disaster recovery (a clean machine without this module) needs raw restic with the flags spelled out:

```bash
restic \
  -r sftp:restic-controller@desktop.ts.rydback.net:/repo \
  --password-file /path/to/decrypted-restic-repo-password \
  -o sftp.args='-i /path/to/decrypted-restic-ssh-key -o StrictHostKeyChecking=accept-new' \
  snapshots
```

## Notes

- **Sleeping targets are woken.** A target with a WoL relay in the registry (`hosts.<target>.wol.relay`, real MAC) is woken before each run and the run waits up to 5 minutes for its SSH port (`backupPrepareCommand`). When this host is the relay it sends the magic packet itself; otherwise it runs `wake-<target>` on the relay over SSH as the relay's `wake` account, which `modules/common` creates on every relay host and which accepts the fleet's restic keys (registry `users.restic`) with a forced command that allows nothing else. A target that stays down fails the run; the next day's run and the restore test's age check make that visible. The target may still suspend during a long run if its idle detection doesn't count the SFTP session as activity.
- **Host keys are pinned.** Each target's host key defaults to `lib.hosts.<target>.ssh.host`, and SFTP runs with `StrictHostKeyChecking=yes` against a store-generated known_hosts file, so a changed or spoofed receiver is refused. Only targets with no key in the registry (and no explicit `hostKey`) fall back to trust-on-first-use in `/var/lib/restic/known_hosts`.
- **Initial snapshot size.** `/var/lib/emulation` is potentially many GB. The first push to `island-stationary.ts.rydback.net` over residential upload is slow; consider seeding island-stationary over LAN on a visit, then letting incremental snapshots take over.
- **One password, multiple repos.** The single `passwordFile` is reused across every target — each repo is initialised with the same password. Restic's threat model treats each repo independently, so this is fine; the only operational cost is that rotating the password means rotating every repo.
- **Verification is built in** (`verify.enable`, on by default). Each run ends with `restic check --read-data-subset=<share>` on that repo, so a corrupt pack fails the unit instead of waiting for the day it is needed. Once a week `restic-verify-<target>` wakes the target, asserts the latest snapshot is at most `maxSnapshotAgeDays` old (a silently failing backup shows up here even when nobody reads the journal), restores `restorePath` with `--verify` into a scratch dir under `/var/lib/restic` and requires at least one file. Both are visible as failed units; `journalctl -u restic-verify-<target>` has the summary line. This is the automated half of the disaster-recovery doctrine in `docs/de-cloud.md`; the manual drill in `docs/disaster-recovery.md` is still run by hand.
