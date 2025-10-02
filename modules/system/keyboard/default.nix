{ pkgs, config, lib, ... }:
with lib;

{
  options.keyboard = {
    enable = mkOption {
      description = "Enable keyboard customization";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.keyboard.enable {
    boot.kernelModules = [ "uinput" ];
    hardware.uinput.enable = true;

    # Set up udev rules for uinput
    services.udev.extraRules = ''
      KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    '';

    # Ensure the uinput group exists
    users.groups.uinput = { };

    systemd.services.kanata-internalKeyboard.serviceConfig = {
      SupplementaryGroups = [
        "input"
        "uinput"
      ];
    };

    services.kanata = {
      enable = true;
      keyboards = {
        internalKeyboard = {
          extraDefCfg = "process-unmapped-keys yes";
          config = ''
            (defsrc
             a s d f
             j k l ;
            )

            (defvar
             tap-time 50
             hold-time 250
            )

            (defalias
             a_hold (tap-hold 1 $hold-time a (one-shot 400 lmeta))
             s_hold (tap-hold 1 $hold-time s lalt)
             d_hold (tap-hold 1 $hold-time d lctrl)
             f_hold (tap-hold 1 200 f lshift)

             j_hold (tap-hold 1 140 j rshift)
             k_hold (tap-hold 1 $hold-time k rctrl)
             l_hold (tap-hold 1 $hold-time l ralt)
             ;_hold (tap-hold 1 $hold-time ; (one-shot 400 rmeta))
            )

            (deflayer base
             @a_hold
             @s_hold
             @d_hold
             @f_hold

             @j_hold
             @k_hold
             @l_hold
             @;_hold
            )
          '';
        };
      };
    };
  };
}
