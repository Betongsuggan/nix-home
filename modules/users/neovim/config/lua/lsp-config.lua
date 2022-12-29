-- Setup lspconfig.
local nvim_lsp  = require('lspconfig')
local telescope = require('telescope.builtin')
local keymaps   = require('keymappings')

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    -- Enable completion triggered by <c-x><c-o>
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    require('illuminate').on_attach(client)

    -- Mappings.
    keymaps.lsp_go_to_declaration(telescope.lsp_type_definitions)
    keymaps.lsp_go_to_definition(telescope.lsp_definitions)
    keymaps.lsp_go_to_implementation(telescope.lsp_implementations)
    keymaps.lsp_next_reference(function() require('illuminate').next_reference({ wrap = true }) end)
    keymaps.lsp_previous_reference(function() require('illuminate').next_reference({ reverse = true, wrap = true }) end)
    keymaps.lsp_next_diagnostic(function() vim.diagnostic.goto_next({ float =  { border = "single" }}) end)
    keymaps.lsp_previous_diagnostic(function() vim.diagnostic.goto_prev({ float =  { border = "single" }}) end)
    keymaps.lsp_hover(vim.lsp.buf.hover)
    keymaps.lsp_rename(vim.lsp.buf.rename)
    keymaps.lsp_format(vim.lsp.buf.formatting)
    keymaps.lsp_show_signature(vim.lsp.buf.signature_help)
    keymaps.lsp_show_type_definition(vim.lsp.buf.type_definition)
    keymaps.lsp_show_code_action(function () vim.cmd([[CodeActionMenu]]) end)
    keymaps.lsp_show_diagnostics(telescope.diagnostics)
    keymaps.lsp_show_references(telescope.lsp_references)

    if client.server_capabilities.document_formatting then
        vim.cmd([[
            augroup LspFormatting
                autocmd! * <buffer>
                autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()
            augroup END
            ]])
    end
end

local notify = require('notify')
vim.lsp.handlers['window/showMessage'] = function(_, result, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local lvl = ({ 'ERROR', 'WARN', 'INFO', 'DEBUG' })[result.type]
  notify({ result.message }, lvl, {
    title = 'LSP | ' .. client.name,
    timeout = 10000,
    keep = function()
      return lvl == 'ERROR' or lvl == 'WARN'
    end,
  })
end

local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

local capabilities = require('cmp_nvim_lsp').default_capabilities()
-- Enable Language Servers
local function default_lsp_setup(module)
    nvim_lsp[module].setup{
        on_attach = on_attach,
        capabilities = capabilities
    }
end

-- Bash
default_lsp_setup('bashls')

-- Haskell
default_lsp_setup('hls')

-- Java
nvim_lsp.java_language_server.setup{
    cmd = { 'java-language-server' },
    on_attach = on_attach,
    capabilities = capabilities
}

-- Kotlin
default_lsp_setup('kotlin_language_server')

-- Lua
local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")
nvim_lsp.sumneko_lua.setup{
    settings = {
        Lua = {
            runtime = {
                -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                version = 'LuaJIT',
                -- Setup your lua path
                path = runtime_path,
            },
            completion = {
                callSnippet = 'Replace'
            },
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                globals = {'vim'},
            },
            workspace = {
                -- Make the server aware of Neovim runtime files
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
            },
            -- Do not send telemetry data containing a randomized but unique identifier
            telemetry = {
                enable = false,
            }
        }
    },
    on_attach = on_attach,
    capabilities = capabilities
}

-- Nix
nvim_lsp.rnix.setup{
    on_attach = function(client, bufnr)
        on_attach(client, bufnr)

        -- Let statix format
        client.server_capabilities.document_formatting = false
        client.server_capabilities.document_range_formatting = false
    end
}

-- Go
nvim_lsp.gopls.setup{
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

-- JSON
default_lsp_setup('jsonls')

-- NULL
require("null-ls").setup({
    sources = {
        -- Nix
        require("null-ls").builtins.formatting.nixpkgs_fmt,
        require("null-ls").builtins.diagnostics.statix,
        require("null-ls").builtins.code_actions.statix,
    },
})
