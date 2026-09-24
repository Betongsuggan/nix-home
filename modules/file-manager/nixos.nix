{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  anyUser = inputs.self.lib.anyHomeUser config;
  anyUserEnabled = anyUser (u: u.my.file-manager.enable);
  anyNetworkShares = anyUser (u: u.my.file-manager.enable && u.my.file-manager.networkShares.enable);
in
{
  config = mkMerge [
    (mkIf anyUserEnabled {
      # Settings backend for Thunar/XFCE applications
      programs.xfconf.enable = true;

      # Thunar file manager with plugins
      programs.thunar = {
        enable = true;
        plugins = with pkgs; [
          thunar-archive-plugin
          thunar-volman
        ];
      };

      # Virtual filesystem support (trash, MTP, SMB, SFTP, etc.)
      services.gvfs.enable = true;

      # Thumbnail service
      services.tumbler.enable = true;

      # Disk management for auto-mounting
      services.udisks2.enable = true;

      # Polkit for privileged operations (mounting, etc.)
      security.polkit.enable = true;
    })

    (mkIf anyNetworkShares {
      # mDNS discovery so SMB shares appear under "Network" and
      # .local hostnames resolve when mounting shares
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    })
  ];
}
