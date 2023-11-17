local nvim_lsp = require('lspconfig')

return function(on_attach, capabilities)
  nvim_lsp.gopls.setup {
    cmd = { "gopls" },
    on_attach = on_attach,
    settings = {
      gopls = {
        completeUnimported = true,
        usePlaceholders = true,
        gofumpt = true,
        analyses = {
          unusedparams = true,
          shadow = true,
        },
        staticcheck = true,
      },
    },
  }
end
