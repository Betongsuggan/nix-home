local set = vim.opt
local g = vim.g

-- Set leader key
g.mapleader = ' '
vim.cmd([[ colorscheme gruvbox ]])

-- Visuals
set.cursorline = true
set.laststatus = 2
set.number = true
set.ruler = true
set.termguicolors = true
set.title = true
set.wildmenu = true

-- Clipboard
-- set.clipboard=unnamedplus = true

-- Search behavior
set.incsearch = true -- Find next match as we type the search
set.hlsearch = true -- Highlight search matches
set.ignorecase = true -- Ignore casing when we seach...
set.smartcase = true -- ...unless we search with capitalization

-- Editoring
set.autoindent = true
set.smartindent = true
set.autowrite = true
set.expandtab = true
set.number = true
set.shiftwidth = 2
set.smarttab = true
set.tabstop = 2

-- Timers
set.timeoutlen = 1000
set.ttimeout = true
set.ttimeoutlen = 5
set.updatetime = 100

Theming = {
  statusline = 'slant',
  statusline_color = 'gruvbox'
}
