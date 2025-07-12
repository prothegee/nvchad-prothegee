local this = {}

local _actions = require("telescope.actions")
local _action_state = require("telescope.actions.state")

local _nvim = require "modules.functions.nvim"
local _cmake = require "modules.partials.cmake"

--#region global
-- command center default collections
this.default = {
    mode = {
        all = { "i", "n" },
        insert = "i",
        normal = "n"
    },
    lhs = "<C-S-p>",
    command = "NVimCommandCenter",
    description = "NVim Command Center Interface ( ctrl+shift+pp )"
}

-- commands collection
this.commands = {
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
    [_cmake.project_configure_clean_hint] = function()
        _cmake.project_configure_clean()
    end,

    [_cmake.project_build_hint] = function()
        _cmake.project_build()
    end
    --#endregion
}

this.prompt_title = "NVim Command Center"

-- show this ui
function this.show_ui()
    _nvim.initialize()

    require('telescope.pickers').new({
        prompt_title = this.promp_title,
        finder = require('telescope.finders').new_table({
            results = vim.tbl_keys(this.commands),
        }),
        sorter = require('telescope.config').values.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            _actions.select_default:replace(function()
                _actions.close(prompt_bufnr)
                local selection = _action_state.get_selected_entry()
                local cmd = this.commands[selection[1]]

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
function this.register_default_command()
    vim.api.nvim_create_user_command(this.default.command, this.show_ui, {})
end
-- register remove default command
function this.register_remove_default_command()
    vim.api.nvim_del_user_command(this.default.command)
    vim.notify("INFO: removing `" .. this.default.command .. "` command", vim.log.levels.INFO)
end

-- register default keymap
function this.register_default_keymap()
    if _nvim.keymap_is_exists(this.default.mode.insert, this.default.lhs) then
        vim.notify("ERROR: `" .. this.default.mode.insert .. "` `" .. this.default.lhs .. "` already exists", vim.log.levels.ERROR)
        return
    end

    if _nvim.keymap_is_exists(this.default.mode.normal, this.default.lhs) then
        vim.notify("ERROR: `" .. this.default.mode.normal .. "` `" .. this.default.lhs .. "` already exists", vim.log.levels.ERROR)
        return
    end

    vim.keymap.set(this.default.mode.all, this.default.lhs, ":" .. this.default.command .. "<CR>", {
        desc = this.default.description,
        silent = true
    })
end
-- register remove default keymap
function this.register_remove_default_keymap()
    _nvim.del_keymap_safe(this.default.mode.insert, this.default.lhs)
    _nvim.del_keymap_safe(this.default.mode.normal, this.default.lhs)
end
--#endregion

return this

