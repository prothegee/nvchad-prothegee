local this = {}

this.preset_init_hint = "CMake: Preset Init"
function this.preset_init()
    vim.notify(this.preset_init_hint)
end

this.preset_select_hint = "CMake: Preset Select"
function this.preset_select()
    vim.notify(this.preset_select_hint)
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

return this

