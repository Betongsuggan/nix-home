local nvim_lsp  = require('lspconfig')

return function (on_attach, capabilities)
  nvim_lsp.gopls.setup{
    cmd = { "gopls" },
    on_attach = function(arg, bufnr)
      vim.api.nvim_create_autocmd('BufWritePre', {
        pattern = '<buffer>',
        callback = function()
          vim.lsp.buf.format()
        end
      })
      vim.api.nvim_create_autocmd('BufWritePre', {
        pattern = '<buffer>',
        callback = function()
          vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })
        end
      })
      on_attach(arg, bufnr)
    end,
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
