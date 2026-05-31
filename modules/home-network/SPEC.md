# Home Network

The single first-class module every host opts into to join the home tailnet. Bundles the headscale coordinator (controller side), the tailscale client + SSH-on-`tailscale0` (every member), and the bootstrap tooling new hosts use to join the tailnet for the very first time.

This is **the primary onboarding document** for the fleet. The bootstrapping doctrine — runbook humans follow + configuration surface the fleet exposes — lives here.

## Why this module exists

`controller` exposes port 22 only on `tailscale0`. That creates a chicken-and-egg for new hosts: they cannot reach `controller` to clone `nix-vault` until they are on the tailnet, but the preauth key that gets them onto the tailnet lives in `nix-vault` (encrypted to the new host's age identity, which is itself derived from a key that does not exist yet).

The module breaks the cycle by having controller publish a continuously rotated, single-use, short-TTL preauth key — age-encrypted to the operator's YubiKey — at a public HTTPS path. A new host's installer fetches the blob, decrypts it locally with the inserted YubiKey, and joins the tailnet on its own. Port 22 stays tailnet-only. No preexisting tailnet member is required to onboard a new one — only the YubiKey and `controller` being up.

The trust model mirrors the sops material already checked into `nix-vault`: ciphertext is publicly readable; security comes from the YubiKey, not from access control.

## Modes

Exactly one mode applies per host. Set `home-network.mode` explicitly — there is no default, so a typo cannot silently land a host in the wrong state.

| Mode | What it wires up | When it applies |
|------|------------------|-----------------|
| `controller` | headscale + DERP + preauth-key rotator + tailscale client + SSH-on-`tailscale0` + reverse-proxy contributions | The single coordinator host (`controller`) |
| `bootstrap` | Bootstrap tooling (`age`, `age-plugin-yubikey`, `tailscale`, `curl`, `git`, `ssh-to-age`, `sops`) + the `home-network-bootstrap` helper script + pcscd | A new host on its first install pass, before it has been registered in `nix-vault` |
| `onboarded` | tailscale client (sops-decrypted authkey) + SSH-on-`tailscale0` + `authorizeSshFor` peer keys | Steady state for every member after enrollment |

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Master switch |
| `mode` | enum | (required) | `controller` \| `bootstrap` \| `onboarded` |
| `authorizeSshFor` | attrs | `{ }` | Map `local-user → [{host, user}]`; pulls peer SSH keys from `lib.hosts` into `authorized_keys`. Honoured in `controller`/`onboarded` only. |
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

These are the steps from "I just unboxed a new machine" to "the host is a steady-state tailnet member". Works for both **same-site** (new machine on the home LAN) and **remote** (new machine at a different physical site, operator physically present with the YubiKey) onboardings. The only inputs are the YubiKey and the new host's installer.

### Step 1 — Declare the host in `nix-home` (bootstrap mode)

Add a `hosts/<new-host>/` skeleton and set:

```nix
home-network = {
  enable = true;
  mode = "bootstrap";
};
```

Do not enable `sops-secrets` yet — the host has no age identity to decrypt against. Commit. (You can do this on any machine; you do not need to push.)

### Step 2 — Boot the standard NixOS installer

Boot the new host from a vanilla NixOS installer USB. Bring up networking (DHCP is fine). Insert the YubiKey.

### Step 3 — Get the installer onto the tailnet

The `home-network-bootstrap` helper is what the installed system *will* have under `mode = "bootstrap"`, but the live installer doesn't have it yet. Run the equivalent steps directly:

```bash
nix-shell -p age age-plugin-yubikey tailscale curl util-linux

# Discover YubiKey age identity (touch the YubiKey).
age-plugin-yubikey --identity > /tmp/yk-identity.txt

# Fetch and decrypt the rotated preauth blob (touch the YubiKey again on decrypt).
curl -fsSL https://rydback.net/.well-known/tailnet-bootstrap.age -o /tmp/bs.age
age -d -i /tmp/yk-identity.txt /tmp/bs.age > /tmp/authkey

# Start tailscaled in userspace-networking mode (no /dev/net/tun on the installer).
sudo tailscaled --tun=userspace-networking --socket=/tmp/tailscaled.sock --statedir=/tmp/ts-state &
sleep 2

# Join the tailnet.
sudo tailscale --socket=/tmp/tailscaled.sock up \
  --login-server https://vpn.rydback.net \
  --authkey "$(cat /tmp/authkey)" \
  --hostname "installer-$(uuidgen | tr -d - | head -c8)"
```

Verify:

```bash
sudo tailscale --socket=/tmp/tailscaled.sock status
ssh -o StrictHostKeyChecking=accept-new betongsuggan@controller   # should succeed (YubiKey touch)
```

### Step 4 — Run the existing enrollment dance over the tailnet

You are now a tailnet peer. From here, the enrollment is the existing `nix-vault` workflow:

```bash
# Materialize the YubiKey FIDO resident key for SSH.
ssh-keygen -K
eval "$(ssh-agent)"
ssh-add ~/.ssh/id_ed25519_sk_bootstrap

# Clone repos. Both reachable via MagicDNS.
git clone https://github.com/<you>/nix-home   # public, no auth
git clone git@controller:nix-vault.git        # YubiKey-authed over tailnet

# Generate the host's permanent SSH host key.
sudo ssh-keygen -A

# Register the host's age recipient in nix-vault.
cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
# Edit nix-vault/.sops.yaml to add the new recipient under creation_rules
# for secrets/<new-host>.yaml. Then:
cd nix-vault
sops updatekeys secrets/<new-host>.yaml   # if file exists
sops secrets/<new-host>.yaml              # create or edit; add `services/headscale-preauthkey`
git commit -am "add <new-host>"
git push

# Install with the local nix-vault checkout, since the host's key isn't yet
# authorized on controller's git-server.
sudo nixos-install --flake /path/to/nix-home#<new-host> \
                   --override-input nix-vault path:/path/to/nix-vault
```

The preauth key inside `secrets/<new-host>.yaml` is generated once via `sudo headscale preauthkeys create -u <user> --reusable -e 8760h` on controller and pasted into the encrypted YAML. This is the *steady-state* preauth key, distinct from the rotated bootstrap blob.

### Step 5 — Flip the host to `onboarded` and rebuild

Back in `nix-home`:

```nix
home-network = {
  enable = true;
  mode = "onboarded";
};

sops-secrets = {
  enable = true;
  secretsFile = "${inputs.nix-vault}/secrets/<new-host>.yaml";
};
```

Commit, push, and on the new host:

```bash
sudo nixos-rebuild switch --flake .#<new-host>
```

The new host now joins the tailnet under its own identity using the sops-decrypted preauth key. The installer's ephemeral `installer-XXXXXXXX` node expires after the bootstrap blob's 1h TTL, or force-expire it from controller:

```bash
sudo headscale nodes list
sudo headscale nodes expire -i <node-id>
```

## Server-side rotator (controller mode)

What `controller` mode wires up in addition to regular tailnet membership:

- `systemd.services.home-network-rotate-preauth` (oneshot): runs `headscale preauthkeys create --user <headscaleUser> --expiration <keyTtl> --output json`, pipes the result through `jq -r .key`, then through `age -r <yubikeyAgeRecipient>`, and atomically renames the output to `/var/lib/home-network/preauth.age` (0644, root).
- `systemd.timers.home-network-rotate-preauth`: triggers the rotator every `controller.bootstrap.rotateInterval` (default 15 min), plus 30s after boot.
- Adds a `location` block to the existing nginx virtual host named by `controller.bootstrap.publicDomain` (default `rydback.net`) that serves the blob over HTTPS as `application/octet-stream` with `Cache-Control: no-store` and `GET`-only access.

### Threat model

**Public ciphertext is the design.** The encrypted blob is meant to be fetchable by anyone on the internet. Security comes from the cryptographic key (the YubiKey), not from access control on the URL. This mirrors the sops trust model already used elsewhere in this fleet.

- **Compromised YubiKey + captured blobs.** Anyone with the physical YubiKey and any previously captured blob can decrypt it — but the preauth key inside is single-use and expires after `keyTtl`. The window where a captured blob is useful equals the TTL. By the time a YubiKey is reported lost, every captured blob's plaintext is already expired or burned.
- **Replay of a captured blob.** The preauth key inside is `--reusable=false`. Once consumed by a single `tailscale up`, headscale rejects further attempts.
- **DoS via blob GETs.** No per-IP rate limiting at this layer. Acceptable: the file is ~1 KB and serving a few thousand GETs/sec is well within nginx's defaults.
- **Atomic rename.** The rotator writes to a sibling tempfile in the same directory and `mv -f`s into place. A concurrent `curl` either reads the old blob fully or the new one — never a partial.
- The rotator does **not** revoke previously issued keys. Headscale auto-expires them at TTL.

## Failure modes

- **Rotator dies, blob goes stale.** Every blob on disk eventually references an expired key. Onboarding is blocked until the rotator runs again. There is no remote recovery path by design — fix it from controller's physical console. `sudo systemctl status home-network-rotate-preauth.{timer,service}` to investigate; `sudo systemctl start home-network-rotate-preauth.service` writes a fresh blob immediately. Mitigations baked in: 15-min rotation interval keeps freshness loud; the 1h TTL is intentionally longer than the rotation interval so a brief outage does not lock onboarding out.
- **YubiKey lost.** All rotated blobs become undecryptable. Stand up a replacement YubiKey, register its age public key in `nix-vault`, set `home-network.controller.yubikeyAgeRecipient` to the new value, and rebuild controller.
- **`nixos-rebuild switch` to `onboarded` fails before completing.** The new host is stuck without tailnet membership. Recovery: re-run Step 3 from the installer (or from a rescue shell) to rejoin the tailnet temporarily, fix the underlying issue, retry the flip.
- **Installer node clutters headscale.** Bounded by the 1h TTL. Run `sudo headscale nodes expire …` from any tailnet member to clean up sooner.

## Notes

- `controller` mode appends to `reverse-proxy.domains` and contributes `reverse-proxy.vhosts.headscale`. The host's own `reverse-proxy` block does not need to declare these.
- `bootstrap` mode does **not** join the tailnet automatically. It only installs tools. The operator drives the join via the helper script.
- The `home-network-bootstrap` helper is generated by `pkgs.writeShellApplication`, so it is available as a normal executable on hosts built in `bootstrap` mode. The live-installer flow shown above runs the same commands directly because the installer doesn't have the helper.
- Cross-references: `modules/tailscale-client/SPEC.md`, `modules/headscale/SPEC.md`, `modules/sops/SPEC.md`.
