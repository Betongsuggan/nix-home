{ config, pkgs, lib, ... }:
with lib;

let
  cfg = config.br.autorandr;
  privateLaptopScreen = "00ffffffffffff004d10f71400000000181e0104a51d12780ede50a3544c99260f505400000001010101010101010101010101010101283c80a070b023403020360020b410000018203080a070b023403020360020b410000018000000fe0047524e5050804c513133344e31000000000002410332011200000a010a2020007f";
  workLaptopScreen = "00ffffffffffff004d10d11400000000041e0104a52215780ede50a3544c99260f505400000001010101010101010101010101010101283c80a070b023403020360050d210000018203080a070b023403020360050d210000018000000fe00464b52314b804c513135364e31000000000002410332001200000a010a2020003a";
  currentScreen = workLaptopScreen;
  portableMonitor = "00ffffffffffff0006b3e01773600000201e0104a52616783ba335a6534a9c27105054bfef00d1cf818081c0814081009500b300714f0cdf80a070384040304035007ed71000001e023a801871382d40582c45007ed71000001e000000fc00415355532058473137410a2020000000fd0030f0ffff3c010a20202020202001a2020330f14c0103051404131f120211903f2309170783010000e200d565030c0010006d1a0000020130f0000000000000023a80d072382d40102c96807ed710000018047480d072382d40102c45807ed71000001e0474801871382d40582c45007ed71000001e2982805070384d400820f80c7ed71000001a00000000000000f2";
  apartmentMonitor = "00ffffffffffff00410c3f096a200000091e0104a55021783a10e5ad5048a526135054bfef00d1c0b3009500818081c0316845686168e77c70a0d0a0295030203a001d4e3100001a000000ff0041553032303039303038323938000000fc0050484c203334365031430a2020000000fd0030641ea03c010a20202020202001f602031af14d0103051404131f12021190595a23090707830100004ed470a0d0a0465030403a001d4e3100001c507800a0a038354030203a001d4e3100001ed8590060a3382840a0103a101d4e3100001aef51b87062a0355080b83a001d4e3100001c0000000000000000000000000000000000000000000000000000000000fa";
  islandMonitor = "00ffffffffffff0010acd3a142384f31221f0104a53b21783be755a9544aa1260d5054a54b00714f8180a9c0d1c00101010101010101565e00a0a0a029503020350055502100001a000000ff00324632514744330a2020202020000000fc0044454c4c20533237323244430a000000fd00304b72723c010a202020202020010e020325f14f101f051404131211030216150706012309070783010000681a00000101304b007e3900a080381f4030203a0055502100001a023a801871382d40582c450055502100001ed97600a0a0a034503020350055502100001a00000000000000000000000000000000000000000000000000000000000000000000000092";
  areMonitor = "00ffffffffffff004f4d0803000000002b180103804627780a1990a75546982410494b01080001010101010101010101010101010101011d007251d01e206e285500c48e2100001e011d8018711c1620582c2500c48e2100009e000000fc00445347692054560a2020202020000000fd0016500e5b10000a2020202020200149020322724d0384050710129314161f20212223097f078301000067030c001000b82d8c0ad08a20e02d10103e9600c48e21000018011d00bc52d01e20b8285540c48e2100001e011d80d0721c1620102c2580c48e2100009e8c0ad090204031200c405500c48e210000188c0ad08a20e02d10103e9600c48e2100001800000016";
  currentMonitorOutput = "DP-2";
in
{
  options.br.autorandr = {
    enable = mkEnableOption "Enable Autorandr";
  };

  config = mkIf (cfg.enable) {
    programs.autorandr = {
      enable = true;
      profiles = {
        "laptop" = {
          fingerprint = {
            eDP-1 = currentScreen;
          };
          config = {
            eDP-1 = {
              enable = true;
              crtc = 0;
              primary = true;
              position = "0x0";
              mode = "1920x1200";
              rate = "59.95";
            };
          };
        };
        "portable-monitor" = {
          fingerprint = {
            eDP-1 = currentScreen;
            DP-1 = portableMonitor;
            DP-2 = portableMonitor;
          };
          config = {
            eDP-1 = {
              enable = true;
              mode = "1920x1200";
              rate = "59.95";
              position = "1920x120";
            };
            DP-1 = {
              enable = true;
              primary = true;
              position = "0x0";
              mode = "1920x1080";
              rate = "239.96";
            };
            DP-2 = {
              enable = true;
              primary = true;
              position = "0x0";
              mode = "1920x1080";
              rate = "239.96";
            };
          };
        };
        "apartment-monitor" = {
          fingerprint = {
            eDP-1 = currentScreen;
            DP-1 = apartmentMonitor;
          };
          config = {
            eDP-1 = {
              enable = true;
              mode = "1920x1200";
              rate = "59.95";
              position = "760x1440";
            };
            DP-1 = {
              enable = true;
              primary = true;
              position = "0x0";
              mode = "3440x1440";
              #mode = "1920x1080";
              rate = "100.00";
            };
          };
        };
        "island-monitor" = {
          fingerprint = {
            eDP-1 = currentScreen;
            DP-1 = islandMonitor;
          };
          config = {
            eDP-1 = {
              enable = true;
              mode = "1920x1200";
              rate = "59.95";
              position = "0x120";
            };
            DP-1 = {
              enable = true;
              primary = true;
              position = "1920x0";
              mode = "2560x1440";
              rate = "75.00";
            };
          };
        };
        "åre-monitor" = {
          fingerprint = {
            eDP-1 = currentScreen;
            DP-2 = areMonitor;
          };
          config = {
            eDP-1 = {
              enable = true;
              mode = "1920x1200";
              rate = "59.95";
              position = "0x120";
            };
            DP-2 = {
              enable = true;
              primary = true;
              position = "1920x0";
              mode = "1920x1080";
              rate = "60.00";
            };
          };  
        };
      };
    };
  };
}
