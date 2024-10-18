local yaml = require("usql.yaml")

local default_config = {
  usql_path = "usql",
  config_path = "$HOME/.config/usql/config.yaml",
  lualine = {
    fg = "#10B1FE",
    icon = "",
  },
  ssh = {
    start_port = 12345
  }
}

local M = vim.deepcopy(default_config)

M.update = function(opts)
  local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

  for k, v in pairs(newconf) do
    M[k] = v
  end
end

M.get_connections = function()
  local config_file = vim.fs.normalize(M.config_path)

  if vim.fn.filereadable(config_file) == 0 then
    vim.notify("usql: config file not found", vim.log.levels.WARN)
    return {}
  end

  local file = assert(io.open(config_file, "r"))
  local yaml_map = yaml.parse(file:read("*all")) or {}
  file:close()

  local connections = yaml_map["connections"] or {}
  local connections_map = {}

  for key, value in pairs(connections) do

    local protocol
    local hostname
    local port
    local database
    local dsn
    local display
    local ssh_config
    local username
    local password

    if type(value) == "table" then
      protocol = value["protocol"]
      hostname = value["hostname"]
      port = value["port"]
      database = value["database"] or ""
      display = value["alias"] or key
      ssh_config = value["ssh_config"]
      username = value["username"]
      password = value["password"]
    else
      dsn = value
      display = key
    end

    table.insert(connections_map, {
      display = display,
      name = key,
      dsn = dsn,
      protocol = protocol,
      hostname = hostname,
      username = username,
      password = password,
      port = port,
      database = database,
      ssh_config = ssh_config
    })
  end

  return connections_map
end

return M
