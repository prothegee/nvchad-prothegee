local this = {}

function this.initialize()
    local dir = vim.fn.getcwd()

    vim.notify("current dir: " .. dir)
end

return this

