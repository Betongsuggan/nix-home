{
  config,
  options,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;

let
  cfg = config.my.profiles;
in
{
  options.my.profiles = {
    workstation.enable = mkEnableOption "a machine someone sits at: desktop session, audio, bluetooth, printing";
    laptop.enable = mkEnableOption "a portable workstation: touchpad, backlight, battery and power management";
    gaming-station.enable = mkEnableOption "a couch gaming machine with an autologin `gamer` session";
  };

  config = mkMerge [
    (mkIf cfg.workstation.enable (
      {
        hardware.enableAllFirmware = mkDefault true;
        services.fwupd.enable = mkDefault true;

        my = {
          audio.enable = mkDefault true;
          bluetooth.enable = mkDefault true;
          graphics.enable = mkDefault true;
          network-manager.enable = mkDefault true;
          printers.enable = mkDefault true;
          wayland-security.enable = mkDefault true;
        };
      }
      // optionalAttrs (options ? home-manager) {
        home-manager.sharedModules = [ { my.profiles.desktop.enable = mkDefault true; } ];
      }
    ))

    (mkIf cfg.laptop.enable (
      {
        my.profiles.workstation.enable = mkDefault true;
        my.power-management.enable = mkDefault true;

        services.libinput = {
          enable = true;
          touchpad = {
            tapping = mkDefault true;
            accelProfile = mkDefault "flat";
            accelSpeed = mkDefault "0";
            disableWhileTyping = mkDefault true;
          };
        };

        # Let the video group write the backlight directly
        services.udev.extraRules = ''
          ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
          ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
        '';

      }
      # Hosts without Home Manager users have no home-manager options at all
      // optionalAttrs (options ? home-manager) {
        home-manager.sharedModules = [ { my.battery-monitor.enable = mkDefault true; } ];
      }
    ))

    (mkIf cfg.gaming-station.enable {
      my.profiles.workstation.enable = mkDefault true;

      # Admins can drive the virtual input devices (remappers, streaming)
      users.users =
        genAttrs config.my.common.admins (_: {
          extraGroups = [
            "uinput"
            "input"
          ];
        })
        // {
          # The couch session: an unprivileged `gamer` logged in on tty1 at boot
          # (the account itself comes from lib.accounts)
          gamer.extraGroups = [
            "networkmanager"
            "video"
            "audio"
            "input"
            "uinput"
            "gamemode"
          ];
        };
      my.autologin = {
        enable = true;
        user = "gamer";
        method = "getty";
        tty = "tty1";
      };

      my.secure-boot.enable = mkDefault true;
      my.audio.lowLatency = mkDefault true;
      my.bluetooth.wake = {
        enable = mkDefault true;
        allowedDevices = [
          "D0:BC:C1:41:80:04" # DualSense Wireless Controller
        ];
      };

      # Off-site/on-site copy of controller's backups
      my.restic-target = {
        enable = mkDefault true;
        sources.controller.sshKey = inputs.self.lib.hosts.controller.users.restic.ssh.id_ed25519;
      };

      nixpkgs.config.permittedInsecurePackages = [ "freeimage-3.18.0-unstable-2024-04-18" ];

      boot = {
        # Zen kernel optimized for desktop/gaming performance on Ryzen CPUs
        kernelPackages = mkDefault pkgs.linuxPackages_zen;
        supportedFilesystems = [ "ntfs" ];
        kernelParams = [
          "preempt=full"
          "threadirqs"
          "transparent_hugepage=madvise"
          "mitigations=off"
          "amd_pstate=active" # Modern AMD P-State driver
          "split_lock_detect=off" # Gaming performance
          "tsc=reliable"
          "clocksource=tsc"
          "nowatchdog"
          "nmi_watchdog=0"
        ];
        kernel.sysctl = {
          "vm.swappiness" = 10;
          "vm.max_map_count" = 2147483642; # Required for some games
          "vm.vfs_cache_pressure" = 50;
          "vm.dirty_ratio" = 20;
          "vm.dirty_background_ratio" = 5;
        };
      };

      zramSwap = {
        enable = mkDefault true;
        algorithm = mkDefault "zstd";
        memoryPercent = mkDefault 50;
      };

      powerManagement.cpuFreqGovernor = mkDefault "performance";

      programs.gamemode = {
        enable = true;
        enableRenice = true;
        settings.general = {
          renice = mkDefault 10;
          softrealtime = mkDefault "auto";
          ioprio = mkDefault 0;
          inhibit_screensaver = mkDefault 1;
        };
      };
      environment.systemPackages = with pkgs; [
        gamemode
        mangohud
        ryzenadj # these are Ryzen machines
      ];
    })
  ];
}
