<div align="center">

# usql.nvim

  <a href="#requirements" title="Requirements">Requirements</a> |
  <a href="#installation" title="Installation">Installation</a> |
  <a href="#usage" title="Usage">Usage</a> |
  <a href="https://github.com/hsanson/usql.nvim/releases" title="Releases">
  Releases</a>
</div>

<p></p>

Simple Neovim plugin for the universal command-line database interface [usql](https://github.com/xo/usql). It allows to execute SQL statements and display the results in a split window from within Neovim.

## Requirements

- [Neovim >= 0.10.0](https://github.com/neovim/neovim/releases)
- [usql](https://github.com/xo/usql)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
  - [nvim-treesitter SQL parser](https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#supported-languages) `:TSInstall sql`.
- [telescope.nvim (optional)](https://github.com/nvim-telescope/telescope.nvim)
- [lualine.nvim (optional)](https://github.com/nvim-lualine/lualine.nvim)

## Installation

Via [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    'hsanson/usql.nvim',
    ft = "sql",
    opts = {
        -- Path to usql binary,
        usql_path = "usql",

        -- Absolute path to usql config.yaml file.
        config_path = "$HOME/.config/usql/config.yaml",

        -- Lualine component configuration
        lualine = {
            fg = "#10B1FE",
            icon = "",
        }
    }
},
```

## Usage

Create some key maps to execute SQL queries, usually in `ftplugins/sql.lua` file:

```lua
local augroup = vim.api.nvim_create_augroup

local group = augroup('UsqlGroup', { clear = true })

vim.keymap.set('n', '<localleader>re', function()
    require("usql").select_connection()
  end, { desc = "Usql switch connection", remap = false, buffer = 0 })

vim.keymap.set('n', '<localleader>rr', function()
    require("usql").run_statement()
  end, { desc = "Usql execute SQL statement under the cursor", remap = false, buffer = 0 })

vim.keymap.set('n', '<localleader>rf', function()
    require("usql").run_file()
  end, { desc = "Usql execute whole SQL file", remap = false, buffer = 0 })
```

1. Open an `sql` file.
2. Execute `<localleader>re` and select connection to use.
3. Move the cursor to any SQL statement.
4. Execute `<localleader>rr` to run the SQL statement using `usql`.
5. A split window opens with the query results.
6. Execute `<localleader>rf` to run all SQL statements contained in the file using `usql`.

## Lualine

Add `usql` component to your [lualine configuration](https://github.com/nvim-lualine/lualine.nvim?tab=readme-ov-file#default-configuration) to show current connection in
the status line:

```lua
sections = {
    lualine_y = {
      { 'usql' },
    },
}
```


