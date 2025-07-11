-- ~/.config/nvim/lua/configs/conform.lua
local options = {
    formatters_by_ft = {
        -- lua = { "stylua" },
    },

    -- format_on_save = {
    --   -- These options will be passed to conform.format()
    --     timeout_ms = 300,
    --     lsp_fallback = true,
    -- },
}

return options

