{ config, pkgs, lib, vimUtils, ... }:


let
  cfg = config.br.neovim;
  # installs a vim plugin from git with a given tag / branch
  pluginGit = ref: repo: pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "${lib.strings.sanitizeDerivationName repo}";
    version = ref;
    src = builtins.fetchGit {
      inherit ref;
      url = "https://github.com/${repo}.git";
    };
  };

  # always installs latest version
  plugin = pluginGit "HEAD";
in
{
  options.br.neovim = {
    enable = lib.mkEnableOption "Enable the vim editor";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      EDITOR="nvim";
    };
    programs.neovim = {
      enable = true;
      extraConfig = ''
        :luafile ~/.config/nvim/lua/init.lua
      '';
      plugins = with pkgs.vimPlugins; [
        # Navigation
        ctrlp
        bufferline-nvim
        vim-smoothie
        telescope-nvim

        # Editor plugins
        nvim-autopairs
        feline-nvim
        nvim-notify
        vim-illuminate

        # File tree
        nvim-tree-lua
        nvim-web-devicons
        nvim-treesitter

        # Keybindings
        legendary-nvim

        # Indentation
        indent-blankline-nvim

        # LSP
        nvim-lspconfig
        ## Better language server Lua support
        null-ls-nvim
        ## Show references in a popup
        (plugin "wiliamks/nice-reference.nvim")
        ## Show code actions icon
        nvim-lightbulb
        ## Show code actions in popup
        nvim-code-action-menu
        ## Show LSP Processes
        fidget-nvim

        # Completions
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        cmp-cmdline
        cmp-nvim-lsp-signature-help
        nvim-cmp
        lspkind-nvim

        # Snippets
        luasnip
        cmp_luasnip

        # Go plugins
        (plugin "ray-x/go.nvim")
        (plugin "ray-x/guihua.lua")

        # Nix plugins
        vim-nix

        # Themes
        (plugin "ellisonleao/gruvbox.nvim")
      ];
      extraPackages = with pkgs; [
        tree-sitter
        ripgrep

        # Bash
        nodePackages.bash-language-server

        # Nix
        rnix-lsp
        nixpkgs-fmt
        statix

        # Lua
        sumneko-lua-language-server

        # Java
        java-language-server

        # Kotlin
        kotlin-language-server

        # Go
        gopls

        # Json
        nodePackages.vscode-json-languageserver
      ];
    };
    xdg.configFile.nvim = {
      source = ./config;
      recursive = true;
    };
  };
}
