local M = {}

local health_start = vim.health.start or vim.health.report_start
local health_warn = vim.health.warn or vim.health.report_warn
local health_error = vim.health.error or vim.health.report_error
local health_ok = vim.health.ok or vim.health.report_ok
local config = require("usql.config")

M.check = function()
  health_start("usql.nvim")

  local usql_path = vim.fs.normalize(config.usql_path)
  if vim.fn.executable(usql_path) == 1 then
    health_ok(string.format("Binary execuable `%s` found", usql_path))
  else
    health_error(string.format("Binary executable `%s` missing", usql_path))
  end

  local config_path = vim.fs.normalize(config.config_path)
  if vim.fn.filereadable(config_path) == 1 then
    health_ok(string.format("Config file `%s` found", config_path))
  else
    health_warn(string.format("Config file `%s` missing", config_path))
  end
end

return M
