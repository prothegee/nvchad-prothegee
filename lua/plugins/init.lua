require "modules.command-center"

return {
    {
        "stevarc/conform.nvim",
        -- event = "BufWritePre",
        opts = require "configs.conform"
    },

    {
        "neovim/nvim-lspconfig",
        lazy = false,
        opts = {
            ensure_installed = {
                "bashls",
                "clangd", "neocmake",
                "rust_analyzer",
                "ts_ls",
                "svelte",
                "html", "cssls",
                "jsonls",
                "vimls",
                "markdown_oxide",
            }
        },
        run = ":MasonInstallAll",
        config = function()
            require "configs.lsp"
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        opts = {
            ensure_installed = {
                "bash",
                "c", "cpp", "cmake", "make",
                "rust",
                "javascript", "typescript",
                "svelte",
                "html", "css", "scss",
                "json", "jsonc",
                "vim", "vimdoc",
                "markdown",
            }
        },
        run = ":TSUpdate",
    },

    {
        "nvim-telescope/telescope.nvim",
        lazy = false,
        requires = {
            { "nvim-lua/plenary.nvim" }
        },
    },

    {
        import = "nvchad.blink.lazyspec"
    },
}

