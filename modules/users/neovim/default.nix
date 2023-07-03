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
        nvim-scrollbar

        # Editor plugins
        nvim-autopairs
        feline-nvim
        nvim-notify
        vim-illuminate

        # File tree
        nvim-tree-lua
        nvim-web-devicons

        # Syntax highlighting
        nvim-treesitter.withAllGrammars
        nvim-treesitter-textobjects

        # Keybindings
        legendary-nvim

        # Indentation
        indent-blankline-nvim

        # Collaboration
        (plugin "jbyuki/instant.nvim")

        # LSP
        nvim-lspconfig
        ## Better language server Lua support
        null-ls-nvim
        ## Show references in a popup
        (plugin "wiliamks/nice-reference.nvim")
        ## Show code actions icon
        nvim-lightbulb
        ## Show code actions in popup
        (plugin "aznhe21/actions-preview.nvim")

        # LSP Testing
        neotest-plenary

        ## Show LSP Processes
        fidget-nvim

        # Completions
        nvim-cmp
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        cmp-cmdline
        cmp-nvim-lua
        cmp-vsnip
        cmp-nvim-lsp-signature-help
        lspkind-nvim

        # Snippets
        luasnip
        cmp_luasnip

        # Go plugins
        (plugin "ray-x/go.nvim")
        (plugin "ray-x/guihua.lua")

        # Haskell plugins
        haskell-tools-nvim

        # Nix plugins
        vim-nix

        # Rust plugins
        rust-tools-nvim

        # Themes
        (plugin "ellisonleao/gruvbox.nvim")

        # Typescript
        vim-prettier

        # Lua
        neodev-nvim

        # Utils
        FixCursorHold-nvim
      ];
      extraPackages = with pkgs; [
        tree-sitter
        ripgrep

        # Bash
        nodePackages.bash-language-server

        # Go
        gopls

        # Haskell
        haskell-language-server
        haskellPackages.hoogle

        # Java
        java-language-server

        # Json
        nodePackages.vscode-json-languageserver

        # Kotlin
        kotlin-language-server

        # Lua
        lua-language-server

        # Nix
        rnix-lsp
        nixpkgs-fmt
        statix

        # Rust
        rust-analyzer

        # Terraform
        terraform-ls

        # Typescript
        nodePackages.typescript
        nodePackages.prettier
        nodePackages.typescript-language-server
      ];
    };
    xdg.configFile.nvim = {
      source = ./config;
      recursive = true;
    };
  };
}
