local null_ls = require("null-ls")
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

return function(on_attach, capabilities)
  null_ls.setup({
    sources = {
      -- Nix
      null_ls.builtins.formatting.nixpkgs_fmt,
      null_ls.builtins.diagnostics.statix,
      null_ls.builtins.code_actions.statix,

      -- Go
      null_ls.builtins.formatting.gofumpt,
      null_ls.builtins.formatting.goimports,
      null_ls.builtins.formatting.golines,

      -- TypeScript
      null_ls.builtins.formatting.prettier
    },
    on_attach = function(client, bufnr)
      if client.supports_method("textDocument/formatting") then
        vim.api.nvim_clear_autocmds({
          group = augroup,
          buffer = bufnr,
        })
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = augroup,
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({ bufnr = bufnr })
          end,
        })
      end
    end
  })
end
