local bufnr = vim.api.nvim_get_current_buf()

vim.keymap.set("n", "<Plug>(SelectConnection)", function()
    require("usql").select_connection()
  end,
  { desc = "Usql switch connection", noremap = true }
)

vim.keymap.set("n", "<Plug>(ExecuteStatement)", function()
    require("usql").run_statement()
  end,
  { desc = "Usql execute SQL statement under the cursor", noremap = true}
)

vim.keymap.set("v", "<Plug>(ExecuteStatement)", function()
    require("usql").run_visual_statement()
  end,
  { desc = "Usql execute visually selected SQL statements", noremap = true}
)

vim.keymap.set("n", "<Plug>(ExecuteFile)", function()
    require("usql").run_file()
  end,
  { desc = "Usql execute all statements in the buffer", noremap = true}
)
