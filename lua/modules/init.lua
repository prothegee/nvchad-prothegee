local _nvim = require "modules.partials.nvim"
local _session = require "modules.partials.session"
local _command_center = require "modules.command-center"

_nvim.initialize()

_session.initialize()

-- _command_center.initialize() -- postpone
_command_center.register_default_keymap()
_command_center.register_default_command()

