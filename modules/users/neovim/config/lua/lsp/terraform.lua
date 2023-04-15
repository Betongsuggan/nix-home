local nvim_lsp = require('lspconfig')

return function (on_attach, capabilities)
  nvim_lsp.terraformls.setup{
    on_attach = function(arg, bufnr)
      vim.api.nvim_create_autocmd({"BufWritePre"}, {
        pattern = {"*.tf", "*.tfvars"},
        callback = vim.lsp.buf.format(),
      })
      on_attach(arg, bufnr)
    end
  }
end
