local _nvim = require "modules.partials.nvim"
local _command_center = require "modules.command-center"

_nvim.initialize()

_command_center.register_default_keymap()
_command_center.register_default_command()

