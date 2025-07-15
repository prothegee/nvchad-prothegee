require "nvchad.mappings"

local map = vim.keymap.set

-- i
map("i", "<Tab>", "", {})
map("i", "<Tab>", function()
    if vim.snippet.active() then
        return vim.snippet.jump(1)
    else
        -- fallback to default behavior (completion or tab)
        return "<Tab>"
        -- return vim.api.nvim_replace_termcodes("<Tab>", true, true, true) -- some suggest is just return "<Tab>"
    end
end, { expr = true, desc = "Smart Tab: jumps snippets or inserts tab" })
-- map("i", "jk", "<ESC>")
-- map("i", "<Tab>", "<Tab>", { desc = "tab space" })
--
-- -- n
-- map("n", ";", ":", { desc = "CMD enter command mode" })
-- map("n", "<Tab>", ":bnext<CR>", { desc = "go to next buffer tab" })

-- s

-- t

