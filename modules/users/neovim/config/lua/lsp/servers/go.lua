local nvim_lsp  = require('lspconfig')

return function (on_attach, capabilities)
  nvim_lsp.gopls.setup{
    cmd = { "gopls" },
    on_attach = on_attach,
    settings = {
      gopls = {
        gofumpt = true,
        analyses = {
          unusedparams = true,
        },
        staticcheck = true,
      },
    },
  }
end
