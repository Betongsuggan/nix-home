-- Status bar on be bottom

local gruvbox = {
  fg = '#928374',
  bg = '#1F2223',
  black = '#1B1B1B',
  skyblue = '#458588',
  cyan = '#83a597',
  green = '#689d6a',
  oceanblue = '#1d2021',
  magenta = '#fb4934',
  orange = '#fabd2f',
  red = '#cc241d',
  violet = '#b16286',
  white = '#ebdbb2',
  yellow = '#d79921',
}

local disable = {
  filetypes = {
    '^NvimTree$',
    '^packer$',
    '^startify$',
    '^fugitive$',
    '^fugitiveblame$',
    '^qf$',
    '^help$',
    '^minimap$',
    '^Trouble$',
    '^dap-repl$',
    '^dapui_watches$',
    '^dapui_stacks$',
    '^dapui_breakpoints$',
    '^dapui_scopes$'
  },
  buftypes = {
    '^terminal$'
  },
  bufnames = {}
}

local feline = require('feline')
feline.setup({
  theme = gruvbox,
  disable = disable
})
