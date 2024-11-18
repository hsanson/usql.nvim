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

## Usage

Create some key maps to execute SQL queries, usually in `ftplugins/sql.lua` file:

```lua
vim.keymap.set("n", "<localleader>re", "<Plug>(SelectConnection)")
vim.keymap.set({"n", "v"}, "<localleader>rr", "<Plug>(ExecuteStatement)")
vim.keymap.set("n", "<localleader>rf", "<Plug>(ExecuteFile)")
```

1. Open a `sql` file.
2. Execute `<localleader>re` and select connection to use.
3. Move the cursor to any SQL statement.
4. Execute `<localleader>rr` to run SQL statement under the cursor or visually
   selected using `usql`.
5. A split window opens with the query results.
6. Execute `<localleader>rf` to run all SQL statements contained in the file using `usql`.

## Connections Config

This plugin reads usql default YAML configuration file to retrieve the list of
available database connections. In addition to usql
[configuration](https://github.com/xo/usql?tab=readme-ov-file#configuration)
parameters, this plugin supports additional keys:

* **display**: Used for display in the connections selector if present and
  lualine status. If not present the connection YAML key is used instead.

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

## SSH Tunnel

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
