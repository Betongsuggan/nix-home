{ config, lib, pkgs, ... }:
with lib;

{
  imports = [ ./bash ./fish ./nushell ];

  options.shell = {
    enable = mkEnableOption "Enable shell configuration";

    defaultShell = mkOption {
      description = "Default shell to use";
      type = types.enum [ "bash" "fish" "nushell" ];
      default = "bash";
    };

    aliases = mkOption {
      description = "Shell aliases shared across all shells";
      type = types.attrsOf types.str;
      default = {
        cloud = "cd ~/Development/cloud";
        dashboard = "cd ~/Development/web/apps/dashboard";
        nocode = "cd ~/Development/web/apps/nocode";
        demo = "cd ~/Development/web/apps/nocode-demo";
        ll = "ls -la --color=auto";
        ls = "ls --color=auto";
        vim = "nix run github:/Betongsuggan/nvim --refresh";
        hm = "home-manager";
        gw = "./gradlew --no-daemon";
      };
    };

    editor = mkOption {
      description = "Default editor";
      type = types.str;
      default = "nix run github:/Betongsuggan/nvim";
    };

    viMode = mkOption {
      description = "Enable vi mode in shells";
      type = types.bool;
      default = true;
    };

    extraPaths = mkOption {
      description = "Extra paths to add to PATH";
      type = types.listOf types.str;
      default = [ "~/.cargo/bin/" ];
    };

    bash = {
      enable = mkOption {
        description = "Enable bash shell";
        type = types.bool;
        default = config.shell.defaultShell == "bash";
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
        default = config.shell.defaultShell == "fish";
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
        default = config.shell.defaultShell == "nushell";
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

  config = mkIf config.shell.enable {
    # The individual shell modules are enabled based on the shell.{bash,fish,nushell}.enable options
    # which are automatically set based on the defaultShell selection
  };
}
