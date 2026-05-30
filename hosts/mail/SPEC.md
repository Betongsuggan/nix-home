# Mail

Headless Hetzner Cloud VPS hosting the self-hosted email trial for `rydback.net` (Option A in `de-googling.md`). The host's job is to be the receiving and sending MTA for `@rydback.net` addresses, run in parallel with Gmail until the documented cutover criterion is met.

## Status

**Scaffold only.** Files exist, flake evaluates, nothing is deployed. Bringing this online is tracked in `de-googling.md` Phase 2.

## Provider & shape

- **Hetzner Cloud**, CX22 in Falkenstein (Germany) or Helsinki (Finland) — EU jurisdiction, ~€4/mo.
- **Cloud resources declared in `terraform.nix`** via [terranix](https://github.com/terranix/terranix): server, firewall, rDNS, SSH key. Generated `config.tf.json` is consumed by OpenTofu.
- **DNS records managed manually in AWS Route 53** during the trial. Route-53-as-code is deferred until the trial proves Option A is viable; see `de-googling.md`.
- **OS installed via [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)** over SSH on the freshly-provisioned VM. Disk layout declared via [disko](https://github.com/nix-community/disko) in `hardware.nix`.

## Co-location rationale

Everything for this host — NixOS config, disk layout, cloud infrastructure — lives in this directory rather than being split into a top-level `infra/` tree. Reason: ~6 values (hostname, public IPv4/IPv6, ACME email, mail domain) appear in both the Terraform side (rDNS, DNS) and the NixOS side (Stalwart config, ACME, HELO). Single source of truth in Nix beats keeping them in sync across two trees.

## Workflow (once filled in)

```sh
# Generate Terraform config from terranix
nix build .#terraform-mail
ln -sf result hosts/mail/config.tf.json

# Apply infrastructure
cd hosts/mail
tofu init
tofu plan
tofu apply

# Install NixOS over SSH (first time)
nixos-anywhere --flake .#mail root@<server-ip>

# Subsequent updates
nixos-rebuild switch --flake .#mail --target-host root@mail.rydback.net
```

## Open TODOs (filled in as we progress through the steps)

- [ ] `terraform.nix`: wire Hetzner API token from sops or env.
- [ ] `terraform.nix`: confirm location (`fsn1` vs `hel1`) and server type after Hetzner port-25 unblock.
- [ ] `system.nix`: enable `tailscale-client` once mail host is enrolled on the headscale tailnet.
- [ ] `system.nix`: enable Stalwart with real domain config and DKIM key sourcing.
- [ ] `system.nix`: enable `reverse-proxy` for ACME certs (HTTP-01 on 80/443) — Stalwart consumes the resulting cert.
- [ ] `system.nix`: enable sops, point at `nix-vault/secrets/mail.yaml`.
- [ ] `nix-vault/keys.nix`: add this host's `/etc/ssh/ssh_host_ed25519_key.pub` once provisioned.
- [ ] Route 53: A/AAAA/MX/SPF/DKIM/DMARC/MTA-STS/TLS-RPT records (manual for trial phase).
- [ ] Tighten SSH to tailnet-only after tailscale is up (currently public, key-only).

## Cutover criterion (per `de-googling.md`)

Two weeks of clean delivery to Gmail / Outlook / Fastmail recipients with no spam-foldering, before any real account changes email-of-record from Gmail to `@rydback.net`. If the trial fails on deliverability or babysitting cost, fallback path is Proton with `rydback.net` MX repointed — see `de-googling.md`.
