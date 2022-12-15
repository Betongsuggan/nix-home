{ config, pkgs, lib, vimUtils, ... }:
let
  cfg = config.br.neovim;
  # installs a vim plugin from git with a given tag / branch
  pluginGit = ref: repo: pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "${lib.strings.sanitizeDerivationName repo}";
    version = ref;
    src = builtins.fetchGit {
      url = "https://github.com/${repo}.git";
      ref = ref;
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
    nixpkgs.overlays = [
      (import (builtins.fetchTarball {
        url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
      }))
    ];

    home.sessionVariables = {
      EDITOR="nvim";
    };
    programs.neovim = {
      enable = true;
      package = pkgs.neovim-nightly;
      extraConfig = ''
        lua <<EOF
          local set = vim.opt

          -- Visuals
          set.title = true
          set.cursorline = true
          set.number = true
          set.ruler = true
          set.termguicolors = true
          set.wildmenu = true
          set.laststatus = 2

          -- Clipboard
          set.clipboard=unnamedplus = true

          -- Editoring
          set.tabstop = 2
          set.shiftwidth = 2
          set.smarttab = true
          set.expandtab = true
          set.autowrite = true

          -- Timers
          set.ttimeout = true
          set.updatetime = 100
          set.timeoutlen = 1000
          set.ttimeoutlen = 5
        EOF

        filetype plugin indent on
        set completeopt=noinsert,menuone,noselect
        set nocompatible
        syntax on
        set nowrap
        set encoding=utf8
        set hidden

        set inccommand=split
        set splitbelow splitright
        set nobackup
        set nowritebackup

        colorscheme gruvbox
        "let g:lightline.colorscheme = 'gruvbox'
        let g:VIM_COLOR_SCHEME = 'gruvbox'

        " --- Auto commands
        autocmd FileType c,cpp,java,php,json,go,nix :autocmd BufWritePre <buffer> %s/\s\+$//e

        " Airline configuration
        let g:airline_powerline_fonts = 1
        let g:airline#extensions#tabline#enabled = 1

        " NERDTree configuration
        let NERDTreeShowHidden = 1

        map <C-n> :NERDTreeToggle<CR>

        " CTRLP configuration
        let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']

        " Setup Go plugins
        lua <<EOF
        local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
        vim.api.nvim_create_autocmd("BufWritePre", {
          pattern = "*.go",
          callback = function()
           require('go.format').goimport()
          end,
          group = format_sync_grp,
        })
        require('go').setup()
        EOF
      '';
      plugins = with pkgs.vimPlugins; [
        # Developer plugins
        vim-nix

        # Navigation
        ctrlp
        nerdtree

        # Go plugins
        (plugin "nvim-treesitter/nvim-treesitter")
        (plugin "neovim/nvim-lspconfig")
        (plugin "ray-x/go.nvim")
        (plugin "ray-x/guihua.lua")

        # Themes
        vim-airline
        vim-devicons
        gruvbox
      ];
    };
  };
}
