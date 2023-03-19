local nvim_lsp  = require('lspconfig')

--vim.api.nvim_create_autocmd({
--  pattern = '*.go',
--  callback = function()
--    vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })
--  end
--}, 'BufWritePre')

return function (on_attach, capabilities)
  nvim_lsp.gopls.setup {
  	cmd = {'gopls'},

  	-- for postfix snippets and analyzers
  	capabilities = capabilities,
  	settings = {
  	  gopls = {
  	    experimentalPostfixCompletions = true,
  	    analyses = {
  	      unusedparams = true,
  	      shadow = true,
  	   },
  	   staticcheck = true,
  	  },
  	},
  	on_attach = on_attach,
  }
end
