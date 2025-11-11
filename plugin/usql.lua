local bufnr = vim.api.nvim_get_current_buf()

vim.keymap.set("n", "<Plug>(SelectConnection)", function()
    require("usql").select_connection()
  end,
  { desc = "Switch DB connection", noremap = true }
)

vim.keymap.set("n", "<Plug>(SendStatement)", function()
    require("usql.yarepl").send_statement()
  end,
  { desc = "Send SQL statement", noremap = true}
)

vim.keymap.set("n", "<Plug>(SendBuffer)", function()
    require("usql.yarepl").send_buffer()
  end,
  { desc = "Send current buffer", noremap = true}
)
