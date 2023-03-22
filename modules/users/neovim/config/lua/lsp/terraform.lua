local nvim_lsp = require('lspconfig')

return function (on_attach, capabilities)
  nvim_lsp.terraformls.setup{}

  --vim.api.nvim_create_autocmd({"BufWritePre"}, {
  --  pattern = {"*.tf", "*.tfvars"},
  --  callback = vim.lsp.buf.format(),
  --})
end
