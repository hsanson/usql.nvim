local tunnels = {}
local ssh_config

local config = require("usql.config")

M = {}

-- Generate ssh config file for tunnels.
M.create_ssh_config = function()

  if ssh_config and vim.fn.filereadable(ssh_config) then
    return ssh_config
  end

  ssh_config = vim.fn.tempname()
  local file = assert(io.open(ssh_config, "w"))
  local db_connections = config.get_connections()
  local local_port = config.ssh.start_port

  for _, conn in ipairs(db_connections) do
    if conn["ssh_config"] then
      file:write("Host " .. conn["name"] .. "\n")
      if conn["ssh_config"]["ssh_host"] then
        file:write("HostName " .. conn["ssh_config"]["ssh_host"] .. "\n")
      end
      if conn["ssh_config"]["ssh_port"] then
        file:write("Port " .. conn["ssh_config"]["ssh_port"] .. "\n")
      end
      if conn["ssh_config"]["ssh_user"] then
        file:write("User " .. conn["ssh_config"]["ssh_user"] .. "\n")
      end
      if conn["ssh_config"]["ssh_key"] then
        local key = vim.fs.normalize(conn["ssh_config"]["ssh_key"])
        file:write("IdentityFile " .. key .. "\n")
      end
      if conn["ssh_config"]["proxy"] then
        file:write("ProxyCommand " .. conn["ssh_config"]["proxy"] .. "\n")
      end
      file:write(string.format(
        "LocalForward %d %s:%d", local_port, conn["hostname"], conn["port"]
      ))
      file:write("\n")

      table.insert(tunnels, {
        name = conn["name"],
        local_port = local_port,
        job_id = nil,
        connected = false
      })

      local_port = local_port + 1
    end
  end

  file:close()
  return ssh_config
end

-- Creates a file with the passphrase.
local create_passphrase_file = function(db_connection)
  local tmp_file = vim.fn.tempname()
  local file = assert(io.open(tmp_file, "w"))
  file:write(db_connection["ssh_phrase"] or "")
  file:close()
  return tmp_file
end

M.ssh_command = function(name)
  return table.concat({
    "ssh",
    "-N",
    "-n",
    "-F",
    M.create_ssh_config(),
    name
  }, " ")
end

M.create_tunnel = function(name)

  -- Generate ssh config file and populates
  -- tunnels list.
  M.create_ssh_config()

  if not M.find_by_name(name) then
    vim.notify(
      "usql: Connection " .. name .. " does not have ssh_config",
      vim.log.levels.WARN
    )
    return
  end

  -- If already connected do nothing.
  if M.connected(name) then
    return
  end

  local cmd = M.ssh_command(name)
  local job_id = vim.fn.jobstart(cmd, {
    on_stdout = function(_, _)
    end,
    on_stderr = function(_, _)
    end,
    on_exit = function(jid, _)
      local tunnel = M.find_by_job_id(jid)
      if tunnel then
        vim.notify("TERMINATING " .. jid)
        tunnel["connected"] = false
        tunnel["job_id"] = nil
        vim.notify(
          "SSH tunnel " .. tunnel["name"] .. " closed",
          vim.log.levels.INFO
        )
      end
    end
  })

  local tunnel = M.find_by_name(name)
  tunnel["connected"] = true
  tunnel["job_id"] = job_id
end

M.destroy_tunnel = function(name)
  local tunnel = M.find_by_name(name)
  if tunnel and tunnel["connected"] then
    vim.fn.jobstop(tunnel["job_id"])
  else
    vim.notify(
      "Tried to destroy none existing tunnel " .. name,
      vim.log.levels.WARN
    )
  end
end

M.find_by_name = function(name)
  for _, tunnel in ipairs(tunnels) do
    if tunnel["name"] == name then
      return tunnel
    end
  end
  return nil
end

-- Return true if the tunnel is connected,
-- false otherwise.
M.connected = function(name)
  local tunnel = M.find_by_name(name)
  if tunnel and tunnel["connected"] then
    return true
  end
  return false
end

M.find_by_job_id = function(job_id)
  for _, tunnel in ipairs(tunnels) do
    if tunnel["job_id"] == job_id then
      return tunnel
    end
  end
  return nil
end

M.get_tunnels = function()
  return tunnels
end

return M
