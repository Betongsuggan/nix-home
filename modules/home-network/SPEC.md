# Home Network

The single first-class module every host opts into to join the home tailnet. Bundles the headscale coordinator (controller side), the tailscale client + SSH-on-`tailscale0` (every member), and the bootstrap tooling new hosts use to join the tailnet for the very first time.

This is **the primary onboarding document** for the fleet. The bootstrapping doctrine — runbook humans follow + configuration surface the fleet exposes — lives here.

## Why this module exists

`controller` exposes port 22 only on `tailscale0`. That creates a chicken-and-egg for new hosts: they cannot reach `controller` to clone `nix-vault` until they are on the tailnet, but the preauth key that gets them onto the tailnet lives in `nix-vault` (encrypted to the new host's age identity, which is itself derived from a key that does not exist yet).

The module breaks the cycle by having controller publish a continuously rotated, single-use, ephemeral, short-TTL preauth key — age-encrypted to the operator's YubiKey — at a public HTTPS path. A new host fetches the blob, decrypts it locally with the inserted YubiKey, and joins the tailnet on its own as a temporary `installer-XXXXXXXX` node. Port 22 stays tailnet-only. No preexisting tailnet member is required to onboard a new one — only the YubiKey and `controller` being up.

The trust model mirrors the sops material already checked into `nix-vault`: ciphertext is publicly readable; security comes from the YubiKey, not from access control.

## Modes

Exactly one mode applies per host. Set `home-network.mode` explicitly — there is no default, so a typo cannot silently land a host in the wrong state.

| Mode | What it wires up | When it applies |
|------|------------------|-----------------|
| `controller` | headscale + DERP + preauth-key rotator (mints `--ephemeral` keys) + tailscale client + SSH-on-`tailscale0` + reverse-proxy contributions | The single coordinator host (`controller`) |
| `bootstrap` | The `home-network-bootstrap` helper + its runtime tooling (`age`, `age-plugin-yubikey`, `tailscale`, `curl`, `git`, `ssh-to-age`, `sops`) + pcscd + kernel-mode `tailscaled` (not yet joined) + `openssh.enable` so `/etc/ssh/ssh_host_ed25519_key` exists for the upcoming sops enrollment (firewall closed) | A new host on its first install pass, before it has been registered in `nix-vault` |
| `onboarded` | tailscale client (sops-decrypted authkey) + SSH-on-`tailscale0` + `authorizeSshFor` peer keys | Steady state for every member after enrollment |

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Master switch |
| `mode` | enum | (required) | `controller` \| `bootstrap` \| `onboarded` |
| `authorizeSshFor` | attrs | `{ }` | Map `local-user → [{host, user}]`; pulls peer SSH keys from `lib.hosts` into `authorized_keys`. Honoured in `controller`/`onboarded` only. Pass `inputs.self.lib.allUserPeers` to authorize every user key in the fleet (used by controller). |
| `bootstrap.blobUrl` | string | `https://rydback.net/.well-known/tailnet-bootstrap.age` | URL the helper fetches |
| `bootstrap.loginServer` | string | `https://vpn.rydback.net` | Headscale URL passed to `tailscale up` |
| `controller.yubikeyAgeRecipient` | string | `""` | Public age recipient for operator's YubiKey (required in `controller` mode) |
| `controller.headscaleUser` | string | `""` | Headscale user the rotated preauth keys are scoped to (required in `controller` mode) |
| `controller.headscale.domain` | string | `""` | Public domain for headscale (`server_url` host) — required in `controller` mode |
| `controller.headscale.baseDomain` | string | `""` | MagicDNS base domain — required, must differ from `domain` |
| `controller.headscale.users` | list str | `[ ]` | Headscale users to provision idempotently |
| `controller.headscale.extraDnsRecords` | list submod | `[ ]` | MagicDNS overrides pushed to tailnet clients |
| `controller.bootstrap.publicDomain` | string | `"rydback.net"` | Existing nginx vhost that serves the blob |
| `controller.bootstrap.urlPath` | string | `"/.well-known/tailnet-bootstrap.age"` | Path under that vhost |
| `controller.bootstrap.rotateInterval` | string | `"15min"` | How often the blob is regenerated |
| `controller.bootstrap.keyTtl` | string | `"1h"` | Lifetime of each issued preauth key |

## Onboarding a new host

The procedure assumes the new host has already been built once (in `mode = "bootstrap"`) and is running NixOS. The live-installer path is not supported — `nixos-install` first, then bootstrap.

The whole flow is **seven steps**, and steps 3 and 4 are the only ones that need fresh state on the new host or controller. Everything else is local file edits.

### 1. Build the host once

In `nix-home`, declare the host with:

```nix
home-network = {
  enable = true;
  mode = "bootstrap";
};
```

Boot it. Insert the YubiKey.

### 2. Publish the host's SSH keys

On the new host, grab `/etc/ssh/ssh_host_ed25519_key.pub` (the `openssh.enable` flipped on by bootstrap mode created it at activation). Add the host to `lib/default.nix`:

```nix
<host> = {
  tailnetName = "<host>";      # MUST match the system hostname tailscaled will register as
  addresses = [ "<host>" ];
  ssh = {
    host = "ssh-ed25519 AAAA… root@<host>";   # from /etc/ssh/ssh_host_ed25519_key.pub
    users = {
      betongsuggan = {
        id_rsa = "ssh-rsa AAAA… betongsuggan@<host>";  # your personal user pubkey
      };
    };
  };
};
```

Commit and push `nix-home`. (Controller hasn't been rebuilt yet, so these keys aren't trusted yet — that happens in step 4.)

### 3. Run `home-network-bootstrap` on the new host

```bash
home-network-bootstrap
```

Idempotently:
- joins the tailnet via the YubiKey-decrypted rotated blob (as a temporary `installer-XXXXXXXX` node),
- materializes the FIDO resident SSH key with `ssh-keygen -K`,
- `exec`s into an interactive SSH session on `controller` using that FIDO key.

Re-running the command after an early exit is safe — it skips the already-done steps and re-opens the SSH session. The FIDO key is hard-coded to be authorized in controller's `users.users.betongsuggan.openssh.authorizedKeys.keys`, so this always works.

### 4. On controller — rebuild, mint preauth key, prune

Inside the SSH session opened by step 3:

```bash
cd ~/nix-home && git pull && sudo nixos-rebuild switch --flake .#controller
sudo headscale preauthkeys create --user birger --reusable --expiration 8760h
```

The rebuild pulls in the lib changes from step 2 — controller now trusts the new host's user keys for SSH (via `authorizeSshFor.betongsuggan = lib.allUserPeers`) and for git access to `nix-vault.git` (via `git-server.authorizedKeys = lib.allSshKeys`). Copy the printed preauth key string. **One-time cleanup** of any zombie installer nodes left over from before the rotator was switched to ephemeral keys:

```bash
sudo headscale nodes list --output json \
  | jq -r '.[] | select(.name | startswith("installer-")) | .id' \
  | xargs -r -n1 sudo headscale nodes expire -i
```

Exit the SSH session.

### 5. Clone `nix-vault`

Controller now trusts your user key, so:

```bash
cd ~ && git clone git@controller:nix-vault.git
```

### 6. Register the host in `nix-vault`

```bash
# Age recipient derived from the host SSH key (the same one in lib).
cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
```

- Add the resulting `age1…` recipient under the appropriate `creation_rules` block in `~/nix-vault/.sops.yaml`.
- Create `~/nix-vault/secrets/<host>.yaml` with the preauth key from step 4:

  ```yaml
  services:
    headscale-preauthkey: <preauth-key-from-step-4>
  ```

  Use `sops secrets/<host>.yaml` to edit (encrypts with the recipients listed in `.sops.yaml`).

- Commit and push:

  ```bash
  cd ~/nix-vault && git add .sops.yaml secrets/<host>.yaml && git commit -m "add <host>" && git push
  ```

### 7. Flip to `onboarded` and rebuild

In `nix-home`, update the host's `system.nix`:

```nix
home-network = {
  enable = true;
  mode = "onboarded";
};

sops-secrets = {
  enable = true;
  secretsFile = "${inputs.nix-vault}/secrets/<host>.yaml";
};
```

Commit, push, then on the new host:

```bash
sudo nixos-rebuild switch --flake .#<host>
```

The host now joins the tailnet permanently under its real hostname using the sops-decrypted preauth key. The ephemeral `installer-XXXXXXXX` node from step 3 disappears from headscale within a few minutes of the old tailscaled session ending.

## Server-side rotator (controller mode)

What `controller` mode wires up beyond regular tailnet membership:

- `systemd.services.home-network-rotate-preauth` (oneshot): runs `headscale preauthkeys create --user <headscaleUser> --ephemeral --expiration <keyTtl> --output json`, pipes the result through `jq -r .key`, then through `age -r <yubikeyAgeRecipient>`, and atomically renames the output to `/var/lib/home-network/preauth.age` (0644, root).
- `systemd.timers.home-network-rotate-preauth`: triggers the rotator every `controller.bootstrap.rotateInterval` (default 15 min), plus 30s after boot.
- Adds a `location` block to the existing nginx virtual host named by `controller.bootstrap.publicDomain` (default `rydback.net`) that serves the blob over HTTPS as `application/octet-stream` with `Cache-Control: no-store` and `GET`-only access.

The `--ephemeral` flag is what makes the `installer-XXXXXXXX` nodes auto-clean: headscale removes ephemeral nodes a few minutes after they go offline, so when the new host rebuilds into `onboarded` mode (step 7) and tailscaled re-registers under its real hostname, the installer node disappears on its own.

### Threat model

**Public ciphertext is the design.** The encrypted blob is meant to be fetchable by anyone on the internet. Security comes from the cryptographic key (the YubiKey), not from access control on the URL. This mirrors the sops trust model already used elsewhere in this fleet.

- **Compromised YubiKey + captured blobs.** Anyone with the physical YubiKey and any previously captured blob can decrypt it — but the preauth key inside is single-use, ephemeral, and expires after `keyTtl`. The window where a captured blob is useful equals the TTL.
- **Replay of a captured blob.** The preauth key inside is `--reusable=false`. Once consumed by a single `tailscale up`, headscale rejects further attempts. And the resulting node is ephemeral, so even a successful unauthorized join gets evicted automatically once the attacker stops actively presenting it.
- **DoS via blob GETs.** No per-IP rate limiting at this layer. Acceptable: the file is ~1 KB and serving a few thousand GETs/sec is well within nginx's defaults.
- **Atomic rename.** The rotator writes to a sibling tempfile in the same directory and `mv -f`s into place. A concurrent `curl` either reads the old blob fully or the new one — never a partial.
- The rotator does **not** revoke previously issued keys. Headscale auto-expires them at TTL.

## Failure modes

- **Rotator dies, blob goes stale.** Every blob on disk eventually references an expired key. Onboarding is blocked until the rotator runs again. There is no remote recovery path by design — fix it from controller's physical console. `sudo systemctl status home-network-rotate-preauth.{timer,service}` to investigate; `sudo systemctl start home-network-rotate-preauth.service` writes a fresh blob immediately. Mitigations baked in: 15-min rotation interval keeps freshness loud; the 1h TTL is longer than the rotation interval so a brief outage does not lock onboarding out.
- **YubiKey lost.** All rotated blobs become undecryptable. Stand up a replacement YubiKey, register its age public key in `nix-vault`, set `home-network.controller.yubikeyAgeRecipient` to the new value, and rebuild controller.
- **SSH session in step 3 exits early.** Just re-run `home-network-bootstrap` — it's idempotent. Steps 1 and 2 of the script (join, materialize) short-circuit; step 3 re-opens the SSH session.
- **`nixos-rebuild switch` to `onboarded` fails before completing.** The host is stuck without permanent tailnet membership. Recovery: re-run `home-network-bootstrap` to rejoin the tailnet as a new ephemeral installer node, fix the underlying issue, retry the flip.

## Notes

- `controller` mode appends to `reverse-proxy.domains` and contributes `reverse-proxy.vhosts.headscale`. The host's own `reverse-proxy` block does not need to declare these.
- `bootstrap` mode does **not** join the tailnet automatically. It runs `tailscaled` in kernel mode (so MagicDNS and `tailscale0` are wired into the system resolver) but does not configure an auth key. The operator drives the join via `home-network-bootstrap`.
- The FIDO resident SSH key stub (`~/.ssh/id_ed25519_sk_rk_nix-vault{,.pub}`) is left on disk after onboarding — it's harmless (the actual private material lives on the YubiKey, the file is a slot reference). Remove it manually if you want to, or just leave it.
- Cross-references: `modules/tailscale-client/SPEC.md`, `modules/headscale/SPEC.md`, `modules/sops/SPEC.md`.
