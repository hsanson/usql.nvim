local config = require("usql.config")
local yarepl = require("yarepl")

local M = {}

-- Look for the statement closest to current cursor position
-- using Tree-sitter SQL parser.
local find_current_statement = function()
    local ts = vim.treesitter

    local current_node = ts.get_node()
    while current_node and current_node:type() ~= "statement" do
        current_node = current_node:parent()
    end

    if current_node then
        local r1, c1, _ = current_node:start()
        local r2, c2, _ = current_node:end_()

        local sql_file = current_node:parent()

        local current_node_idx = 1
        if sql_file and sql_file:type() == "program" then
            -- Find the current node index
            for node in sql_file:iter_children() do
                if node:id() == current_node:id() then
                    break
                end
                current_node_idx = current_node_idx + 1
            end

            return {
                start_line = r1,
                start_col = c1,
                end_line = r2,
                end_col = c2
            }
        else
            vim.notify("usql: SQL statement syntax error", vim.levels.log.ERROR)
        end
    end

    return nil
end

local find_statement_strings = function(bufnr, start_line, start_col, end_line, end_col)
    local statement = vim.api.nvim_buf_get_text(bufnr, start_line, start_col, end_line, end_col, {})

    -- Filter out empty strings and commented lines
    statement =
        vim.tbl_filter(
        function(line)
            local trimmed = vim.trim(line)
            return trimmed ~= "" and not string.match(trimmed, "^%-%-")
        end,
        statement
    )

    -- Add ";" to last element if needed
    if #statement > 0 then
        local last_line = statement[#statement]
        local trimmed_last = vim.trim(last_line)
        if not string.match(trimmed_last, ";$") and not string.match(trimmed_last, "\\G$") then
            statement[#statement] = last_line .. ";\r"
        end
    end

    return statement
end

M.cmd = function()
    local usql_path = vim.fs.normalize(config.usql_path)

    if vim.fn.executable(usql_path) == 0 then
        vim.notify(string.format("usql: binary `%s` not found or not execuable", usql_path), vim.log.levels.ERROR)
        return {}
    end

    return {usql_path, "-q", "--pset", "pager=off", "-w"}
end

M.formatter = function(lines)
    for i, line in ipairs(lines) do
        -- Trim leading and trailing whitespace
        lines[i] = line:match("^%s*(.-)%s*$")
        -- Replace multiple spaces with a single space
        lines[i] = lines[i]:gsub("%s+", " ")
    end

    -- Remove empty lines from the list
    for i = #lines, 1, -1 do
        if lines[i] == "" then
            table.remove(lines, i)
        end
    end

    -- Add ";\r" to the last line if it doesn't start with "\"
    if lines[#lines]:match("^\\") then
        lines[#lines] = lines[#lines] .. "\r"
    elseif lines[#lines]:match(";$") then
        lines[#lines] = lines[#lines] .. "\r"
    else
        lines[#lines] = lines[#lines] .. ";\r"
    end

    return lines
end

M.send_statement = function()
    local current_buffer = vim.api.nvim_get_current_buf()

    local statement = find_current_statement()

    if statement == nil then
      vim.notify("usql: no SQL statement found", vim.levels.log.WARNING)
      return
    end

    local str = find_statement_strings(
      current_buffer,
      statement.start_line,
      statement.start_col,
      statement.end_line,
      statement.end_col
    )

    yarepl._send_strings(0, nil, current_buffer, str)
end

M.send_buffer = function()
    local current_buffer = vim.api.nvim_get_current_buf()

    local str = find_statement_strings(
      current_buffer,
      0,
      0,
      -1,
      -1
    )

    yarepl._send_strings(0, nil, current_buffer, str)
end

-- Safe wrapper for REPLSendVisual that handles the last line without newline issue
M.send_visual = function(opts)
    local id = opts.count or 0
    local name = opts.args or ""
    local current_buffer = vim.api.nvim_get_current_buf()

    vim.api.nvim_feedkeys('\27', 'nx', false)

    local visual_mode = vim.fn.visualmode()
    
    -- Safe implementation of get_lines that handles last line without newline
    local begin_mark = "'<"
    local end_mark = "'>"

    local begin_pos = vim.fn.getpos(begin_mark)
    local end_pos = vim.fn.getpos(end_mark)

    local begin_line = begin_pos[2]
    local begin_col = begin_pos[3]
    local end_line = end_pos[2]
    local end_col = end_pos[3]

    local lines
    if visual_mode == 'v' or visual_mode == 'char' then
        lines = vim.api.nvim_buf_get_text(0, begin_line - 1, begin_col - 1, end_line - 1, -1, {})
        if #lines > 0 and #lines[#lines] > 0 then
            if begin_line == end_line then
                end_col = end_col - begin_col + 1
            end
            -- Cap end_col to line length to avoid index out of range
            end_col = math.min(end_col, #lines[#lines])
            local offset = vim.str_utf_end(lines[#lines], end_col)
            lines[#lines] = lines[#lines]:sub(1, end_col + offset)
        end
    else
        -- Line-wise mode
        lines = vim.api.nvim_buf_get_lines(0, begin_line - 1, end_line, false)
    end

    if #lines == 0 then
        vim.notify 'No visual range!'
        return
    end

    yarepl._send_strings(id, name, current_buffer, lines)
end

return M
