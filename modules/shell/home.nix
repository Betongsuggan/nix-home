{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  imports = [
    ./bash
    ./fish
    ./nushell
  ];

  options.my.shell = {
    enable = mkEnableOption "Enable shell configuration";

    backend = mkOption {
      description = "Shell backend to use";
      type = types.enum [
        "bash"
        "fish"
        "nushell"
      ];
      default = "bash";
    };

    aliases = mkOption {
      description = "Shell aliases shared across all shells (hosts add their own; the defaults below are mkDefault per alias)";
      type = types.attrsOf types.str;
      default = { };
    };

    editor = mkOption {
      description = "Default editor";
      type = types.str;
      default = "nvim";
    };

    viMode = mkOption {
      description = "Enable vi mode in shells";
      type = types.bool;
      default = true;
    };

    extraPaths = mkOption {
      description = "Extra paths to add to PATH";
      type = types.listOf types.str;
      default = [ "${config.home.homeDirectory}/.cargo/bin" ];
    };

    bash = {
      enable = mkOption {
        description = "Enable bash shell";
        type = types.bool;
        default = config.my.shell.enable && config.my.shell.backend == "bash";
      };

      extraInit = mkOption {
        description = "Extra bash initialization";
        type = types.lines;
        default = "";
      };
    };

    fish = {
      enable = mkOption {
        description = "Enable fish shell";
        type = types.bool;
        default = config.my.shell.enable && config.my.shell.backend == "fish";
      };

      enableNixIndex = mkOption {
        description = "Enable nix-index integration for fish";
        type = types.bool;
        default = true;
      };

      extraInit = mkOption {
        description = "Extra fish initialization";
        type = types.lines;
        default = "";
      };
    };

    nushell = {
      enable = mkOption {
        description = "Enable nushell";
        type = types.bool;
        default = config.my.shell.enable && config.my.shell.backend == "nushell";
      };

      showBanner = mkOption {
        description = "Show nushell banner";
        type = types.bool;
        default = false;
      };

      extraConfig = mkOption {
        description = "Extra nushell configuration";
        type = types.lines;
        default = "";
      };
    };
  };

  config = mkIf config.my.shell.enable {
    my.shell.aliases = mapAttrs (_: mkDefault) {
      ll = "ls -la --color=auto";
      ls = "ls --color=auto";
      gw = "./gradlew --no-daemon";
    };

    home.sessionPath = config.my.shell.extraPaths;

    # The editor from the nvim flake input (update with `nix flake update nvim`)
    home.packages = [ pkgs.nvim-config ];
  };
}
