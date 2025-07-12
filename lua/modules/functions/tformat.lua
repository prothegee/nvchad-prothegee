local THIS = {}

function THIS.json_format_with_indent(data, indent_space)
    indent_space = indent_space or 4

    local indent = string.rep(" ", indent_space)
    local json = vim.json.encode(data)
    local result = ""
    local level = 0
    local in_string = false

    for i = 1, #json do
        local char = json:sub(i, i)

        -- string literal, skip formating inside string
        if char == '"' and json:sub(i-1,i-1) ~= "\\" then
            in_string = not in_string
        end

        if not in_string then
            if char == "{" or char == "[" then
                -- opening brace, increase indent
                result = result .. char .. "\n" .. string.rep(indent, level + 1)
                level = level + 1
            elseif char == "}" or char == "]" then
                -- closing brace, decrease indent
                level = math.max(level - 1, 0)
                result = result .. "\n" .. string.rep(indent, level) .. char
            elseif char == "," then
                -- comma, new line with current indent
                result = result .. char .. "\n" .. string.rep(indent, level)
            elseif char == ":" then
                -- colon, add space after
                result = result .. char .. " "
            else
                -- regular character
                result = result .. char
            end
        else
            -- inside string, add character as-is
            result = result .. char
        end
    end

    return result
end

return THIS

