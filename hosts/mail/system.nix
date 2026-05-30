{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  system.stateVersion = "25.11";

  networking.hostName = "mail";

  time.timeZone = "Europe/Stockholm";
  i18n.defaultLocale = "en_GB.UTF-8";

  users.users.betongsuggan = {
    isNormalUser = true;
    description = "Birger Rydback";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # Daily-driver identity: birgerrydback@bits. Used to SSH in from the
      # laptop for nixos-rebuild and inspection. Once tailscale is up on this
      # host, SSH should be restricted to the tailnet interface.
      inputs.self.lib.hosts.bits.ssh.users.birgerrydback.bits
    ];
  };

  # Wheel group can sudo without re-typing password — pragmatic for a single
  # operator over SSH; protected by SSH key + sudo prompt.
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [ home-manager ];

  openssh = {
    enable = true;
    openFirewall = true;
    permitRootLogin = "prohibit-password";
    passwordAuthentication = false;
  };

  firewall = {
    enable = true;
    tcpPorts = [
      22 # SSH (TODO: restrict to tailnet interface once enrolled)
      25 # SMTP inbound (MX-to-MX)
      80 # HTTP — ACME HTTP-01 challenge
      443 # HTTPS — Stalwart admin UI + future reverse-proxied services
      465 # SMTPS submission
      587 # SMTP submission (STARTTLS)
      993 # IMAPS
    ];
    udpPorts = [ ];
  };

  # TODO (Step 3): enroll in tailnet — requires `headscale-preauthkey` in
  # nix-vault/secrets/mail.yaml.
  #
  # tailscale-client = {
  #   enable = true;
  #   loginServer = "https://vpn.rydback.net";
  #   authKeyFile = config.sops.secrets."headscale-preauthkey".path;
  #   extraUpFlags = [ "--accept-routes" ];
  # };

  # TODO (Step 3): enable sops once host SSH key is registered as an age
  # recipient in nix-vault/.sops.yaml.
  #
  # sops-secrets = {
  #   enable = true;
  #   secretsFile = "${inputs.nix-vault}/secrets/mail.yaml";
  # };

  # TODO (Step 4): Stalwart + ACME. Stalwart consumes the cert produced by the
  # reverse-proxy module (or directly via security.acme), reading it from
  # /var/lib/acme/mail.rydback.net/{fullchain,key}.pem.
  #
  # services.stalwart-mail = {
  #   enable = true;
  #   openFirewall = false; # firewall module above already opens 25/465/587/993
  #   settings = { ... };
  # };
  #
  # reverse-proxy = {
  #   enable = true;
  #   acmeEmail = "rydback@gmail.com";
  #   domains = [ "mail.rydback.net" ];
  # };
}
