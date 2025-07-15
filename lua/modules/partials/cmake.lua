local M = {}

local _nvim = require "modules.partials.nvim"
local _telescope = {
    picker = require("telescope.pickers"),
    finder = require("telescope.finders"),
    config = require("telescope.config"),
    actions = require("telescope.actions"),
    action_state = require("telescope.actions.state")
}
local _tformat = require "modules.partials.tformat"

-- this module actual name to be use
M.name = "NVimCMake"

-- template collections
M.template = {
    nvim_cmake_content = [[
    {
        "preset": 0,
        "preset_name": "debug"
    }
    ]],
}

-- file collections
M.file = {
    cmake_lists_txt = "CMakeLists.txt",
    cmake_presets_json = "CMakePresets.json",
    cmake_compile_commands_json = "compile_commands.json",
    nvim_cmake_content_path = ".nvim/nvim-cmake.json",
}

-- # create nvim cmake
-- ---
-- # note
-- * will create `.nvim/nvim-cmake.json` at current dir
function M.create_nvim_cmake()
    local destination = vim.fn.getcwd() .. "/" .. M.file.nvim_cmake_content_path

    if vim.loop.fs_stat(destination) then
        vim.notify("INFO: \"" .. destination .. "\" already exists", vim.log.levels.INFO)
        return
    end

    local file = io.open(destination, "w")

    if not file then
        vim.notify("ERROR: failed to create \"" .. destination .. "\"", vim.log.levels.ERROR)
        return
    end

    if not file:write(M.template.nvim_cmake_content) then
        vim.notify("ERROR: failed to write nvim-cmake.json", vim.log.levels.ERROR)
        return
    end

    if not file:close() then
        vim.notify("ERROR: fail to close nvim-cmake.json", vim.log.levels.ERROR)
        return
    end
end

-- # get nvim cmake data
-- ---
-- # note
-- * get existing data from `.nvim/nvim-cmake.json` at current dir
-- ---
-- # return
-- object = { preset, preset_name }
function M.get_nvim_cmake_data()
    local result = {
        preset = 0,
        preset_name = "debug"
    }

    local nvim_cmake_file = vim.fn.getcwd() .. "/" .. M.file.nvim_cmake_content_path

    if vim.loop.fs_stat(nvim_cmake_file) then
        M.create_nvim_cmake()
        nvim_cmake_file = vim.fn.getcwd() .. "/" .. M.file.nvim_cmake_content_path
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

    return {
        preset = result.preset,
        preset_name = result.preset_name
    }
end

-- # set nvim cmake data
-- ---
-- # params
-- * preset - number
-- * preseet_name - string
-- ---
-- # return
-- boolean
function M.set_nvim_cmake_data(preset, preset_name)
    local cache = vim.fn.getcwd() .. "/" .. M.file.nvim_cmake_content_path

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

-- # get cmake preset data
-- ---
-- # note
-- * this function related with CMakePresets.json & .nvim/nvim-cmake.json
-- * return value will be based on configurePresets index
function M.get_cmake_preset_data()
    local file = io.open(vim.fn.getcwd() .. "/" .. M.file.cmake_presets_json)

    if not file then
        vim.notify("ERROR: can't find " .. M.file.cmake_presets_json, vim.log.levels.ERROR)
        return nil
    end

    local content = file:read("*a")
    file:close()

    content = content:gsub("//.-[\r\n]", "")

    local ok, presets = pcall(vim.json.decode, content)

    if not ok then
        vim.notify("ERROR: fail to decode contnet as preset", vim.log.levels.ERROR)
        return nil
    end

    if not presets.configurePresets or type(presets.configurePresets) ~= "table" then
        vim.notify("ERROR: configurePresets key not found", vim.log.levels.ERROR)
        return nil
    end

    local nvim_cmake = M.get_nvim_cmake_data()

    if not nvim_cmake or not nvim_cmake.preset then
        vim.notify("ERROR: \"preset\" key not found", vim.log.levels.ERROR)
        return nil
    end

    local preset = nvim_cmake.preset + 1

    if preset < 1 or preset > #presets.configurePresets then
        vim.notify("ERROR: wrong preset index, (" .. preset .. ") out of range", vim.log.levels.ERROR)
        return nil
    end

    local data = presets.configurePresets[preset]

    if not data or type(data) ~= "table" then
        vim.notify("ERROR: wrong preset data from preset index", vim.log.levels.ERROR)
        return nil
    end

    if not data.name then
        vim.notify("ERROR: preset missing \"name\" key", vim.log.levels.ERROR)
        return nil
    end

    if not data.binaryDir then
        vim.notify("ERROR: preset missing \"binaryDir\" key", vim.log.levels.ERROR)
        return nil
    end

    if nvim_cmake.preset_name and data.name ~= nvim_cmake.preset_name then
        vim.notify(string.format("ERROR: preset name not match, cache=%s, preset=%s", nvim_cmake.preset_name, data.name), vim.log.levels.ERROR)
        return nil
    end

    return data
end

M.preset_init_hint = "CMake: Preset Init"
-- # cmake preset init
-- ---
-- # note
-- * will create CMakePresets.json if doesn't exists
-- * has corelation with .nvim/nvim-cmake.json
function M.preset_init()
    vim.notify(M.preset_init_hint)

    M.create_nvim_cmake()

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

M.preset_select_hint = "CMake: Preset Select"
-- # cmake preset select
-- ---
-- # note
-- * will sellect preset from CMakePresets.json
-- * has corelation with .nvim/nvim-cmake.json
-- * selected preset will be save to .nvim/nvim-cmake.json

function M.preset_select()
    local file_path = vim.fn.getcwd() .. "/" .. M.file.cmake_presets_json

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

                    M.set_nvim_cmake_data(preset.idx, preset.name)

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

M.project_clean_hint = "CMake: Project Clean"
function M.project_clean()
    vim.notify("TODO: " .. M.project_clean_hint)
end

M.project_configure_hint = "CMake: Project Configure"
-- # cmake project configure
-- ---
-- # note
-- * will configure from selected preset
-- * has corelation with CMakePresets.json & .nvim/nvim-cmake.json
function M.project_configure()
    local preset = M.get_cmake_preset_data()

    if preset == nil then
        vim.notify("ERROR: preset error", vim.log.levels.ERROR)
        return
    end

    local cache_vars = {}

    if preset.cacheVariables then
        for key, val in pairs(preset.cacheVariables) do
            table.insert(cache_vars, string.format("-D%s=%s", key, tostring(val)))
        end
    end

    local binary_dir = preset.binaryDir:gsub("${sourceDir}", vim.fn.getcwd())

    local cmake_cmd = string.format(
        "cmake -G\"%s\" -S\"%s\" -B\"%s\" %s",
        preset.generator,
        vim.fn.getcwd(),
        binary_dir,
        table.concat(cache_vars, " ")
    )

    _nvim.create_floating_terminal(cmake_cmd, (M.project_configure_hint .. " - " .. preset.displayName))
end

M.project_cofigure_clean_hint = "CMake: Project Configure Clean"
-- # cmake project configure clean
-- ---
-- # note
-- * same as project_configure, but will clean target build dir first
-- * will configure from selected preset
-- * has corelation with CMakePresets.json & .nvim/nvim-cmake.json
function M.project_configure_clean()
    local preset = M.get_cmake_preset_data()

    if preset == nil then
        vim.notify("ERROR: preset error", vim.log.levels.ERROR)
        return
    end

    local cache_vars = {}

    if preset.cacheVariables then
        for key, val in pairs(preset.cacheVariables) do
            table.insert(cache_vars, string.format("-D%s=%s", key, tostring(val)))
        end
    end

    local binary_dir = preset.binaryDir:gsub("${sourceDir}", vim.fn.getcwd())

    local cmake_cmd = string.format(
        "cmake --build %s --target clean && cmake -G\"%s\" -S\"%s\" -B\"%s\" %s",
        binary_dir,
        preset.generator,
        vim.fn.getcwd(),
        binary_dir,
        table.concat(cache_vars, " ")
    )

    _nvim.create_floating_terminal(cmake_cmd, (M. project_configure_clean_hint .. " - " .. preset.displayName))
end

M.project_configure_clean_remove_hint = "CMake: Project Configure Clean Remove"
-- # cmake project configure clean remove
-- ---
-- # note
-- * same as project_configure, but will remove (not --taget clean) build dir first
-- * will configure from selected preset
-- * has corelation with CMakePresets.json & .nvim/nvim-cmake.json
function M.project_configure_clean_remove()
    local preset = M.get_cmake_preset_data()

    if preset == nil then
        vim.notify("ERROR: preset error", vim.log.levels.ERROR)
        return
    end

    local cache_vars = {}

    if preset.cacheVariables then
        for key, val in pairs(preset.cacheVariables) do
            table.insert(cache_vars, string.format("-D%s=%s", key, tostring(val)))
        end
    end

    local binary_dir = preset.binaryDir:gsub("${sourceDir}", vim.fn.getcwd())

    local cmake_cmd = string.format(
        "rm -rf %s && cmake -G\"%s\" -S\"%s\" -B\"%s\" %s",
        binary_dir,
        preset.generator,
        vim.fn.getcwd(),
        binary_dir,
        table.concat(cache_vars, " ")
    )

    _nvim.create_floating_terminal(cmake_cmd, (M.project_configure_clean_remove_hint .. " - " .. preset.displayName))
end

M.project_build_hint = "CMake: Project Build"
-- # cmake project build
-- ---
-- # note
-- * will build from selected preset as default build
-- * has corelation with CMakePresets.json & .nvim/nvim-cmake.json
function M.project_build()
    local preset = M.get_cmake_preset_data()

    if preset == nil then
        vim.notify("ERROR: preset error", vim.log.levels.ERROR)
        return
    end

    local cache_vars = {}

    if preset.cacheVariables then
        for key, val in pairs(preset.cacheVariables) do
            table.insert(cache_vars, string.format("-D%s=%s", key, tostring(val)))
        end
    end

    local binary_dir = preset.binaryDir:gsub("${sourceDir}", vim.fn.getcwd())

    local symlink = function()
        if not _nvim.os.windows then
            return string.format("ln -s %s/%s;", binary_dir, M.file.cmake_compile_commands_json)
        else
            return "" -- the hell happen with Windows & Mac?
        end
    end

    local cmake_cmd = string.format(
        "%scmake --build \"%s\"",
        symlink(),
        binary_dir
    )

    _nvim.create_floating_terminal(cmake_cmd, (M.project_build_hint .. " - " .. preset.displayName))
end

return M

