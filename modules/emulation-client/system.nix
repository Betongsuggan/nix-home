{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.emulation-mounts;

  # Common CIFS mount options.
  #
  # `x-systemd.automount` is the key piece: instead of a hard mount at boot
  # (which would fail and block if the server is unreachable, or race
  # tailscaled coming up), systemd sets up an autofs-style mountpoint that
  # mounts on first access and unmounts after idle. Cheap, lazy, and the
  # share is silently absent rather than a boot failure when controller is
  # offline.
  #
  # `noperm` skips client-side permission checks — the share is read-only
  # and anonymous-readable on the server anyway, so any local user reading
  # it is fine. Avoids needing per-user uid/gid mapping in the options.
  commonOpts = [
    "guest"
    "ro"
    "nofail"
    "_netdev"
    "noperm"
    "dir_mode=0755"
    "file_mode=0644"
    "x-systemd.automount"
    "x-systemd.idle-timeout=60s"
    "x-systemd.mount-timeout=15s"
    # closetimeo=0: disable CIFS deferred-close handle caching. By default CIFS
    # keeps a file handle open server-side for a few seconds after the app
    # closes it (see `cifs_close_all_deferred_files_sb`). At shutdown, if a ROM
    # was still recently open (e.g. a Switch .xci in Ryujinx) AND the server has
    # gone unreachable, the deferred handle can't be flushed, leaving a busy
    # inode that trips `kernel BUG at fs/super.c:654` ("Busy inodes after
    # unmount of cifs") — which hangs shutdown in PID 1 and forces a hard
    # power-off. Closing handles immediately removes the trigger. Safe here: the
    # shares are read-only-ish media access, not latency-sensitive.
    "closetimeo=0"
    # cache=none: the default cache=strict corrupts random-access reads deep
    # into large files over this tailnet CIFS link (a plain sequential copy is
    # fine, but Ryujinx's seek-heavy reads of multi-GB Switch .xci images come
    # back wrong → LibHac ResultFsOutOfRange / "no valid application"). Reading
    # uncached fixes it. If Switch gameplay stutters from the uncached reads,
    # try "cache=loose" (cached, relaxed coherency — safe for these read-only
    # shares) instead.
    "cache=none"
  ];

  mkUserMounts =
    user:
    let
      home = "/home/${user}";
    in
    [
      {
        name = "${home}/emulation/roms";
        value = {
          device = "//${cfg.server}/emulation-roms";
          fsType = "cifs";
          options = commonOpts;
        };
      }
      {
        name = "${home}/emulation/bios";
        value = {
          device = "//${cfg.server}/emulation-bios";
          fsType = "cifs";
          options = commonOpts;
        };
      }
    ];
in
{
  options.emulation-mounts = {
    enable = mkEnableOption "Auto-mount emulation-server Samba shares into users' home directories";

    server = mkOption {
      type = types.str;
      example = "controller.ts.rydback.net";
      description = ''
        Hostname or address of the Samba server hosting the
        `emulation-roms` and `emulation-bios` shares. Usually the
        emulation-server host's tailnet FQDN — anything addressable from
        this host that exports the standard share names.
      '';
    };

    users = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "betongsuggan" "gamer" ];
      description = ''
        User accounts that should get `~/emulation/{roms,bios}` automounted
        from the emulation server's Samba shares. The mounts use
        `x-systemd.automount` so they're created lazily on first access
        rather than at boot — no failure if controller is offline, no race
        with tailscaled coming up.
      '';
    };
  };

  config = mkIf cfg.enable {
    fileSystems = listToAttrs (concatMap mkUserMounts cfg.users);

    # Create each user's `~/emulation/` parent. The mount-point dirs
    # themselves (`roms`, `bios`) are auto-created by systemd on first
    # access, but their parent must exist.
    systemd.tmpfiles.rules = map (
      user: "d /home/${user}/emulation 0755 ${user} users -"
    ) cfg.users;

    environment.systemPackages = [ pkgs.cifs-utils ];
  };
}
