local _tformat = require "modules.partials.tformat"

local M = {}

-- os list
M.os = {
    windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
}

-- initialize nvim
function M.initialize()
    local dir_current = vim.fn.getcwd()
    local dir_to_create = dir_current .. "/.nvim"

    if vim.fn.isdirectory(dir_to_create) == 0 then
        vim.fn.mkdir(dir_to_create, "p")
    end
end

-- # check keymap by mode & lhs is exists
function M.keymap_is_exists(mode, lhs)
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
        if map.lhs == lhs then
            return true
        end
    end

    return false
end

-- # to delete keymap safe by mode & lhs
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

-- # create floating terminal
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

    vim.notify("INFO: press ESC to exit", vim.log.levels.INFO)

    return window
end

-- get all buffers as an array string
function M.get_all_buffers_as_array_string()
    local buffers = {}

    for _, buffer in pairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buffer) and vim.bo[buffer].buflisted then
            local name = vim.api.nvim_buf_get_name(buffer)
            if name ~= "" then
                table.insert(buffers, name)
            end
        end
    end

    return buffers
end

-- # get current buffer as string
function M.get_active_buffer_as_string()
    local current_buf = vim.api.nvim_get_current_buf()
    return vim.api.nvim_buf_get_name(current_buf)
end

-- # write file tool #1
function M.write_file(path, content)
    local lines = vim.split(content, "\n")
    vim.fn.writefile(lines, path)
end

-- # read json file
function M.read_json_file(path)
    if not vim.loop.fs_stat(path) then
        return nil
    end

    local file = io.open(path, "r")

    if not file then
        return nil
    end

    local content = file:read("*a")

    file:close()

    local ok, data = pcall(vim.json.decode, content)

    if not ok then
        return nil
    end

    return data
end

-- # write json file
function M.write_json_file(path, data)
    local content = _tformat.json_format_with_indent(data, 4)
    M.write_file(path, content)
end

-- # remove buffer from session
function M.remove_buffer_from_session(bufnr, file_path)
    local buffers_file = vim.fn.getcwd() .. "/" .. file_path
    local data = M.read_json_file(buffers_file)
    if not data or not data.opened_buffers then return end

    local buf_path = vim.api.nvim_buf_get_name(bufnr)

    -- skip empty, [No Name], and non-file buffers
    if buf_path == "" or buf_path == "[No Name]" or vim.fn.filereadable(buf_path) ~= 1 then
        return
    end

    local new_buffers = {}
    for _, path in ipairs(data.opened_buffers) do
        if path ~= buf_path and
           path ~= "[No Name]" and
           path ~= "" then
            table.insert(new_buffers, path)
        end
    end

    data.opened_buffers = new_buffers
    M.write_json_file(buffers_file, data)
end

-- # save all active buffers state
function M.save_buffers_state(file_path)
    local buffers = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
            local name = vim.api.nvim_buf_get_name(buf)
            -- only include buffers with valid, existing files
            if name ~= "" and
               name ~= "[No Name]" and
               vim.fn.filereadable(name) == 1 then
                table.insert(buffers, name)
            end
        end
    end

    M.write_json_file(vim.fn.getcwd() .. "/" .. file_path, {
        opened_buffers = buffers
    })
end

-- clean existing session files of [No Name] entries
function M.clean_session_files(file_name)
    local buffers_file = vim.fn.getcwd() .. "/" .. file_name
    local data = M.read_json_file(buffers_file)
    if not data or not data.opened_buffers then return end

    local cleaned_buffers = {}
    for _, path in ipairs(data.opened_buffers) do

        -- only keep valid, existing files
        if path ~= "[No Name]" and
           path ~= "" and
           vim.fn.filereadable(path) == 1 then
            table.insert(cleaned_buffers, path)
        end
    end

    -- always write to ensure clean state
    data.opened_buffers = cleaned_buffers
    M.write_json_file(buffers_file, data)
end

-- # load nvim-tree state
function M.load_nvim_tree_state(file_name)
    local data = M.read_json_file(vim.fn.getcwd() .. "/" .. file_name)
    if not data then return end

    local ok, api = pcall(require, "nvim-tree.api")
    if not ok then return end

    if data.is_open and not api.tree.is_visible() then
        api.tree.open()
    elseif not data.is_open and api.tree.is_visible() then
        api.tree.close()
    end
end

-- # load buffers state (updated to skip [No Name] buffers)
function M.load_buffers_state(file_path)
    local data = M.read_json_file(vim.fn.getcwd() .. "/" .. file_path)
    if not data or not data.opened_buffers then return end

    -- track loaded buffers to prevent duplicates
    local loaded_buffers = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
            local name = vim.api.nvim_buf_get_name(buf)
            loaded_buffers[name] = true
        end
    end

    -- close all empty buffers before loading session
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        if name == "" or name == "[No Name]" then
            if vim.api.nvim_buf_is_loaded(buf) then
                vim.api.nvim_buf_delete(buf, { force = true })
            end
        end
    end

    for _, buf_path in ipairs(data.opened_buffers) do
        -- skip [No Name] and empty paths, and already loaded buffers
        if buf_path ~= "[No Name]" and
           buf_path ~= "" and
           not loaded_buffers[buf_path] and
           vim.fn.filereadable(buf_path) == 1 then
            vim.cmd("edit " .. buf_path)
            loaded_buffers[buf_path] = true  -- Mark as loaded
        end
    end
end

-- # save current nvim-tree state
function M.save_nvim_tree_state(file_path)
    local ok, api = pcall(require, "nvim-tree.api")
    if not ok then return end

    local tree_state = {
        is_open = api.tree.is_visible(),
        opened_dirs = {}
    }

    if tree_state.is_open then
        -- get current working directory as fallback
        local cwd = vim.fn.getcwd()
        tree_state.opened_dirs = {cwd}
    end

    M.write_json_file(vim.fn.getcwd() .. "/" .. file_path, tree_state)
end


return M

