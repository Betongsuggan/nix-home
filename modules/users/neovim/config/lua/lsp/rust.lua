--local nvim_lsp = require('lspconfig')

local rt = require("rust-tools")

return function (on_attach, capabilities)
  rt.setup({
    server = {
      on_attach = on_attach,
      capabilities = capabilities
    }
  })
end

  --vim.api.nvim_create_autocmd({"BufWritePre"}, {
  --  pattern = {"*.tf", "*.tfvars"},
  --  callback = vim.lsp.buf.format(),
  --})


--rt.setup({
--  server = {
--    on_attach = function(_, bufnr)
--      -- Hover actions
--      vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
--      -- Code action groups
--      vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
--    end,
--  },
--})
