local _nvim = require "modules.partials.nvim"

local M = {}

M.conf = {
    auto_save = false,
    auto_load = false
}

M.dirs = {
    nvim_session = ".nvim/session"
}

M.file = {
    nvim_tree = ".nvim/session/nvim-tree.json",
    nvim_session = ".nvim/session/session.json",
    nvim_buffers = ".nvim/session/nvim-buffer.json"
}

M.template = {
    nvim_session = [[
{
    "use_autosave": false,
    "use_autoload": false
}
]],

    nvim_session_nvim_tree = [[
{
    "is_open": false,
    "opened_dirs": []
}
]],

    nvim_session_buffers = [[
{
    "opened_buffers": []
}
]]
}

-- # initialize nvim buffers session
function M.initialize_session_buffers()
    local target_file = vim.fn.getcwd() .. "/" .. M.file.nvim_buffers
    _nvim.write_file(target_file, M.template.nvim_session_buffers)
end

-- # initialize nvim-tree session
function M.initialize_session_nvim_tree()
    local target_file = vim.fn.getcwd() .. "/" .. M.file.nvim_tree
    _nvim.write_file(target_file, M.template.nvim_session_nvim_tree)
end

-- # initialize session config
function M.initialize_session_config()
    local target_file = vim.fn.getcwd() .. "/" .. M.file.nvim_session
    _nvim.write_file(target_file, M.template.nvim_session)
end

-- # initialize autosave functionality
function M.initialize_autosave()
    local session_data = _nvim.read_json_file(vim.fn.getcwd() .. "/" .. M.file.nvim_session)
    if not session_data then return end

    M.conf.auto_save = session_data.use_autosave or false

    if M.conf.auto_save then
        -- save session on VimLeave
        vim.api.nvim_create_autocmd("VimLeave", {
            callback = function()
                _nvim.save_nvim_tree_state(M.file.nvim_tree)
                _nvim.ave_buffers_state()
            end
        })

        -- update buffers list on buffer write
        vim.api.nvim_create_autocmd("BufWritePost", {
            callback = function()
                _nvim.save_buffers_state(M.file.nvim_buffers)
            end
        })

        -- remove buffer when closed
        vim.api.nvim_create_autocmd("BufDelete", {
            callback = function(args)
                _nvim.remove_buffer_from_session(args.buf, M.file.nvim_buffers)
            end
        })
    end
end

-- # initialize autoload functionality
function M.initialize_autoload()
    local session_data = _nvim.read_json_file(vim.fn.getcwd() .. "/" .. M.file.nvim_session)
    if not session_data then return end

    M.conf.auto_load = session_data.use_autoload or false

    if M.conf.auto_load then
        _nvim.load_nvim_tree_state(M.file.nvim_tree)
        _nvim.load_buffers_state(M.file.nvim_buffers)

        -- if we have session buffers, close the initial empty buffer
        local has_session_buffers = false
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local name = vim.api.nvim_buf_get_name(buf)
            if name ~= "" and name ~= "[No Name]" then
                has_session_buffers = true
                break
            end
        end

        if has_session_buffers then
            vim.schedule(function()
                -- close all empty buffers
                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    local name = vim.api.nvim_buf_get_name(buf)
                    if name == "" or name == "[No Name]" then
                        if vim.api.nvim_buf_is_loaded(buf) and not vim.bo[buf].modified then
                            vim.api.nvim_buf_delete(buf, { force = true })
                        end
                    end
                end
            end)
        end
    end
end

-- # autosave setup UI
M.autosave_setup_hint = "Session: Autosave Setup"
function M.autosave_setup()
    local session_file = vim.fn.getcwd() .. "/" .. M.file.nvim_session
    local data = _nvim.read_json_file(session_file) or { use_autosave = false }

    data.use_autosave = not data.use_autosave
    _nvim.write_json_file(session_file, data)

    M.conf.auto_save = data.use_autosave
    vim.notify("Autosave " .. (data.use_autosave and "enabled" or "disabled"), vim.log.levels.INFO)
end

-- # autoload setup UI
M.autoload_setup_hint = "Session: Autoload Setup"
function M.autoload_setup()
    local session_file = vim.fn.getcwd() .. "/" .. M.file.nvim_session
    local data = _nvim.read_json_file(session_file) or { use_autoload = false }

    data.use_autoload = not data.use_autoload
    _nvim.write_json_file(session_file, data)

    M.conf.auto_load = data.use_autoload
    vim.notify("Autoload " .. (data.use_autoload and "enabled" or "disabled"), vim.log.levels.INFO)
end

-- # save session manually
M.save_hint = "Session: Save"
function M.save()
    _nvim.save_nvim_tree_state(M.file.nvim_tree)
    _nvim.save_buffers_state(M.file.nvim_buffers)
    vim.notify("Session saved", vim.log.levels.INFO)
end

-- # load session manually
M.load_hint = "Session: Load"
function M.load()
    _nvim.load_nvim_tree_state(M.file.nvim_tree)
    _nvim.load_buffers_state(M.file.nvim_buffers)

    -- close all empty buffers after manual load
    vim.schedule(function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local name = vim.api.nvim_buf_get_name(buf)
            if name == "" or name == "[No Name]" then
                if vim.api.nvim_buf_is_loaded(buf) and not vim.bo[buf].modified then
                    vim.api.nvim_buf_delete(buf, { force = true })
                end
            end
        end
    end)

    vim.notify("Session loaded", vim.log.levels.INFO)
end

-- # initialize
-- ---
-- # note
-- * use to call from module only as require
function M.initialize()
    local dir_current = vim.fn.getcwd()
    local dir_to_create = dir_current .. "/" .. M.dirs.nvim_session

    if vim.fn.isdirectory(dir_to_create) == 0 then
        vim.fn.mkdir(dir_to_create, "p")
    end

    if not vim.loop.fs_stat(vim.fn.getcwd() .. "/" .. M.file.nvim_tree) then
        M.initialize_session_nvim_tree()
    end

    if not vim.loop.fs_stat(vim.fn.getcwd() .. "/" .. M.file.nvim_buffers) then
        M.initialize_session_buffers()
    else
        _nvim.clean_session_files(M.file.nvim_buffers)
    end

    if not vim.loop.fs_stat(vim.fn.getcwd() .. "/" .. M.file.nvim_session) then
        M.initialize_session_config()
    end

    M.initialize_autosave()
    M.initialize_autoload()
end

return M

