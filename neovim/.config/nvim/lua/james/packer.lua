-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'
    use 'neanias/everforest-nvim'
    use 'mbbill/undotree'
    use 'tpope/vim-fugitive'
    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate'
    }


    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.x',
        -- or                            , branch = '0.1.x',
        requires = { {'nvim-lua/plenary.nvim'} }
    }

    use({
        'glepnir/galaxyline.nvim',
        branch = 'main',
        requires = { 'nvim-tree/nvim-web-devicons', opt = true },
    })
    -- LSP
    -- These nuts haha
    -- though for real, I'm using Zero LSP
    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        requires = {
            {'williamboman/mason.nvim'},
            {'williamboman/mason-lspconfig.nvim'},
            {'neovim/nvim-lspconfig'},
            {'hrsh7th/nvim-cmp'},
            {'hrsh7th/cmp-nvim-lsp'},
            {'L3MON4D3/LuaSnip'},
        }
    }

    use {"akinsho/toggleterm.nvim", tag = '*', config = function()
        require("toggleterm").setup()
    end}

    use {"CopilotC-Nvim/CopilotChat.nvim" , tag = '*'}

    use {"lervag/vimtex", tag = '*', config = function()
        -- VimTeX configuration goes here, e.g.
        vim.g.vimtex_view_method = "zathura"
    end}

    use({
            "stevearc/oil.nvim",
            config = function()
            end,
    })
    package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua"
    package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua"


    use {
        "3rd/image.nvim", config = function()
    end}

    use {
        'kkoomen/vim-doge',
        run = ':call doge#install()'
    }
    use {
        'anurag3301/nvim-platformio.lua',
        requires = {
            {'akinsho/nvim-toggleterm.lua'},
            {'nvim-telescope/telescope.nvim'},
            {'nvim-lua/plenary.nvim'},
        }
    }
end)
