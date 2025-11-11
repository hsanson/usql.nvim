<div align="center">

# usql.nvim

  <a href="#requirements" title="Requirements">Requirements</a> |
  <a href="#installation" title="Installation">Installation</a> |
  <a href="#usage" title="Usage">Usage</a> |
  <a href="https://github.com/hsanson/usql.nvim/releases" title="Releases">
  Releases</a>
</div>

<p></p>

Simple Neovim plugin for the universal command-line database interface [usql](https://github.com/xo/usql). It depens on [yarepl.nvim](https://github.com/milanglacier/yarepl.nvim) for the heavy lifting and adds helpers to make it easier to work with SQL:

- Provide yarepl command and formatter for usql.
- Database connection selector using vim.ui or telescope if available.
- SSH tunneling on top of usql database connections.
- Keymaps to work with usql repl:
  - <Plug>(SelectConnection)
  - <Plug>(SendStatement)
  - <Plug>(SendBuffer)

## Requirements

- [Neovim >= 0.10.0](https://github.com/neovim/neovim/releases)
- [usql](https://github.com/xo/usql)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
  - [nvim-treesitter SQL parser](https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#supported-languages) `:TSInstall sql`.
- [yarepl.nvim](https://github.com/milanglacier/yarepl.nvim)
- [telescope.nvim (optional)](https://github.com/nvim-telescope/telescope.nvim)
- [lualine.nvim (optional)](https://github.com/nvim-lualine/lualine.nvim)
- ssh client (optional): Used to create SSH tunnels.

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

In your YAREPL configuration add usql meta:

```lua
{
  "milanglacier/yarepl.nvim",
  config = function()
    local yarepl = require("yarepl")
    local usql = require("usql.yarepl")

    yarepl.setup({
      metas = {
        usql = { cmd = usql.cmd, formatter = usql.formatter },
      },
    })

  end
}
```

## Usage

Create key map to open connection selector:

```lua
vim.keymap.set("n",
  "<localleader>rt",
  "<Plug>(SelectConnection)",
  { desc = "Select DB connection" }
  )
```

Create key maps to send SQL statement under cursor and whole buffer:

```lua
vim.keymap.set("n",
  "<localleader>rs",
  "<Plug>(SendStatement)",
  { desc = "Send SQL Statement" }
  )

vim.keymap.set("n",
  "<localleader>rf",
  "<Plug>(SendBuffer)",
  { desc = "Send current buffer" }
  )
```

> [!NOTE]
> You may want to add the above key maps in the ftplugin/sql.lua file so they
> only work on SQL files.

Create other YAREPL key maps to send visual and motions as explained in YAREPL [Wiki](https://github.com/milanglacier/yarepl.nvim/wiki/Example-Keymap-setup-without-using-the-%60plug%60-keymaps-shipped-with-yarepl).

1. Open a `sql` file.
2. Open usql REPL with whichever key map you set.
3. Execute `<localleader>rt` to open connection selector and select the
   connection you want to use.
4. Move the cursor to any SQL statement.
5. Execute `<localleader>rs` to run SQL statement under the cursor.
6. Execute `<localleader>rf` to run all SQL statements in the current buffer.

## Connections Config

This plugin reads usql default YAML configuration file to retrieve the list of
available database connections. In addition to usql
[configuration](https://github.com/xo/usql?tab=readme-ov-file#configuration)
parameters, this plugin supports additional keys:

### Display

The **display** parameter is used for display in the connections selector
and lualine status. If not present the connection YAML key is used instead.

Example configuration:

```yaml
connections:
  my_dev_db:
    display: Local DB
    protocol: postgresql
    hostname: localhost
    port: 5432
    database: my_dev
    username: my_username
    password: secret_password
```

### SSH Tunnel

This plugin enhances `usql` by adding the capability of defining SSH tunnels in
the database configuration. If a database connection has the `ssh_config` key,
this plugin will create and SSH tunnel and instruct `usql` to use the tunnel
when connecting to the database.

Example:

```yaml
connections:
  my_dev_db:
    display: Local DB
    protocol: postgresql
    hostname: [database hostname]
    port: 5432
    database: my_dev
    username: my_username
    password: secret_password
    ssh_config:
        ssh_host: 192.168.56.50
        ssh_port: 22
        ssh_user: admin
        ssh_key: ~/.ssh/id_rsa
```

> [!NOTE]
> Ensure you have configured an ssh-agent or similar and that you can connect to
> the ssh host without being prompt for the passphrase.

> [!IMPORTANT]
> SSH tunnels support only public key authentication. Support for plain password
> authentication is not planned and not recommended for production use.

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
