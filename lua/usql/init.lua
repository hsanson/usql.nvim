local current_connection = {
  name = "",
  display = "",
  dsn  = "",
  protocol = "",
  hostname = "",
  port = "",
  database = ""
}

local job_output = {}
local utils = require("usql.utils")
local config = require("usql.config")
local tunnel = require("usql.tunnel")

local M = {}

M.UI_ID = "usql://ui"

local get_usql_buffer = function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if name == M.UI_ID then
      return buf
    end
  end
  return nil
end

local create_usql_buffer = function()
  local prev_win = vim.api.nvim_get_current_win()
  vim.cmd("keepalt " .. "split" .. " " .. M.UI_ID)
  local usql_buffer = get_usql_buffer()
  vim.api.nvim_set_current_win(prev_win)
  return usql_buffer
end

local get_job_stdout_contents = function(jid)
  job_output[jid] = job_output[jid] or {}
  job_output[jid]["stdout"] = job_output[jid]["stdout"] or {}
  return job_output[jid]["stdout"]
end

local get_job_stderr_contents = function(jid)
  job_output[jid] = job_output[jid] or {}
  job_output[jid]["stderr"] = job_output[jid]["stderr"] or {}
  return job_output[jid]["stderr"]
end

local clear_job_contents = function(jid)
  job_output[jid] = nil
end

local open_usql_buffer = function(contents)
  local usql_buffer = get_usql_buffer()

  if usql_buffer == nil then
    usql_buffer = create_usql_buffer()
  end

  if usql_buffer ~= nil then
    vim.bo[usql_buffer].readonly = false
    vim.api.nvim_buf_set_lines(usql_buffer, 0, -1, false, contents)
    vim.bo[usql_buffer].filetype = "text"
    vim.bo[usql_buffer].modified = false
    vim.bo[usql_buffer].readonly = true
  end
end

-- Rudimentary method to generate DSN connection strings.
-- If the connection has ssh tunnel this replaces the
-- database host/port with the tunnel host/port so usql
-- connects via the tunnel.
M.build_dsn_str = function(conn)

  if conn["dsn"] then
    return conn["dsn"]
  end

  local name = conn["name"]
  local dsn = ""

  if conn["protocol"] then
    dsn = dsn .. conn["protocol"] .. "://"
  end

  if conn["username"] then
    dsn = dsn .. utils.url_escape(conn["username"])

    if conn["password"] then
      dsn = dsn .. ":" .. utils.url_escape(conn["password"])
    end

    dsn = dsn .. "@"
  end

  if conn["ssh_config"] then
    local ssh_conn = tunnel.find_by_name(name) or {}
    dsn = dsn .. "localhost:" .. ssh_conn["local_port"]
  else
    if conn["hostname"] then
      dsn = dsn .. conn["hostname"]
    end

    if conn["port"] then
      dsn = dsn .. ":" .. conn["port"]
    end
  end

  if conn["database"] then
    dsn = dsn .. "/" .. conn["database"]
  end

  conn["dsn"] = dsn
  return conn["dsn"]
end

-- Create an autocmd to delete the buffer when the window is closed
-- This is necessary to prevent the buffer from being left behind
-- when the window is closed
local augroup = vim.api.nvim_create_augroup("usql_window_closed", { clear = true })
vim.api.nvim_create_autocmd("WinClosed", {
  group = augroup,
  callback = function(args)
    -- if the window path is the same as the UI_ID and the buffer exists
    local buf = get_usql_buffer()
    if buf and args.buf == buf then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end,
})

-- Lazy.nvim setup function.
M.setup = function(opts)
  require("usql.config").update(opts)
end

M.set_current_connection = function(conn)
  vim.notify("Change connection " .. conn["display"], vim.log.levels.INFO)

  -- Create ssh tunnel if required.
  if conn["ssh_config"] then
    tunnel.create_tunnel(conn["name"])
  end

  current_connection = conn
end

M.get_current_connection = function()
  return current_connection
end

M.select_connection = function()
  local has_telescope, telescope = pcall(require, "telescope")
  if has_telescope then
    telescope.extensions.usql.connections()
  else
    vim.ui.select(
      config.get_connections(), {
        prompt = "Database Connections",
        format_item = function(entry)
          return entry["display"]
        end,
      }, function(choice)
        M.set_current_connection(choice)
    end)
  end
end

M.get_temp_sql_file = function(start_line, end_line)
  local tmp_file = vim.fn.tempname() .. ".sql"
  local file = assert(io.open(tmp_file, "w"))
  local statement_str = table.concat(
    vim.api.nvim_buf_get_lines(0, start_line, end_line, false),
    "\n"
  )

  -- Ensure the statement has `;` at the end or usql would
  -- never return a response.
  if not string.match(statement_str, ";$") then
    statement_str = statement_str .. ";"
  end

  file:write(statement_str)
  file:close()
  return tmp_file
end

M.execute = function(start_line, end_line)
  return table.concat({
    vim.fs.normalize(config.usql_path),
    "-q",
    "-f",
    M.get_temp_sql_file(start_line, end_line),
    M.build_dsn_str(M.get_current_connection())
  }, " ")
end

-- Look for the statement closest to current cursor position
-- using Tree-sitter SQL parser.
local find_current_statement = function()
  local ts = vim.treesitter

  local current_node = ts.get_node()
  while current_node and current_node:type() ~= 'statement' do
    current_node = current_node:parent()
  end

  if current_node then
    local r1, _, _ = current_node:start()
    local r2, _, _ = current_node:end_()

    local sql_file = current_node:parent()

    local current_node_idx = 1
    if sql_file and sql_file:type() == 'program' then
      -- Find the current node index
      for node in sql_file:iter_children() do
        if node:id() == current_node:id() then
          break
        end
        current_node_idx = current_node_idx + 1
      end

      return {
        current = current_node_idx,
        start_line = r1,
        end_line = r2 + 1,
      }
    else
      vim.notify("usql: SQL statement syntax error", vim.levels.log.ERROR)
    end
  end

  return nil
end

M.run_statement = function()
  local statement = find_current_statement()

  if statement then
    M.run(statement.start_line, statement.end_line)
  else
    vim.notify(
      "Usql: no SQL statement found at current cursor position",
      vim.log.levels.WARN
    )
  end
end

M.run_file = function()
  M.run(0, -1)
end

M.run = function(start_line, end_line)

  local usql_path = vim.fs.normalize(config.usql_path)
  if vim.fn.executable(usql_path) == 0 then
    vim.notify(
      string.format("usql: binary `%s` not found or not execuable", usql_path),
      vim.log.levels.ERROR)
    return
  end

  vim.fn.jobstart(M.execute(start_line, end_line), {
    on_stdout = function(jid, contents)
      local job_stdout = get_job_stdout_contents(jid)
      for _, line in ipairs(contents) do
        if line ~= nil and string.len(line) > 0 then
          table.insert(job_stdout, line)
        end
      end
    end,
    on_stderr = function(jid, contents)
      local job_stderr = get_job_stderr_contents(jid)
      for _, line in ipairs(contents) do
        if line ~= nil and string.len(line) > 0 then
          table.insert(job_stderr, line)
        end
      end
    end,
    on_exit = function(jid, code)
      local success = code == 0
      if success then
        open_usql_buffer(get_job_stdout_contents(jid))
        vim.notify(
          "Query success",
          vim.log.levels.INFO
        )
      else
        open_usql_buffer(get_job_stderr_contents(jid))
        vim.notify(
          "Query failed",
          vim.log.levels.ERROR
        )
      end
      clear_job_contents(jid)
    end
  })
end

return M
