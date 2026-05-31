# restic-backup

Push-mode restic backups from this host to one or more SFTP receivers. Pairs with the `restic-target` module on the receiving end. One systemd timer is generated per target — each target is an independent repo with its own snapshot history.

## Usage

```nix
restic-backup = {
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
      sftpHost = "desktop.ts.rydback.net";
      sftpUser = "restic-controller";
      # sftpPath defaults to /repo (post-chroot path on the receiver)
    };
    island = {
      sftpHost = "island.ts.rydback.net";
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
| targets.&lt;name&gt;.sftpHost | string | (required) | Receiver hostname, typically `<host>.ts.rydback.net`. |
| targets.&lt;name&gt;.sftpUser | string | (required) | Username on the receiver. Convention: `restic-<this-source>`. |
| targets.&lt;name&gt;.sftpPath | path | `"/repo"` | Path *inside* the receiver's chroot. Default matches `restic-target`'s writable subdir. |
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
restic-island  snapshots

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

- **Host key TOFU.** First connection to each target accepts and pins the host key into `/var/lib/restic/known_hosts`. On the tailnet with deny-by-default firewalls and Headscale-coordinated peers, MITM is implausible — but a paranoid operator can pre-populate that file from `hosts.<target>.ssh.host` in `lib/default.nix` before the first backup runs.
- **Initial snapshot size.** `/var/lib/emulation` is potentially many GB. The first push to `island.ts.rydback.net` over residential upload is slow; consider seeding island over LAN on a visit, then letting incremental snapshots take over.
- **One password, multiple repos.** The single `passwordFile` is reused across every target — each repo is initialised with the same password. Restic's threat model treats each repo independently, so this is fine; the only operational cost is that rotating the password means rotating every repo.
- **Verify restores quarterly.** Untested backups are hope, not backups. The de-googling plan explicitly calls this out; consider a systemd timer that picks a random path and restores it to a tmp dir as a smoke test.
