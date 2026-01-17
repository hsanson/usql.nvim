local current_connection = {
  name = "",
  display = "",
  dsn  = "",
  protocol = "",
  hostname = "",
  port = "",
  database = ""
}

local utils = require("usql.utils")
local config = require("usql.config")
local tunnel = require("usql.tunnel")
local yarepl = require("yarepl")

local M = {}

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
    if conn["protocol"] == "sqlserver" then
      dsn = dsn .. "?database=" .. conn["database"]
    else
      dsn = dsn .. "/" .. conn["database"]
    end
  end

  conn["dsn"] = dsn
  return conn["dsn"]
end

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

  local current_buffer = vim.api.nvim_get_current_buf()
  local dsn = conn["name"]

  if conn["ssh_config"] then
    dsn = M.build_dsn_str(M.get_current_connection())
  end

  yarepl._send_strings(0, nil, current_buffer, {"\\c " .. dsn .. "\n"}, false, false, false)
end

M.get_current_connection = function()
  return current_connection
end

M.select_connection = function()
  local has_telescope, telescope = pcall(require, "telescope")
  local has_snacks, snacks = pcall(require, "snacks")
  local has_yarepl, yarepl = pcall(require, "yarepl")

  if not has_yarepl then
    vim.notify("usql: yarepl.nvim not found", vim.log.levels.ERROR)
    return
  end

  local current_buffer = vim.api.nvim_get_current_buf()
  local repl = yarepl._get_repl(0, nil, current_buffer)

  if not repl then
    vim.notify("usql: no yarepl REPL buffer found", vim.log.levels.ERROR)
    return
  end

  if has_snacks then
    local success, snacks_usql = pcall(require, "snacks._extensions.usql")
    if success and snacks_usql then
      snacks_usql.connections()
    else
      vim.notify("usql: Snacks extension not loaded. Install snacks.nvim first.", vim.log.levels.WARN)
      -- Fallback to vim.ui.select
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
  elseif has_telescope then
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

-- Direct access to snacks picker for users who want to call it explicitly
M.select_connection_snacks = function(opts)
  local success, snacks_usql = pcall(require, "snacks._extensions.usql")
  if success and snacks_usql then
    snacks_usql.connections(opts)
  else
    vim.notify("usql: Snacks extension not available. Install snacks.nvim first.", vim.log.levels.ERROR)
  end
end

return M
