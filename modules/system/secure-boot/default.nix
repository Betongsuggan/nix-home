{ config, lib, pkgs, ... }:
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
      pkiBundle = "/etc/secureboot";
    };

    # Ensure GRUB is disabled when Secure Boot is enabled
    # Lanzaboote only works with systemd-boot, not GRUB
    boot.loader.grub.enable = mkForce false;
    boot.loader.grub.useOSProber = mkForce false;

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

    # Warning about manual setup required
    warnings = [
      ''
        Secure Boot has been enabled. After building and switching to this configuration,
        you must complete the one-time setup process:

        1. Create Secure Boot keys:
           sudo sbctl create-keys

        2. Enroll keys in firmware (this will enable Secure Boot):
           sudo sbctl enroll-keys -m

        3. Verify the system will boot with Secure Boot:
           Check that /boot/EFI/Linux/*.efi files exist
           These are the signed unified kernel images

        4. Reboot and enable Secure Boot in BIOS/UEFI settings

        5. After reboot, verify Secure Boot status:
           sudo sbctl status

        Note: systemd-boot will still allow you to select between NixOS generations
        at boot time. Press Space during boot to see the boot menu.
      ''
    ];
  };
}
