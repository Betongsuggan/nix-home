local nvim_lsp  = require('lspconfig')

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
