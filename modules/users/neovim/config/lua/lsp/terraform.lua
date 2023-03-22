require'lspconfig'.terraformls.setup{}
vim.api.nvim_create_autocmd({
  pattern = {"*.tf", "*.tfvars"},
  callback = vim.lsp.buf.format(),
}, {"BufWritePre"})
