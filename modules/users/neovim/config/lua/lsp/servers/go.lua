local lsp = require('lspconfig')
local configs = require 'lspconfig/configs'

if not configs.golangcilsp then
 	configs.golangcilsp = {
		default_config = {
			cmd = {'golangci-lint-langserver'},
			root_dir = lsp.util.root_pattern('.git', 'go.mod'),
			init_options = {
					command = { "golangci-lint", "run", "--out-format", "json", "--issues-exit-code=1" };
			}
		};
	}
end

return function(on_attach, capabilities)
  lsp.gopls.setup {
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
          nilaway = true,
        },
        staticcheck = true,
      },
    },
  }

  lsp.golangci_lint_ls.setup {
  	filetypes = {'go','gomod'}
  }
end
