local this = {}

--#region local
local _nvim = require "modules.functions.nvim"
local _telescope = {
    picker = require("telescope.pickers"),
    finder = require("telescope.finders"),
    config = require("telescope.config"),
    actions = require("telescope.actions"),
    action_state = require("telescope.actions.state")
}
local _tformat = require "modules.functions.tformat"
--#endregion

--#region vars
this.template = {
    nvim_cmake_content = [[
    {
        "preset": 0,
        "preset_name": "debug"
    }
    ]],
    nvim_cmake_content_path = ".nvim/nvim-cmake.json"
}
--#endregion

--#region tooling
--- # create nvim cmake
--- ---
--- # note
--- * will create `.nvim/nvim-cmake.json` at current dir
function this.create_nvim_cmake()
    local destination = vim.fn.getcwd() .. "/" .. this.template.nvim_cmake_content_path

    if vim.loop.fs_stat(destination) then
        vim.notify("INFO: \"" .. destination .. "\" already exists", vim.log.levels.INFO)
        return
    end

    local file = io.open(destination, "w")

    if not file then
        vim.notify("ERROR: failed to create \"" .. destination .. "\"", vim.log.levels.ERROR)
        return
    end

    if not file:write(this.template.nvim_cmake_content) then
        vim.notify("ERROR: failed to write nvim-cmake.json", vim.log.levels.ERROR)
        return
    end

    if not file:close() then
        vim.notify("ERROR: fail to close nvim-cmake.json", vim.log.levels.ERROR)
        return
    end
end

--- # get nvim cmake data
--- ---
--- # note
--- * get existing data from `.nvim/nvim-cmake.json` at current dir
--- ---
--- # return
--- object = { preset, preset_name }
function this.get_nvim_cmake_data()
    local result = {
        preset = 0,
        preset_name = "debug"
    }

    local nvim_cmake_file = vim.fn.getcwd() .. "/" .. this.template.nvim_cmake_content_path

    if vim.loop.fs_stat(nvim_cmake_file) then
        this.create_nvim_cmake()
        nvim_cmake_file = vim.fn.getcwd() .. "/" .. this.template.nvim_cmake_content_path
    end

    local file, open_err = io.open(nvim_cmake_file, "r")
    if not file then
        vim.notify("ERROR: can't open nvim-cmake.json: " .. (open_err or "unknown error"), vim.log.levels.ERROR)
        return result
    end

    local content, read_err = file:read("*a")
    if not content then
        vim.notify("ERROR: can't read nvim-cmake.json: " .. (read_err or "unknown error"), vim.log.levels.ERROR)
        file:close()
        return result
    end

    local close_ok, close_err = file:close()
    if not close_ok then
        vim.notify("WARNING: can't close nvim-cmake.json: " .. (close_err or "unknown error"), vim.log.levels.WARN)
    end

    content = content:gsub("//.-[\r\n]", "")

    local ok, data = pcall(vim.json.decode, content)
    if not ok then
        vim.notify("ERROR: fail to decode nvim-cmake.json: " .. (data or "unknown error"), vim.log.levels.ERROR)
        return result
    end

    result.preset = data.preset or result.preset
    result.preset_name = data.preset_name or result.preset_name

    return result
end

function this.set_nvim_cmake_data(preset, preset_name)
    local cache = vim.fn.getcwd() .. "/" .. this.template.nvim_cmake_content_path

    if not cache then
        vim.notify("ERROR: " .. cache .. " doesn't exists", vim.log.levels.ERROR)
        return false
    end

    local data_write = {
        preset = preset,
        preset_name = preset_name
    }
    local data_json = _tformat.json_format_with_indent(data_write, 4)

    local file, file_error = io.open(cache, "w")

    if not file then
        vim.notify("ERROR: fail to open file: " .. (file_error or "unknown error"), vim.log.levels.ERROR)
        return false
    end

    local write, write_error = file:write(data_json)

    if not write then
        vim.notify("ERROR: fail to write file: " .. (write_error or "unknown error"), vim.log.levels.ERROR)
        file:close()
        return false
    end

    local close, close_error = file:close()

    if not close then
        vim.notify("ERROR: fail to close file: " .. (close_error or "unknown error"), vim.log.levels.ERROR)
        return false
    end

    return true
end
--#endregion

--#region core
this.preset_init_hint = "CMake: Preset Init"
function this.preset_init()
    vim.notify(this.preset_init_hint)

    this.create_nvim_cmake()

    local source
    if _nvim.os.windows then
        source = vim.env.LOCALAPPDATA .. "/nvim/template/json/CMakePresets.json"
    else
        source = vim.loop.os_homedir() .. "/.config/nvim/template/json/CMakePresets.json"
    end

    local destination = vim.fn.getcwd() .. "/CMakePresets.json"

    if not vim.loop.fs_stat(source) then
        vim.notify("ERROR: " .. source .. " not found", vim.log.levels.ERROR)
        return
    end

    if vim.loop.fs_stat(destination) then
        vim.notify("CMakePresets.json already exists", vim.log.levels.INFO)
    end

    local file, file_error = io.open(source, "r")

    if not file then
        vim.notify("ERROR: fail to open file: " .. (file_error or "unknown error"), vim.log.levels.ERROR)
        return
    end

    local content, content_error = file:read("*a")

    if not content then
        vim.notify("ERROR: fail to read content: " .. (content_error or "unknown error"), vim.log.levels.ERROR)
        return
    end

    local outfile, outfile_error = io.open(destination, "w")

    if not outfile then
        vim.notify("ERROR: fail to open write file: " .. (outfile_error or "unknown error"), vim.log.levels.ERROR)
        return
    end

    local write, write_error = outfile:write(content)

    if not write then
        vim.notify("ERROR: fail to write file: " .. (write_error or "unknown error"), vim.log.levels.ERROR)
        outfile:close()
        return
    end

    local close, close_error = outfile:close()

    if not close then
        vim.notify("ERROR: fail to close file: " .. (close_error or "unknown error"), vim.log.levels.ERROR)
        return
    end
end

this.preset_select_hint = "CMake: Preset Select"
function this.preset_select()
    local file_path = vim.fn.getcwd() .. "/CMakePresets.json"

    if not file_path then
        vim.notify("ERROR: can't find CMakePresets.json in " .. vim.fn.getcwd())
        return
    end

    local file, file_error = io.open(file_path, "r")

    if not file then
        vim.notify("ERROR: can't open file: " .. (file_error or "unknown error"), vim.log.levels.ERROR)
        return
    end

    local content, content_error = file:read("*a")

    if not content then
        vim.notify("ERROR: fail to read content: " .. (content_error or "unknown error"), vim.log.levels.ERROR)
        file:close()
        return
    end

    content = content:gsub("//.-[\r\n]", "")

    local data_ok, data_json = pcall(vim.json.decode, content)

    if not data_ok or not data_json.configurePresets then
        vim.notify("ERROR: fail to parse CMakePresets.json", vim.log.levels.ERROR)
        return
    end

    local presets = {}

    for index, preset in ipairs(data_json.configurePresets) do
        table.insert(presets, {
            idx = index - 1, -- make 0-based index
            name = preset.name,
            display_name = preset.displayName or preset.name
        })
    end

    if #presets == 0 then
        vim.notify("ERROR: no presets found for some reason", vim.log.levels.ERROR)
        return
    end

    _telescope.picker.new({
        prompt_title = "Select CMake Preset",
        finder = _telescope.finder.new_table({
            results = presets,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry.display_name,
                    ordinal = entry.display_name,
                }
            end,
        }),
        sorter = _telescope.config.values.generic_sorter({}),

        attach_mappings = function(prompt_bufnr) -- has map option?
            _telescope.actions.select_default:replace(function()
                _telescope.actions.close(prompt_bufnr)

                local selection = _telescope.action_state.get_selected_entry()

                if selection and selection.value then
                    local preset = selection.value

                    this.set_nvim_cmake_data(preset.idx, preset.name)

                    vim.notify("INFO: selected preset: " .. preset.display_name, vim.log.levels.INFO)
                else
                    vim.notify("ERROR: selection is not valid", vim.log.levels.ERROR)
                    return false
                end
            end)
            return true
        end,
    }):find()
end

this.project_clean_hint = "CMake: Project Clean"
function this.project_clean()
    vim.notify(this.project_clean_hint)
end

this.project_configure_hint = "CMake: Project Configure"
function this.project_configure()
    vim.notify(this.project_configure_hint)
end

this.project_configure_clean_hint = "CMake: Project Configure Clean"
function this.project_configure_clean()
    vim.notify(this.project_configure_clean_hint)
end

this.project_build_hint = "CMake: Project Build"
function this.project_build()
    vim.notify(this.project_build_hint)
end
--#endregion

return this

