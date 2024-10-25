return {
  require('settings'),
  require('theme'),

  -- LSP configs
  require('lsp/lsp-config'),

  -- AI
  require('ai/openai'),
  require('ai/avante'),

  -- Visual related configs
  --require('visuals/indent-blankline-config'),
  require('visuals/scrollbar-config'),
  require('visuals/fidget-config'),
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
  require('editor/render-markdown'),

  -- Buffer configs
  require('buffers/bufferline-config'),

  -- File tree configs
  require('filetree/nvim-tree-config'),
}
