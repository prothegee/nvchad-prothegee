local M = {}

M.os = {
    windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
}

function M.initialize()
    local dir_current = vim.fn.getcwd()
    local dir_to_create = dir_current .. "/.nvim"

    if vim.fn.isdirectory(dir_to_create) == 0 then
        vim.notify("INFO: creating \"" .. dir_to_create .. "\"", vim.log.levels.INFO)
        vim.fn.mkdir(dir_to_create, "p")
    end
end

function M.keymap_is_exists(mode, lhs)
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
        if map.lhs == lhs then
            return true
        end
    end

    return false
end

function M.del_keymap_safe(mode, lhs)
    local existing = vim.api.nvim_get_keymap(mode)
    for _, map in ipairs(existing) do
        if map.lhs == lhs then
            vim.notify("INFO: deleting keymap for `" .. mode .. "` `" .. lhs .. "`", vim.log.levels.INFO)
            vim.api.nvim_del_keymap(mode, lhs)
            return true
        end
    end

    vim.notify("INFO: skiping safe delete keymap since not exists", vim.log.levels.INFO)

    return false
end

function M.create_floating_terminal(command, title)
    local buf = vim.api.nvim_create_buf(false, true)

    local width = math.floor(vim.o.columns * 0.9)
    local height = math.floor(vim.o.lines * 0.9)

    local window = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = (vim.o.columns - width) / 2,
        row = (vim.o.lines - height) / 2 -1,
        style = "minimal",
        border = "rounded",
        title = title or "Terminal Output",
        title_pos = "center"
    })

    vim.cmd("terminal " .. command)

    vim.api.nvim_set_option_value("modified", false, { buf = buf })
    vim.api.nvim_set_option_value("filetype", "terminal", { buf = buf })

    vim.keymap.set("n", "<Esc>", "<cmd>close!<CR>", { buffer = buf, silent = true })
    vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { buffer = buf, silent = true })

    vim.cmd("startinsert")

    return window
end

--#region postpone
-- function M.get_all_buffers()
--     return nil
-- end
--
-- function M.get_active_buffer()
--     local result = vim.api.nvim_buf_get_name(0)
--
--     if result ~= "" then
--         return result
--     end
--
--     return nil
-- end
--
-- function M.get_current_file()
--     local result = vim.fn.expand("%:t")
--
--     if result ~= "" then
--         return result
--     end
--
--     return nil
-- end
--
-- function M.get_current_file_with_path()
--     local result = vim.fn.expand("%:p")
--
--     if result ~= "" then
--         return result
--     end
--
--     return nil
-- end
--#endregion

return M

