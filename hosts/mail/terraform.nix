{ lib, inputs, ... }:

# Hetzner Cloud resources for the mail VPS, declared via terranix.
#
# Generated `config.tf.json` is consumed by OpenTofu:
#   nix build .#terraform-mail
#   ln -sf result hosts/mail/config.tf.json
#   cd hosts/mail && tofu init && tofu plan
#
# The Hetzner API token is supplied at plan/apply time via the environment:
#   export TF_VAR_hcloud_token=$(sops -d ../../secrets/hcloud_token | tr -d '\n')
# (Once secrets are wired up in Step 3. During scaffold/manual testing, paste
# the token from the password manager into TF_VAR_hcloud_token directly.)

let
  # Values that are referenced from both Terraform and NixOS sides should live
  # here. When the NixOS host needs them too, lift them into hosts/mail/shared.nix
  # and import from both — for now Stalwart isn't wired up so they're terraform-only.
  hostname = "mail.rydback.net";
  serverName = "mail";

  # fsn1 = Falkenstein, Germany (default). hel1 = Helsinki, Finland. nbg1 =
  # Nuremberg. Pick whichever has clean IPv4 reputation when provisioning; can
  # be changed before first `tofu apply`.
  location = "fsn1";

  # CX22: 2 vCPU, 4 GB RAM, 40 GB disk, ~€4/mo. Adequate for personal mail
  # volume with room to grow. Resize is non-destructive on Hetzner.
  serverType = "cx22";

  # Boot image. The actual OS is replaced by NixOS via nixos-anywhere on first
  # SSH; this image only needs to boot long enough to accept the kexec.
  image = "debian-12";

  # The SSH key that nixos-anywhere will use to ssh in for the initial install.
  # Same key used for ongoing nixos-rebuild --target-host afterwards.
  operatorSshKey = inputs.self.lib.hosts.bits.ssh.users.birgerrydback.bits;

  # Inbound ports allowed by the Hetzner cloud firewall. Must stay in sync
  # with hosts/mail/system.nix `firewall.tcpPorts`.
  inboundTcpPorts = [
    22
    25
    80
    443
    465
    587
    993
  ];

  inboundRule = port: {
    direction = "in";
    protocol = "tcp";
    port = toString port;
    source_ips = [
      "0.0.0.0/0"
      "::/0"
    ];
  };
in
{
  terraform = {
    required_version = ">= 1.6";
    required_providers.hcloud = {
      source = "hetznercloud/hcloud";
      version = "~> 1.50";
    };
  };

  variable.hcloud_token = {
    type = "string";
    sensitive = true;
    description = "Hetzner Cloud API token (project-scoped, read+write).";
  };

  provider.hcloud = {
    token = "\${var.hcloud_token}";
  };

  resource = {
    hcloud_ssh_key.operator = {
      name = "birgerrydback-bits";
      public_key = operatorSshKey;
    };

    hcloud_firewall.mail = {
      name = "mail";
      rule = map inboundRule inboundTcpPorts;
    };

    hcloud_server.mail = {
      name = serverName;
      server_type = serverType;
      image = image;
      location = location;
      ssh_keys = [ "\${hcloud_ssh_key.operator.id}" ];
      firewall_ids = [ "\${hcloud_firewall.mail.id}" ];
      labels.role = "mail";
    };

    hcloud_rdns.mail_v4 = {
      server_id = "\${hcloud_server.mail.id}";
      ip_address = "\${hcloud_server.mail.ipv4_address}";
      dns_ptr = hostname;
    };

    hcloud_rdns.mail_v6 = {
      server_id = "\${hcloud_server.mail.id}";
      ip_address = "\${hcloud_server.mail.ipv6_address}";
      dns_ptr = hostname;
    };
  };

  output = {
    server_ipv4.value = "\${hcloud_server.mail.ipv4_address}";
    server_ipv6.value = "\${hcloud_server.mail.ipv6_address}";
    server_status.value = "\${hcloud_server.mail.status}";
  };
}
