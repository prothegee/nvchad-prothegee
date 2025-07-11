-- require "nvchad.mappings"

local _actions = require("telescope.actions")
local _action_state = require("telescope.actions.state")

local _nvim = require "modules.functions.nvim"
local _cmake = require "modules.partials.cmake"

local _command = "NVimCommandCenter"
local _commands = {
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

local _prompt_title = "NVim Command Center"

local function nvim_command_center_palette()
    _nvim.initialize()

    require('telescope.pickers').new({
        prompt_title = _prompt_title,
        finder = require('telescope.finders').new_table({
        results = vim.tbl_keys(_commands),
    }),
    sorter = require('telescope.config').values.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
        _actions.select_default:replace(function()
            _actions.close(prompt_bufnr)
            local selection = _action_state.get_selected_entry()
            local cmd = _commands[selection[1]]

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

vim.api.nvim_create_user_command(_command, nvim_command_center_palette, {})

vim.keymap.set({"i", "n"}, "<C-S-p>", ":" .. _command .. "<CR>", {
    desc = "NVim Command Center Interface (  )",
    silent = true
})

-- vim.keymap.set({"i", "n"}, "<C-S-p>", function()
--   -- Exit insert mode if needed
--   if vim.api.nvim_get_mode().mode == "i" then
--     vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
--   end
--   nvim_command_center_palette()
-- end, {
--   desc = "NVim Command Center Interface",
--   silent = true
-- })

