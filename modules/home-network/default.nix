{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.home-network;

  isController = cfg.mode == "controller";
  isBootstrap = cfg.mode == "bootstrap";
  isOnboarded = cfg.mode == "onboarded";
  isTailnetMember = isController || isOnboarded;

  preauthBlobPath = "/var/lib/home-network/preauth.age";

  bootstrapHelper = pkgs.writeShellApplication {
    name = "home-network-bootstrap";
    runtimeInputs = with pkgs; [
      age
      age-plugin-yubikey
      tailscale
      curl
      coreutils
      util-linux
      gnused
    ];
    text = ''
      blob_url="''${BLOB_URL:-${cfg.bootstrap.blobUrl}}"
      login_server="''${LOGIN_SERVER:-${cfg.bootstrap.loginServer}}"

      step() { printf '==> %s\n' "$1"; }

      work=$(mktemp -d -t home-network-bootstrap.XXXXXX)
      trap 'rm -rf "$work"' EXIT

      step "Discovering YubiKey age identity (touch the YubiKey)..."
      age-plugin-yubikey --identity > "$work/identity.age"

      step "Fetching encrypted preauth blob from $blob_url..."
      curl -fsSL "$blob_url" -o "$work/preauth.age"

      step "Decrypting blob (touch the YubiKey)..."
      age -d -i "$work/identity.age" -o "$work/preauth.key" "$work/preauth.age"

      step "Starting tailscaled in userspace-networking mode..."
      if ! pgrep -x tailscaled >/dev/null; then
        sudo tailscaled \
          --tun=userspace-networking \
          --socket=/tmp/tailscaled.sock \
          --statedir=/tmp/tailscaled-state \
          >"$work/tailscaled.log" 2>&1 &
        # Give the daemon a moment to bind its socket.
        for _ in 1 2 3 4 5 6 7 8 9 10; do
          [ -S /tmp/tailscaled.sock ] && break
          sleep 0.5
        done
      fi

      step "Joining tailnet (login server $login_server)..."
      hostname="installer-$(uuidgen | tr -d - | head -c8)"
      sudo tailscale --socket=/tmp/tailscaled.sock up \
        --login-server "$login_server" \
        --authkey "$(cat "$work/preauth.key")" \
        --hostname "$hostname"

      step "Tailnet status:"
      sudo tailscale --socket=/tmp/tailscaled.sock status

      echo
      echo "Done. The installer is now a tailnet member as '$hostname'."
      echo "Continue with the enrollment runbook in modules/home-network/SPEC.md."
    '';
  };
in
{
  options.home-network = {
    enable = mkEnableOption ''
      Membership of the home tailnet. Wraps headscale (controller mode),
      tailscale client, SSH-on-tailscale0 firewall + authorized_keys, and
      onboarding tooling under a single `mode` switch.
    '';

    mode = mkOption {
      type = types.enum [ "controller" "bootstrap" "onboarded" ];
      description = ''
        Which side of the home tailnet this host represents.

        - `controller`: runs the headscale coordinator + the rotated, age-encrypted
          preauth-key endpoint that new hosts pull from during onboarding. Also
          a regular tailnet member itself.
        - `bootstrap`: not on the tailnet yet. Provides the tools and the
          `home-network-bootstrap` helper script so the operator can fetch the
          encrypted blob, decrypt it with the YubiKey, and join. Used during
          first-pass install of a new host; flipped to `onboarded` once
          enrollment in `nix-vault` is complete.
        - `onboarded`: steady-state tailnet member. Tailscale client auto-joins
          via a sops-decrypted per-host preauth key, sshd listens only on
          `tailscale0`.

        No default — must be explicit so a typo cannot silently land a host in
        the wrong state.
      '';
    };

    authorizeSshFor = mkOption {
      type = types.attrsOf (types.listOf (types.submodule {
        options = {
          host = mkOption {
            type = types.str;
            description = "Tailnet host name (must be a key in flake.lib.hosts).";
          };
          user = mkOption {
            type = types.str;
            description = "Username on the peer host whose SSH keys to authorize.";
          };
        };
      }));
      default = { };
      description = ''
        Map of local user → list of `{host, user}` peer identities. All SSH
        pubkeys under `lib.hosts.<host>.ssh.users.<user>.*` are added to that
        local user's `authorized_keys`. Only honoured in `controller` and
        `onboarded` modes.
      '';
    };

    bootstrap = {
      blobUrl = mkOption {
        type = types.str;
        default = "https://rydback.net/.well-known/tailnet-bootstrap.age";
        description = ''
          Public URL of the age-encrypted preauth blob served by the controller.
          The default matches the controller's `home-network.controller.bootstrap`
          settings; override only if you've moved the endpoint.
        '';
      };

      loginServer = mkOption {
        type = types.str;
        default = "https://vpn.rydback.net";
        description = "Headscale control-server URL passed to `tailscale up`.";
      };
    };

    controller = {
      yubikeyAgeRecipient = mkOption {
        type = types.str;
        default = "";
        example = "age1yubikey1q...";
        description = ''
          Public age recipient for the operator's YubiKey. The same identity used
          for sops. Used only in `controller` mode to encrypt the rotated preauth
          blob.
        '';
      };

      headscaleUser = mkOption {
        type = types.str;
        default = "";
        example = "birger";
        description = "Headscale user the rotated preauth keys are scoped to.";
      };

      headscale = {
        domain = mkOption {
          type = types.str;
          default = "";
          example = "vpn.rydback.net";
          description = "Public domain headscale is served under (proxied by nginx).";
        };
        baseDomain = mkOption {
          type = types.str;
          default = "";
          example = "ts.rydback.net";
          description = "MagicDNS base domain. MUST differ from `domain`.";
        };
        users = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Headscale users to provision idempotently on startup.";
        };
        extraDnsRecords = mkOption {
          type = types.listOf (types.submodule {
            options = {
              name = mkOption { type = types.str; };
              type = mkOption { type = types.str; default = "A"; };
              value = mkOption { type = types.str; };
            };
          });
          default = [ ];
          description = "Extra DNS records pushed to tailnet clients via MagicDNS.";
        };
      };

      bootstrap = {
        publicDomain = mkOption {
          type = types.str;
          default = "rydback.net";
          description = ''
            Existing reverse-proxy domain the encrypted preauth blob is served
            from. Must already (or via this module) be present in
            `reverse-proxy.domains` so ACME issues a cert for it.
          '';
        };
        urlPath = mkOption {
          type = types.str;
          default = "/.well-known/tailnet-bootstrap.age";
          description = "Path under `publicDomain` where the blob is served.";
        };
        rotateInterval = mkOption {
          type = types.str;
          default = "15min";
          description = "How often a fresh preauth blob is generated.";
        };
        keyTtl = mkOption {
          type = types.str;
          default = "1h";
          description = "TTL of each issued preauth key.";
        };
      };
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable && isTailnetMember) {
      # Delegate the actual SSH-on-tailscale0 + firewall + authorized_keys +
      # tailscale-client wiring to the existing `tailnet` module. `home-network`
      # is the host-facing aggregator; `tailnet` remains the low-level
      # building block.
      tailnet = {
        enable = true;
        inherit (cfg) authorizeSshFor;
      };
    })

    (mkIf (cfg.enable && isController) {
      assertions = [
        {
          assertion = cfg.controller.yubikeyAgeRecipient != "";
          message = "home-network.mode = \"controller\" requires controller.yubikeyAgeRecipient.";
        }
        {
          assertion = cfg.controller.headscaleUser != "";
          message = "home-network.mode = \"controller\" requires controller.headscaleUser.";
        }
        {
          assertion = cfg.controller.headscale.domain != "" && cfg.controller.headscale.baseDomain != "";
          message = "home-network.mode = \"controller\" requires controller.headscale.{domain,baseDomain}.";
        }
      ];

      headscale = {
        enable = true;
        inherit (cfg.controller.headscale) domain baseDomain users extraDnsRecords;
      };

      # Server-side bootstrap rotator: every `rotateInterval`, mint a fresh
      # single-use preauth key from headscale, age-encrypt it to the operator's
      # YubiKey recipient, atomically write it to a path served publicly by
      # nginx. The new host's installer fetches the blob, decrypts with the
      # YubiKey, and uses the key to join the tailnet. Ciphertext is safe to
      # leak — security comes from the YubiKey, not access control.
      systemd.tmpfiles.rules = [
        "d /var/lib/home-network 0755 root root -"
      ];

      systemd.services.home-network-rotate-preauth = {
        description = "Rotate the age-encrypted headscale preauth key for tailnet onboarding";
        after = [ "headscale.service" "headscale-provision-users.service" ];
        requires = [ "headscale.service" ];
        wants = [ "headscale-provision-users.service" ];
        path = [
          pkgs.headscale
          pkgs.age
          # `age` invokes the plugin binary by name to interpret an
          # `age1yubikey1…` recipient string at encrypt time — no YubiKey needs
          # to be inserted, but the plugin must be on PATH.
          pkgs.age-plugin-yubikey
          pkgs.jq
          pkgs.coreutils
        ];
        serviceConfig = {
          Type = "oneshot";
          UMask = "0022";
        };
        script = ''
          set -euo pipefail

          # Newer headscale wants a numeric user ID, not a name. Resolve by name.
          uid=$(headscale users list --output json \
                | jq -r --arg n ${escapeShellArg cfg.controller.headscaleUser} \
                    'first(.[] | select(.name == $n) | .id) // empty')
          if [ -z "$uid" ]; then
            echo "headscale user '${cfg.controller.headscaleUser}' not found" >&2
            exit 1
          fi

          key=$(headscale preauthkeys create \
                  --user "$uid" \
                  --expiration ${escapeShellArg cfg.controller.bootstrap.keyTtl} \
                  --output json \
                | jq -r .key)

          tmp=$(mktemp /var/lib/home-network/preauth.age.XXXXXX)
          trap 'rm -f "$tmp"' EXIT
          printf '%s' "$key" \
            | age -r ${escapeShellArg cfg.controller.yubikeyAgeRecipient} -o "$tmp"
          chmod 0644 "$tmp"
          mv -f "$tmp" ${preauthBlobPath}
          trap - EXIT
        '';
      };

      systemd.timers.home-network-rotate-preauth = {
        description = "Rotate the tailnet onboarding preauth blob";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "30s";
          OnUnitActiveSec = cfg.controller.bootstrap.rotateInterval;
          Unit = "home-network-rotate-preauth.service";
          AccuracySec = "10s";
        };
      };

      reverse-proxy = {
        domains = [
          cfg.controller.headscale.domain
          cfg.controller.bootstrap.publicDomain
        ];
        vhosts.headscale = {
          domain = cfg.controller.headscale.domain;
          upstream = "http://127.0.0.1:8080";
        };
      };

      # Exact-match location (`= /path`) — gixy rejects `alias` under a prefix
      # location because nginx can synthesize traversal paths off the end of a
      # prefix. Exact match makes it apply to this single file only.
      services.nginx.virtualHosts.${cfg.controller.bootstrap.publicDomain}.locations."= ${cfg.controller.bootstrap.urlPath}" = {
        alias = preauthBlobPath;
        extraConfig = ''
          default_type application/octet-stream;
          add_header Cache-Control "no-store";
          limit_except GET { deny all; }
        '';
      };
    })

    (mkIf (cfg.enable && isBootstrap) {
      environment.systemPackages = with pkgs; [
        age
        age-plugin-yubikey
        tailscale
        curl
        openssh
        git
        ssh-to-age
        sops
        jq
        util-linux
        bootstrapHelper
      ];

      # PC/SC daemon for smartcard access — needed for age-plugin-yubikey to
      # talk to the inserted YubiKey during the bootstrap helper run.
      services.pcscd.enable = true;
    })
  ];
}
