return {
  require('settings'),

  -- LSP configs
  require('lsp/lsp-config'),

  -- Visual related configs
  require('visuals/indent-blankline-config'),
  require('visuals/scrollbar-config'),
  require('visuals/fidget-config'),
  require('visuals/lightbulb-config'),
  require('visuals/notification-config'),

  -- Status bar configs
  require('statusbar/feline-config'),

  -- Editor behavior configs
  require('editor/actions-preview-config'),
  require('editor/autopairs-config'),
  require('editor/diagnostics-config'),
  require('editor/treesitter-config'),
  require('editor/keymappings'),
  require('editor/cmp-config'),
  require('editor/instant-config'),
  require('editor/telescope-config'),
  require('editor/keymappings'),

  -- Buffer configs
  require('buffers/bufferline-config'),

  -- File tree configs
  require('filetree/nvim-tree-config'),
}
