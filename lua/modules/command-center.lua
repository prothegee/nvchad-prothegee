local M = {}

local _actions = require("telescope.actions")
local _action_state = require("telescope.actions.state")
local _pickers = require("telescope.pickers")
local _finders = require("telescope.finders")
local _configs = require("telescope.config")

local _nvim = require "modules.partials.nvim"
local _cmake = require "modules.partials.cmake"

--#region global
-- command-center default collections
M.default = {
    mode = {
        all = { "i", "n" },
        insert = "i",
        normal = "n"
    },
    lhs = "<C-A-p>",
    command = "NVimCommandCenter",
    description = "NVim Command Center Interface ( ctrl + alt + p )"
}

M.prompt_title = "NVim Command Center"

-- command-center dirs collections
M.dirs = {
    nvim_command_center = ".nvim/command-center"
}

-- command-center commands collections
M.commands = {
    --#region cmake
    [_cmake.preset_init_hint] = function()
        _cmake.preset_init()
    end,
    [_cmake.preset_select_hint] = function()
        _cmake.preset_select()
    end,

    [_cmake.project_clean_hint] = function()
        _cmake.project_clean()
    end,
    [_cmake.project_configure_hint] = function()
        _cmake.project_configure()
    end,
    [_cmake.project_cofigure_clean_hint] = function()
        _cmake.project_configure_clean()
    end,
    [_cmake.project_configure_clean_remove_hint] = function()
        _cmake.project_configure_clean_remove()
    end,

    [_cmake.project_build_hint] = function()
        _cmake.project_build()
    end,
    --#endregion

    --#region search and replace
    --#endregion

    --#regiont tformat
    --#endregion
}

-- initialize command-center
function M.initialize()
    local dir_current = vim.fn.getcwd()
    local dir_to_create = dir_current .. "/" .. M.dirs.nvim_command_center

    if vim.fn.isdirectory(dir_to_create) == 0 then
        vim.notify("INFO: creating \"" .. dir_to_create .. "\"", vim.log.levels.INFO)
        vim.fn.mkdir(dir_to_create, "p")
    end
end

-- show command-center ui
function M.show_ui()
    -- get and sort command keys alphabetically
    local command_keys = vim.tbl_keys(M.commands)
    table.sort(command_keys, function(a, b)
        return a:lower() < b:lower()  -- case-insensitive sorting
    end)

    _pickers.new({
        prompt_title = M.prompt_title,
        finder = _finders.new_table({
            results = command_keys,
        }),
        sorter = _configs.values.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            _actions.select_default:replace(function()
                _actions.close(prompt_bufnr)
                local selection = _action_state.get_selected_entry()
                local cmd = M.commands[selection.value]

                -- check cmd type
                if type(cmd) == "function" then
                    cmd()
                else -- execute as nvim command
                    vim.cmd(cmd)
                end
            end)
            return true
        end,
    }):find()
end

-- register default command
function M.register_default_command()
    vim.api.nvim_create_user_command(M.default.command, M.show_ui, {})
end
-- register remove default command
function M.register_remove_default_command()
    vim.api.nvim_del_user_command(M.default.command)
    vim.notify("INFO: removing `" .. M.default.command .. "` command", vim.log.levels.INFO)
end

-- register default keymap
function M.register_default_keymap()
    if _nvim.keymap_is_exists(M.default.mode.insert, M.default.lhs) then
        vim.notify("ERROR: `" .. M.default.mode.insert .. "` `" .. M.default.lhs .. "` already exists", vim.log.levels.ERROR)
        return
    end

    if _nvim.keymap_is_exists(M.default.mode.normal, M.default.lhs) then
        vim.notify("ERROR: `" .. M.default.mode.normal .. "` `" .. M.default.lhs .. "` already exists", vim.log.levels.ERROR)
        return
    end

    vim.keymap.set(M.default.mode.all, M.default.lhs, function()
        if vim.api.nvim_get_mode().mode == "i" then
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
        end

        M.show_ui()
    end, {
        desc = M.default.description,
        silent = true
    })
end
-- register remove default keymap
function M.register_remove_default_keymap()
    _nvim.del_keymap_safe(M.default.mode.insert, M.default.lhs)
    _nvim.del_keymap_safe(M.default.mode.normal, M.default.lhs)
end
--#endregion

return M

