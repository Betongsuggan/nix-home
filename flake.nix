{
  description = "Betongsuggan's flake to rule them all. Proudly stolen from https://jdisaacs.com/blog/nixos-config/";

  inputs = {
    #nixpkgs.url = "nixpkgs/nixos-22.11";
    nixpkgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    handygccs-flake.url = "github:Betongsuggan/handygccs-flake/xboxdrv-control-mapper";
  };

  outputs = { nixpkgs, home-manager, handygccs-flake, ...}@inputs:
  let
    inherit (nixpkgs) lib;
    
    util = with pkgs; import ./lib {
      inherit system pkgs home-manager lib overlays;
    };

    inherit (util) user;
    inherit (util) host;

    pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [];
    };

    system = "x86_64-linux";
  in {
    homeManagerConfigurations = {
      private = user.mkHMUser {
        userConfig = {
          git = {
            enable = true;
            userName = "Betongsuggan";
            userEmail = "rydback@gmail.com";
          };
          general.enable = true;
          communication.enable = true;
          browsers.enable = true;
          autorandr.enable = true;
          audio.enable = true;
          neovim.enable = true;
          urxvt.enable = true;
          #alacritty.enable = true;
          bash.enable = true;
          i3.enable = true;
          rofi.enable = true;
          polybar.enable = true;
          picom.enable = true;
          fonts.enable = true;
          x11.enable = true;
          colemak.enable = true;
          development.enable = true;
          games.enable = true;
        };
        username="betongsuggan";
      };
      work = user.mkHMUser {
        userConfig = {
          git = {
            enable = true;
            userName = "Birger Rydback";
            userEmail = "birger@humla.io";
          };
          general.enable = true;
          communication.enable = true;
          browsers.enable = true;
          autorandr.enable = true;
          audio.enable = true;
          neovim.enable = true;
          urxvt.enable = true;
          bash.enable = true;
          i3.enable = true;
          rofi.enable = true;
          polybar.enable = true;
          picom.enable = true;
          fonts.enable = true;
          x11.enable = true;
          colemak.enable = true;
          development.enable = true;
        };
        username="birgerrydback";
      };
      work-bits = user.mkHMUser {
        userConfig = {
          git = {
            enable = true;
            userName = "Birger Rydback";
            userEmail = "birgerrydback@bits.bi";
          };
          general.enable = true;
          communication.enable = true;
          browsers.enable = true;
          #autorandr.enable = true;
          audio.enable = true;
          neovim.enable = true;
          alacritty.enable = true;
          bash.enable = true;
          #i3.enable = true;
          #rofi.enable = true;
          #polybar.enable = true;
          #picom.enable = true;
          fonts.enable = true;
          #x11.enable = true;
          sway.enable = true;
          #colemak.enable = true;
          development.enable = true;
        };
        username="birgerrydback";
      };
      ayaneo = user.mkHMUser {
        userConfig = {
          git = {
            enable = true;
            userName = "Birger Rydback";
            userEmail = "rydback@gmail.com";
          };
          general.enable = true;
          games.enable = true;
          browsers.enable = true;
          audio.enable = true;
          neovim.enable = true;
          urxvt.enable = true;
          bash.enable = true;
          fonts.enable = true;
          x11.enable = true;
          colemak.enable = true;
        };
        username="betongsuggan";
      };
    };

    nixosConfigurations = {
      laptop = host.mkHost {
          name = "nixos";
          NICs = [ "wlp0s20f3" ]; 
          kernelPackage = pkgs.linuxPackages_latest;
          initrdMods = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
          kernelMods = [ "kvm-intel" "iwlwifi" ];
          kernelParams = [];
          fileSystems = {
            "/" = {
              device = "/dev/disk/by-uuid/e6fa26ba-7e3a-4146-8bba-54fd65aa211a";
              fsType = "ext4";
            };
  
            "/boot" = {
              device = "/dev/disk/by-uuid/C8DA-ECD3";
              fsType = "vfat";
            };
          };
          swap = "/dev/disk/by-uuid/da3b504d-b0fa-450e-8974-e332c5ce5608";
          systemConfig = {
            touchpad.enable = true;
            graphics.enable = true;
            sound.enable = true;
            docker.enable = true;
            bluetooth.enable = true;
            xserver.enable = true;
            power-management.enable = true;
          };
          users = [{
            name = "betongsuggan";
            groups = [ "wheel" "networkmanager" "video" "docker" ];
            uid = 1000;
            shell = pkgs.bash;
          }];
          cpuCores = 4;
      };
      ayaneo = host.mkHost {
          name = "ayaneo";
          NICs = [ "wlp3s0" ]; 
          kernelPackage = pkgs.linuxPackages_latest;
          initrdMods = [ "nvme" "xhci_pci" "thunderbolt" "usbhid" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
          kernelMods = [ "kvm-amd" ];
          kernelParams = [];
          fileSystems = {
            "/" = {
              device = "/dev/disk/by-uuid/cc910516-4af4-4894-87d5-1e74c726bafc";
              fsType = "ext4";
            };
            "/boot/efi" = {
              device = "/dev/disk/by-uuid/5793-8E8F";
              fsType = "vfat";
            };
          };
          swap = "/dev/disk/by-uuid/ff8b0185-4671-4fff-bdae-fa83dcc0318c";
          bootPartition = "/boot/efi";
          systemConfig = {
            sound.enable = true;
            bluetooth.enable = true;
            graphics.enable = true;
            kde.enable = true;
            firewall = {
              enable = true;
              tcpPorts = [ 8080 ];
            };
          };
          users = [{
            name = "betongsuggan";
            groups = [ "wheel" "networkmanager" ];
            uid = 1000;
            shell = pkgs.bash;
          }];
          cpuCores = 16;
          additionalModules = [ 
            handygccs-flake.nixosModules.handygccs
            { services.handygccs.enable = true; }
            handygccs-flake.nixosModules.xboxdrv-handygccs
            { services.xboxdrv-handygccs.enable = true; }
          ];
      };
      home-desktop = host.mkHost {
          name = "home-desktop";
          kernelPackage = pkgs.linuxPackages_5_15;
          initrdMods = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
          kernelMods = [ "iwlwifi" ];
          kernelParams = [];
          systemConfig = {
            #graphics.enable = true;
            sound.enable = true;
            #docker.enable = true;
            bluetooth.enable = true;
            xserver.enable = true;
            firewall = {
              enable = true;
              tcpPorts = [ 8080 ];
            };
          };
          users = [{
            name = "betongsuggan";
            groups = [ "wheel" "networkmanager" "video" ];
            uid = 1000;
            shell = pkgs.bash;
          }];
          cpuCores = 16;
      };
      humla-nixos = host.mkHost {
          name = "humla-nixos";
          NICs = [ "wlp0s20f3" ]; 
          kernelPackage = pkgs.linuxPackages_latest;
          initrdMods = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
          kernelMods = [ "kvm-intel" "iwlwifi" ];
          kernelParams = [];
          fileSystems = {
            "/" = {
              device = "/dev/disk/by-uuid/0c799567-d4e0-44e8-9007-60c28fdbe367";
              fsType = "ext4";
            };
  
            "/boot" = {
              device = "/dev/disk/by-uuid/AEFE-A292";
              fsType = "vfat";
            };
          };
          swap = "/dev/disk/by-uuid/bda65168-5ec0-4cf9-9bcf-15fa4a3328ce";
          systemConfig = {
            touchpad.enable = true;
            graphics.enable = true;
            sound.enable = true;
            docker.enable = true;
            bluetooth.enable = true;
            xserver.enable = true;
            printers.enable = true;
            power-management.enable = true;
            diskEncryption = {
              enable = true;
              diskId = "33b56bc7-dd4f-4a2d-a000-1d8cb6cfbdb3";
              headerId = "2556269d-06e3-4e5b-94dd-9a2a7fc0fda9";
            };
            firewall = {
              enable = true;
              tcpPorts = [ 8080 ];
            };
          };
          users = [{
            name = "birgerrydback";
            groups = [ "wheel" "networkmanager" "video" "docker" ];
            uid = 1000;
            shell = pkgs.bash;
          }];
          cpuCores = 6;
      };
      bits-nixos = host.mkHost {
          name = "bits-nixos";
          NICs = [ "wwp103s0f4u3u3" ]; 
          kernelPackage = pkgs.linuxPackages_latest;
          initrdMods = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" "sdhci_pci" ];
          kernelMods = [ "kvm-amd" ];
          kernelParams = [];
          fileSystems = {
            "/" = {
              device = "/dev/disk/by-uuid/75ba9480-26dc-4602-8797-b1896f829acd";
              fsType = "ext4";
            };
  
            "/boot" = {
              device = "/dev/disk/by-uuid/D4CC-FF5B";
              fsType = "vfat";
            };
          };
          swap = "/dev/disk/by-uuid/08fd16ed-033c-456a-af0e-f16c933f08a3";
          systemConfig = {
            touchpad.enable = true;
            graphics.enable = true;
            sound.enable = true;
            docker.enable = true;
            bluetooth.enable = true;
            wayland.enable = true;
            printers.enable = true;
            power-management.enable = true;
            diskEncryption = {
              enable = true;
              diskId = "f3fd4fdf-b8ef-45c7-8e96-2ca5bfe32cd9";
              headerId = "1abd4b51-8a97-4d04-97f1-326b2ef1dcbe";
            };
            firewall = {
              enable = true;
              tcpPorts = [ 8080 ];
            };
          };
          users = [{
            name = "birgerrydback";
            groups = [ "wheel" "networkmanager" "video" "docker" ];
            uid = 1000;
            shell = pkgs.bash;
          }];
          cpuCores = 8;
      };
    };
  };
}
