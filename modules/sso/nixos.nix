{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.my.sso;
  selfLib = inputs.self.lib;
  vault = "${inputs.nix-vault}/secrets/common.yaml";

  # Kanidm listens on loopback with the same Let's Encrypt cert nginx serves
  # (it refuses plain HTTP, even from a proxy)
  bind = "127.0.0.1:${toString cfg.port}";
  certDir = config.security.acme.certs.${cfg.domain}.directory;

  clientModule =
    { name, ... }:
    {
      options = {
        displayName = mkOption {
          type = types.str;
          default = name;
          description = "Name shown on Kanidm's application page.";
        };
        redirectUrls = mkOption {
          type = types.listOf types.str;
          example = [ "https://cloud.example.com/apps/user_oidc/code" ];
          description = "The service's OAuth2 callback URLs. Must match exactly.";
        };
        landing = mkOption {
          type = types.str;
          example = "https://cloud.example.com/";
          description = "Where Kanidm's application page sends the user.";
        };
        scopes = mkOption {
          type = types.listOf types.str;
          default = [
            "openid"
            "profile"
            "email"
          ];
          description = "Scopes every member of `sso_users` gets for this client.";
        };
        supplementaryScopes = mkOption {
          type = types.listOf types.str;
          default = [ "groups" ];
          description = "Scopes handed to the service without being required for login.";
        };
        disablePkce = mkOption {
          type = types.bool;
          default = false;
          description = "For clients that cannot do PKCE. Ask upstream to fix it first.";
        };
        legacyCrypto = mkOption {
          type = types.bool;
          default = false;
          description = "Sign tokens with RS256 for clients that cannot verify ES256.";
        };
        secretFile = mkOption {
          type = types.str;
          default = config.sops.secrets."sso-client-${name}".path;
          defaultText = literalExpression ''config.sops.secrets."sso-client-<name>".path'';
          description = ''
            File holding the client secret. By default decrypted from the vault's
            `common.yaml` at `sso/clients/<name>` (shared with the host that runs
            the service, which reads the same key).
          '';
        };
        settings = mkOption {
          type = types.attrs;
          default = { };
          description = "Extra `services.kanidm.provision.systems.oauth2.<name>` settings, e.g. `claimMaps`.";
        };
      };
    };
in
{
  options.my.sso = {
    enable = mkEnableOption "Kanidm, the identity provider every self-hosted service logs in through";

    domain = mkOption {
      type = types.str;
      default = "id.${selfLib.domain}";
      defaultText = literalExpression ''"id.''${lib.domain}"'';
      description = ''
        Kanidm's hostname and WebAuthn relying-party id. Changing it later
        breaks every registered passkey, so pick it once.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 8443;
      description = "Loopback port Kanidm listens on; nginx proxies the domain to it.";
    };

    tailnetOnly = mkOption {
      type = types.bool;
      default = true;
      description = "Only tailnet sources may reach the vhost (ACME challenges excepted).";
    };

    persons = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            displayName = mkOption { type = types.str; };
            mail = mkOption { type = types.str; };
            groups = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Extra Kanidm groups besides `sso_users`.";
            };
          };
        }
      );
      default = { };
      description = ''
        People who can log in, keyed by login name. The operator from
        `lib/default.nix` is always present; consumer modules add their role
        groups to a person with `my.sso.persons.<login>.groups`.
      '';
    };

    groups = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "grafana_admins" ];
      description = ''
        Role groups to create besides `sso_users`. Membership is declared on
        the person (`persons.<login>.groups`); a client maps the group to a
        claim with `clients.<id>.settings.claimMaps`.
      '';
    };

    admins = mkOption {
      type = types.listOf types.str;
      default = [ selfLib.operator.login ];
      defaultText = literalExpression "[ lib.operator.login ]";
      description = "Persons added to Kanidm's built-in `idm_admins` group.";
    };

    clients = mkOption {
      type = types.attrsOf (types.submodule clientModule);
      default = { };
      description = "OAuth2/OIDC clients, keyed by client id.";
    };

    adminPasswordFile = mkOption {
      type = types.str;
      default = config.sops.secrets."sso-admin-password".path;
      defaultText = literalExpression ''config.sops.secrets."sso-admin-password".path'';
      description = "Password of Kanidm's `admin` (server admin). Vault key `services/sso/admin-password`.";
    };

    idmAdminPasswordFile = mkOption {
      type = types.str;
      default = config.sops.secrets."sso-idm-admin-password".path;
      defaultText = literalExpression ''config.sops.secrets."sso-idm-admin-password".path'';
      description = "Password of `idm_admin` (people and groups). Vault key `services/sso/idm-admin-password`.";
    };

    backupDir = mkOption {
      type = types.str;
      default = "/var/backups/kanidm";
      description = ''
        Kanidm's own nightly database snapshots (01:00, 7 kept). Back this up,
        not the live database.
      '';
    };

    issuerFor = mkOption {
      type = types.functionTo types.str;
      readOnly = true;
      default = client: "https://${cfg.domain}/oauth2/openid/${client}";
      description = "The OIDC issuer URL of a client; discovery is at `<issuer>/.well-known/openid-configuration`.";
    };
  };

  config = mkIf cfg.enable {
    # Defined here rather than as the option default so that other modules
    # can add to the operator (e.g. role groups) without replacing the entry
    my.sso.persons.${selfLib.operator.login} = {
      displayName = mkDefault selfLib.operator.displayName;
      mail = mkDefault selfLib.operator.email;
    };

    assertions = [
      {
        assertion = config.my.reverse-proxy.enable;
        message = "my.sso needs my.reverse-proxy for the ${cfg.domain} vhost and its certificate";
      }
      {
        assertion = config.my.sops.enable;
        message = "my.sso reads its passwords and client secrets from the vault, but my.sops is off";
      }
    ];

    services.kanidm = {
      server.enable = true;
      client.enable = true;
      # Pinned major; secret provisioning is what lets passwords and client
      # secrets come from files. Bump when nixpkgs marks the major insecure (EOL)
      package = pkgs.kanidmWithSecretProvisioning_1_11;

      server.settings = {
        inherit (cfg) domain;
        origin = "https://${cfg.domain}";
        bindaddress = bind;
        tls_chain = "${certDir}/fullchain.pem";
        tls_key = "${certDir}/key.pem";
        # nginx on this host sets X-Forwarded-For; trust it from loopback only
        http_client_address_info.x-forward-for = [
          "127.0.0.1"
          "::1"
        ];
        online_backup = {
          path = cfg.backupDir;
          schedule = "00 01 * * *";
          versions = 7;
        };
      };

      client.settings.uri = "https://${cfg.domain}";

      provision = {
        enable = true;
        inherit (cfg) adminPasswordFile idmAdminPasswordFile;

        groups = {
          # Membership comes from each person's `groups` (the module derives
          # `members` from them); the group only has to exist
          sso_users = { };
          # Built-in: add to it, never overwrite. Overwriting removes
          # `idm_admin` itself and the rest of the provisioning run fails with
          # Kanidm's "no matching entries" for the lost permission
          idm_admins = {
            members = cfg.admins;
            overwriteMembers = false;
          };
        }
        // genAttrs cfg.groups (_: { });

        persons = mapAttrs (_: p: {
          inherit (p) displayName;
          mailAddresses = [ p.mail ];
          groups = [ "sso_users" ] ++ p.groups;
        }) cfg.persons;

        systems.oauth2 = mapAttrs (
          _: c:
          {
            inherit (c) displayName;
            originUrl = c.redirectUrls;
            originLanding = c.landing;
            basicSecretFile = c.secretFile;
            preferShortUsername = true;
            scopeMaps.sso_users = c.scopes;
            supplementaryScopeMaps.sso_users = c.supplementaryScopes;
            allowInsecureClientDisablePkce = c.disablePkce;
            enableLegacyCrypto = c.legacyCrypto;
          }
          // c.settings
        ) cfg.clients;
      };
    };

    # Kanidm reloads its certificate on SIGHUP; ACME renewals reload nginx
    # and kanidm alike
    systemd.services.kanidm.serviceConfig.ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
    security.acme.certs.${cfg.domain} = {
      group = "kanidm";
      reloadServices = [ "kanidm.service" ];
    };
    # The vhost's cert now belongs to the kanidm group; nginx still has to read it
    users.users.nginx.extraGroups = [ "kanidm" ];

    my.reverse-proxy = {
      domains = [ cfg.domain ];
      vhosts.sso = {
        inherit (cfg) domain;
        upstream = "https://${bind}";
        extraConfig = mkIf cfg.tailnetOnly (selfLib.tailnet.nginxAllowOnly [ ]);
      };
    };

    sops.secrets = {
      "sso-admin-password" = {
        key = "services/sso/admin-password";
        owner = "kanidm";
        mode = "0400";
      };
      "sso-idm-admin-password" = {
        key = "services/sso/idm-admin-password";
        owner = "kanidm";
        mode = "0400";
      };
    }
    // optionalAttrs (builtins.pathExists vault) (
      mapAttrs' (
        name: _:
        nameValuePair "sso-client-${name}" {
          sopsFile = vault;
          key = "sso/clients/${name}";
          owner = "kanidm";
          mode = "0400";
        }
      ) cfg.clients
    );
  };
}
