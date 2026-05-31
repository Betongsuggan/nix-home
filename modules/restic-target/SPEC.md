# restic-target

Receive restic backups from one or more source hosts. Pairs with the `restic-backup` module on the push side. No new daemon — just chrooted SFTP-only system users plus per-source storage directories.

## Usage

```nix
restic-target = {
  enable = true;
  sources.controller = {
    sshKey = inputs.self.lib.hosts.controller.ssh.users.restic.id_ed25519;
    # storagePath defaults to /var/lib/restic-repos/controller
    # userName defaults to restic-controller
  };
};
```

Adding a second source is one attribute:

```nix
restic-target.sources.bits = {
  sshKey = inputs.self.lib.hosts.bits.ssh.users.restic.id_ed25519;
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable restic target reception. |
| sources | attrset of submodule | `{ }` | Named source hosts allowed to push. Attribute name = source identifier. |
| sources.&lt;name&gt;.sshKey | string | (required) | Source's public key. Pull from `lib/default.nix`, never as a literal. |
| sources.&lt;name&gt;.storagePath | path | `/var/lib/restic-repos/<name>` | Chroot root (root-owned). Repo lives at `<storagePath>/repo`. |
| sources.&lt;name&gt;.userName | string | `restic-<name>` | System user receiving pushes from this source. |

## Public-key handling

Source pubkeys are consumed from `inputs.self.lib.hosts.<source>.ssh.users.restic.<keyname>` in `lib/default.nix`. **Never paste a pubkey literal into a receiver's host config.**

Why this matters:

- One canonical place for any host's identities. Cross-host references stay consistent.
- Adding a new source = one edit to `lib/default.nix`, not edits in every receiver that should accept it.
- The existing `allSshKeys` collector picks up restic keys automatically, so anything that already iterates over the fleet's pubkeys (like `git-server.authorizedKeys`) keeps working without further changes.

The source itself (the `restic-backup` module) consumes the **private** half from sops — that one's a per-host secret, not a shared key.

## SFTP chroot model

Each source gets its own system user (`restic-<source>`) and its own storage path. OpenSSH chroots the user to `<storagePath>` and forces `internal-sftp`, so the user can only:

- Read/write inside the chroot (specifically the `repo` subdir, which is the only writable thing inside).
- Speak SFTP. No shell, no port forwarding, no X11, no tunnels.

The chroot root itself must be **root-owned, mode 0755** — sshd refuses to chroot into a user-writable directory. That's why the writable area is `<storagePath>/repo` (user-owned, 0700) and the source pushes to `sftp:user@host:/repo` (post-chroot path).

## Restic invocation, post-chroot

The source's `restic-backup` config defaults `sftpPath = "/repo"`, which matches this module's writable subdir. If for some reason you change `storagePath` or layout here, mirror the change on the source side.

## Troubleshooting

- **"Connection closed by remote host" immediately after auth.** Check `journalctl -u sshd -f` while the source attempts a backup. Common causes:
  - Chroot directory isn't root-owned 0755 (e.g. you set `createHome = true` somewhere and the user ended up owning their home).
  - A parent directory of `storagePath` isn't world-traversable (sshd needs to be able to walk to the chroot root).
- **"Permission denied (publickey)".** Verify the pubkey in `lib/default.nix` matches the key the source actually has — `cat /var/lib/restic/id_ed25519.pub` on the source and `ssh-keygen -lf <(echo "<lib value>")` to compare fingerprints.
- **Source-side: "Repository does not exist".** First push runs `restic init`, which requires write access to the empty `repo` dir. If init fails, inspect `journalctl -u restic-backups-<name>.service` for the actual SFTP error.

## Notes

- **No restic daemon needed.** SFTP is universal; restic speaks it natively. The receiver has no restic binary running — it's pure storage.
- **Per-source isolation.** Compromise of one source's key only grants write access to that source's repo subtree. Other sources' repos remain inaccessible because of the per-user chroot.
- **`Match all` reset.** The module ends its sshd extraConfig with `Match all` so that any further `services.openssh.extraConfig` content from other modules doesn't accidentally inherit the restic Match scope.
