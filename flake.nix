{
  description = "Betongsuggan's flake to rule them all. Proudly stolen from https://jdisaacs.com/blog/nixos-config/";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ...}@inputs:
  let
    inherit (nixpkgs) lib;
    
    util = with pkgs; import ./lib {
      inherit system pkgs home-manager lib overlays;# overlays = pkgs.overlays;
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
      home-desktop = host.mkHost {
          name = "home-desktop";
          #NICs = [ "" ]; 
          kernelPackage = pkgs.linuxPackages_5_15;
          initrdMods = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
          kernelMods = [ "iwlwifi" ];
          kernelParams = [];
          #fileSystems = {
          #  "/" = {
          #    device = "/dev/disk/by-uuid/0c799567-d4e0-44e8-9007-60c28fdbe367";
          #    fsType = "ext4";
          #  };
          #};
          #swap = "/dev/disk/by-uuid/bda65168-5ec0-4cf9-9bcf-15fa4a3328ce";
          systemConfig = {
            #graphics.enable = true;
            sound.enable = true;
            #docker.enable = true;
            bluetooth.enable = true;
            xserver.enable = true;
            #printers.enable = true;
            #power-management.enable = true;
            #diskEncryption = {
            #  enable = true;
            #  diskId = "33b56bc7-dd4f-4a2d-a000-1d8cb6cfbdb3";
            #  headerId = "2556269d-06e3-4e5b-94dd-9a2a7fc0fda9";
            #};
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
    };
  };
}
