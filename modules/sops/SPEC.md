# sops

Integrates [sops-nix](https://github.com/Mic92/sops-nix) with a separate `nix-secrets` flake input. Secrets are committed (encrypted) to that repo and decrypted at activation using the host's SSH host key as the age identity. Admin recipients (a YubiKey-backed identity via `age-plugin-yubikey` and a software backup) are added to every secret so the operator can edit; hosts only ever decrypt with their own SSH host key.

The module has two halves:

- **`system.nix`** — NixOS module: wires sops-nix, points it at the per-host encrypted file, configures the SSH host key as the decryption identity, and enables prerequisites. Implicitly enables the `openssh` module (so `/etc/ssh/ssh_host_ed25519_key` exists) and `services.pcscd` (for YubiKey access when editing).
- **`user.nix`** — home-manager module: opt-in editing toolchain (`sops`, `age`, `age-plugin-yubikey`) for users who maintain the `nix-secrets` repo. Sets `SOPS_AGE_KEY_FILE` to the conventional `~/.config/sops/age/keys.txt`.

## Usage

### System (per host)

```nix
# in hosts/<host>/system.nix
{ inputs, ... }: {
  sops-secrets = {
    enable = true;
    secretsFile = "${inputs.nix-secrets}/secrets/<host>.yaml";
  };

  sops.secrets."tavily_api_key" = {
    owner = "birgerrydback";
    mode  = "0400";
  };

  sops.secrets."ssh-bits" = {
    key   = "users/birgerrydback/ssh/bits";
    owner = "birgerrydback";
    mode  = "0600";
    path  = "/home/birgerrydback/.ssh/bits";
  };
}
```

The host's `default.nix` must also include the sops-nix module:
```nix
modules = [
  ...
  inputs.sops-nix.nixosModules.sops
  ...
];
```

### User (per editor)

```nix
# in hosts/<host>/user-<name>.nix
sops-edit.enable = true;
```

## Options

### System (`sops-secrets`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable sops-nix-managed secrets for this host |
| secretsFile | path | (required) | Path to the encrypted YAML file (typically `"${inputs.nix-secrets}/secrets/<host>.yaml"`) |

When enabled, also flips on `openssh.enable = true;` (see `modules/openssh/SPEC.md`) and `services.pcscd`.

### User (`sops-edit`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Install sops/age/age-plugin-yubikey and export `SOPS_AGE_KEY_FILE` |

## Bootstrap

A new host joins by:
1. Running `sudo ssh-keygen -A` (or letting the openssh activation generate keys) to ensure `/etc/ssh/ssh_host_ed25519_key` exists.
2. Converting the public half to an age recipient: `cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age`.
3. Adding that recipient and a `creation_rules` block for `secrets/<host>.yaml` to `nix-secrets/.sops.yaml`.
4. Creating `secrets/<host>.yaml` via `sops`.
5. Setting `sops-secrets.enable = true; secretsFile = "${inputs.nix-secrets}/secrets/<host>.yaml";` in the host config.

## Notes

- Per-user secret *delivery* (e.g. SSH keys into `~/.ssh/`) is handled by the NixOS module using `sops.secrets.<name>.{owner,path}`. The home-manager half is only for editing tools.
- Secrets are looked up in the YAML by the secret name, with `/` interpreted as nested-key separators. Use `sops.secrets.<name>.key` to override the lookup path when the secret name doesn't match the YAML structure.
- `/etc/ssh/ssh_host_ed25519_key` lives outside `/nix/store` and survives rebuilds, so the host's decryption identity is stable.
- Editing secrets requires the YubiKey (or the backup software age key from 1Password); see `nix-secrets/.sops.yaml` for the configured recipients.
