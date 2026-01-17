local has_snacks, snacks = pcall(require, "snacks")

if not has_snacks then
  return nil
end

local usql = require("usql")
local config = require("usql.config")

local connections = function(opts)
  opts = opts or {}
  
  local connections_list = config.get_connections()
  
  if #connections_list == 0 then
    vim.notify("usql: No connections found in config", vim.log.levels.WARN)
    return
  end

  local items = {}
  for _, conn in ipairs(connections_list) do
    table.insert(items, {
      text = conn.display,
      value = conn,
      name = conn.name,
      display = conn.display,
    })
  end

  snacks.picker.pick({
    title = "Database Connections",
    items = items,
    layout = opts.layout or "select",
    format = function(item, _)
      return {
        { item.display, "SnacksPickerLabel" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      usql.set_current_connection(item.value)
    end,
  })
end

return {
  connections = connections
}