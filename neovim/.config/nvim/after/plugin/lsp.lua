-- Variables
local lsp_zero = require('lsp-zero')
local lspconfig = require('lspconfig')
local cmp = require('cmp')

lsp_zero.on_attach(function(client, bufnr)
	lsp_zero.default_keymaps({buffer = bufnr})
end)

require('mason').setup({})
require('mason-lspconfig').setup({
    -- Default Parameters
	ensure_installed = {'rust_analyzer', 'bashls', 'lua_ls', 'clangd', 'ts_ls', 'texlab', 'matlab_ls', 'pyright', 'zls'},
	handlers = {
		function(server_name)
			require('lspconfig')[server_name].setup({})
		end,
	},
    -- clangd Config
    clangd = function ()
    lspconfig.clangd.setup {
        on_attach = on_attach, 
        flags = {
            debounce_text_changes = 150,
        },
        cmd = {
            "clangd",
            "--clang-tidy",
            "--compile-commands-dir=build", -- Adjust according to your project structure
            "--enable-config",               -- Use .clangd config file if present
        },
    }
    end,

})

cmp.setup({
  sources = {
    {name = 'nvim_lsp'},
  },
  mapping = {
    ['<C-Return>'] = cmp.mapping.confirm({select = false}),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<Up>'] = cmp.mapping.select_prev_item({behavior = 'select'}),
    ['<Down>'] = cmp.mapping.select_next_item({behavior = 'select'}),
    ['<C-p>'] = cmp.mapping(function()
      if cmp.visible() then
        cmp.select_prev_item({behavior = 'insert'})
      else
        cmp.complete()
      end
    end),
    ['<C-n>'] = cmp.mapping(function()
      if cmp.visible() then
        cmp.select_next_item({behavior = 'insert'})
      else
        cmp.complete()
      end
    end),
  },
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
})


