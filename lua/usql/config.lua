local default_config = {
  usql_path = "usql",
  config_path = "$HOME/.config/usql/config.yaml",
  lualine = {
    fg = "#10B1FE",
    icon = "",
  }
}

local M = vim.deepcopy(default_config)

M.update = function(opts)
  local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

  for k, v in pairs(newconf) do
    M[k] = v
  end
end

return M
