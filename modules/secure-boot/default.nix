{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.secure-boot = {
    enable = mkEnableOption "Enable Secure Boot using lanzaboote";
  };

  config = mkIf config.secure-boot.enable {
    # Lanzaboote replaces systemd-boot and handles Secure Boot
    boot.loader.systemd-boot.enable = mkForce false;
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      # Carry over the host's systemd-boot generation limit, which is otherwise
      # dropped along with systemd-boot itself
      configurationLimit = mkIf (
        config.boot.loader.systemd-boot.configurationLimit != null
      ) config.boot.loader.systemd-boot.configurationLimit;
    };

    # Lanzaboote only works with systemd-boot, not GRUB
    boot.loader.grub.enable = mkForce false;

    # Install sbctl for managing Secure Boot keys
    environment.systemPackages = with pkgs; [
      sbctl
    ];

    # Assertions to ensure proper configuration
    assertions = [
      {
        assertion = config.boot.loader.efi.canTouchEfiVariables;
        message = "Secure Boot requires boot.loader.efi.canTouchEfiVariables = true";
      }
      {
        assertion = config.boot.loader.efi.efiSysMountPoint != "";
        message = "Secure Boot requires a valid EFI system partition mount point";
      }
    ];

  };
}
