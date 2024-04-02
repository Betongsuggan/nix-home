local nvim_lsp = require('lspconfig')
local keymaps  = require('editor/keymappings')

return function(on_attach, capabilities)
  nvim_lsp.tsserver.setup {
    on_attach = on_attach,
    capabilities = capabilities,

    keymaps.lsp_format(function()
      vim.cmd "PrettierAsync"
    end)
  }
end
