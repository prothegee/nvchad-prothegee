local this = {}

this.os = {
    windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
}

this.dirs = {
    nvim_command_center = ".nvim/command-center"
}

function this.initialize()
    local dir_current = vim.fn.getcwd()
    local dir_to_create = dir_current .. "/" .. this.dirs.nvim_command_center

    if vim.fn.isdirectory(dir_to_create) == 0 then
        vim.notify("INFO: creating \"" .. dir_to_create .. "\"", vim.log.levels.INFO)
        vim.fn.mkdir(dir_to_create, "p")
    end
end

function this.keymap_is_exists(mode, lhs)
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
        if map.lhs == lhs then
            return true
        end
    end

    return false
end

function this.del_keymap_safe(mode, lhs)
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

--#region postpone
-- function this.get_all_buffers()
--     return nil
-- end
--
-- function this.get_active_buffer()
--     local result = vim.api.nvim_buf_get_name(0)
--
--     if result ~= "" then
--         return result
--     end
--
--     return nil
-- end
--
-- function this.get_current_file()
--     local result = vim.fn.expand("%:t")
--
--     if result ~= "" then
--         return result
--     end
--
--     return nil
-- end
--
-- function this.get_current_file_with_path()
--     local result = vim.fn.expand("%:p")
--
--     if result ~= "" then
--         return result
--     end
--
--     return nil
-- end
--#endregion

return this

