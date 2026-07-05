# File Sharing

Configures network file sharing via Samba (SMB). Supports defining multiple shares with per-share access control, and enables WSDD for network discovery by Windows and Android clients.

## Usage

```nix
file-sharing = {
  enable = true;
  samba = {
    enable = true;
    openFirewall = true;
    shares = [
      {
        name = "shared";
        path = "/home/user/shared";
        validUsers = [ "user" ];
        readOnly = false;
      }
    ];
  };
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable file sharing |
| samba.enable | bool | false | Enable Samba (SMB) file sharing |
| samba.shares | list of share | [] | List of Samba share definitions |
| samba.workgroup | string | "WORKGROUP" | Network workgroup name |
| samba.allowedSubnets | list of string | ["192.168.0.0/16" "10.0.0.0/8" "172.16.0.0/12"] | Subnets allowed to access Samba shares (`hosts allow` line) |
| samba.interfaces | list of string | [] | Interfaces to bind to (empty = all). When set, `bind interfaces only = yes` is enabled — Samba won't even open sockets on other interfaces. Stronger than `allowedSubnets` alone. |
| samba.openFirewall | bool | false | Automatically open firewall ports for Samba |

Each share in `samba.shares` has the following attributes:

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| name | string | (required) | Name of the share (visible on network) |
| path | path | (required) | Path to the shared directory |
| validUsers | list of string | [] | Users allowed to access (ignored when `guestOk = true`) |
| readOnly | bool | false | Whether the share is read-only at the protocol layer |
| guestOk | bool | false | Allow anonymous (passwordless) access. Runs the share in guest-only mode — see notes below. |
| forceUser | nullable string | null | Force every operation to run as this Unix user on the filesystem, regardless of client identity. Required for writable guest shares whose backing directory is owned by a real user. |
| deleteProtection | bool | false | Soft-delete via `vfs_recycle`: every unlink/rmdir is moved to a hidden `.recycle/` directory inside the share rather than actually deleted. Writes, renames, and overwrites still flow through normally. See notes. |

## Notes

- SMB1 is disabled; only SMB2.10 and above are permitted.
- WSDD (Web Services Dynamic Discovery) is automatically enabled alongside Samba for network visibility.

### Auth model: per-user vs guest

For shares with `guestOk = false`: per-user Samba passwords must be set separately using `smbpasswd -a <username>`. They are independent of system passwords.

For shares with `guestOk = true`: the share is served in **guest-only** mode (`guest only = yes`). Every connection is mapped to the guest account regardless of any username the client supplies; no `smbpasswd` setup is needed. Security must come from the network layer — typically by restricting `allowedSubnets` to a trusted network (LAN, tailnet).

The global `map to guest = Bad User` makes this work for *all* clients, not just anonymous ones. Without it (`security = user` defaults to `map to guest = Never`), a client that sends an explicit unknown username — e.g. Solid Explorer on Android logging in as `guest` — is rejected with `NT_STATUS_LOGON_FAILURE` ("authentication problem"), because Samba tries to authenticate that name and refuses to fall back. `Bad User` maps any unknown username to the guest account, so both null-session (Linux `cifs guest`) and named-guest clients connect.

### `forceUser` for writable guest shares

When a guest connection lands without a real username, Samba runs filesystem ops as the Unix `nobody` user by default. If the share's backing directory is owned by `betongsuggan:users` mode `0775`, `nobody` falls into the "other" bucket (`5` = read+execute, no write) and writes will fail with EACCES even with `readOnly = false`.

`forceUser = "betongsuggan"` makes the server treat every guest operation as `betongsuggan` on the filesystem — new files become `betongsuggan`-owned, existing `betongsuggan`-owned files can be modified. This is the standard pattern for tailnet-public writable shares; the bounded scope of the share path is what limits blast radius, not Unix user identity.

### `deleteProtection` via `vfs_recycle`

When enabled, Samba intercepts `unlink`/`rmdir` calls and moves the target into `<share-path>/.recycle/` instead of actually removing it. The recycle directory:

- Is hidden from clients via `veto files = /.recycle/` and `hide files = /.recycle/` (clients can't see it, list it, or operate on it).
- Preserves the original directory tree (`recycle:keeptree = yes`).
- Keeps versions when the same path is deleted repeatedly (`recycle:versions = yes`).
- Excludes obvious scratch patterns (`*.tmp *.temp *.bak ~$*`) so editor swap files don't pile up.

**Operator hygiene:** the recycle directory grows without bound. Periodically inspect with `sudo du -sh <share-path>/.recycle/` and purge with `sudo rm -rf <share-path>/.recycle/*` when it's reasonable to do so. Worth automating with a systemd timer if the share sees high delete churn.

**What it doesn't protect against:** overwrite-in-place (the new content replaces the old before recycle ever sees an unlink), and rename-over-existing (atomic on most filesystems, no separate unlink). Recycle is a safety net for accidental deletes specifically, not full undo.
