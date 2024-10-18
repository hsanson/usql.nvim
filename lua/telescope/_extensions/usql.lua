local has_telescope, _ = pcall(require, "telescope")

if not has_telescope then
  return nil
end

local usql = require("usql")
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local themes = require "telescope.themes"
local action_state = require "telescope.actions.state"

local connections = function(opts)
  opts = opts or themes.get_dropdown{}
  pickers.new(opts, {
    prompt_title = "Database Connections",
    finder = finders.new_table {
      results = usql.get_connections(),
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry["display"],
          ordinal = entry["display"]
        }
      end
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        usql.set_current_connection(selection["value"])
      end)
      return true
    end,
  }):find()
end

return require("telescope").register_extension {
  exports = {
    connections = connections
  },
}
