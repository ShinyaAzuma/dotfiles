# Neovim Configuration

## Directory Structure

```
~/.config/nvim/
├── init.lua                    # Entry point
├── lazy-lock.json              # Plugin version lock
└── lua/
    ├── base.lua                # Core settings
    ├── keymaps.lua             # Keybindings
    ├── config/
    │   └── lazy.lua            # Lazy.nvim setup
    └── plugins/
        ├── theme.lua           # Tokyonight
        ├── lsp.lua             # LSP
        ├── cmp.lua             # Completion
        ├── treesitter.lua      # Syntax highlighting
        ├── conform.lua         # Formatting
        ├── fzf.lua             # Telescope (fuzzy finder)
        └── lualinestatus.lua   # Status line
```

## Plugins

| Plugin | Purpose |
|--------|---------|
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Plugin manager |
| [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | Color scheme |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP client configuration |
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | Autocompletion engine |
| [cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp) | LSP completion source |
| [cmp-buffer](https://github.com/hrsh7th/cmp-buffer) | Buffer completion source |
| [cmp-path](https://github.com/hrsh7th/cmp-path) | Path completion source |
| [cmp-cmdline](https://github.com/hrsh7th/cmp-cmdline) | Cmdline completion source |
| [cmp-nvim-lua](https://github.com/hrsh7th/cmp-nvim-lua) | Neovim Lua API completion |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax highlighting / parsing |
| [conform.nvim](https://github.com/stevearc/conform.nvim) | Code formatting |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Status line |
| [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | File icons |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder |
| [telescope-file-browser.nvim](https://github.com/nvim-telescope/telescope-file-browser.nvim) | File browser extension |
| [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) | Utility library |

## Core Settings

- Leader key: `<Space>`
- Encoding: UTF-8
- Indentation: 2 spaces (auto-indent, smart indent)
- Line numbers: on
- Clipboard: system clipboard (`unnamedplus`)
- Line wrapping: off
- Smart case search: on
- Split: below / right
- Global status line (`laststatus=3`)

### Highlight Customization

| Group | Description |
|-------|-------------|
| `NormalNC` | Inactive window background (`#111111`) |
| `WinSeparator` | Window separator color (`#ff9e64`) |
| `CursorLine` | Cursor line background (`#2a3a4a`) |

## Keymaps

### Window Navigation

| Key | Action |
|-----|--------|
| `<Leader>h/j/k/l` | Move focus between windows |
| `<Leader>s` | Horizontal split |
| `<Leader>v` | Vertical split |

### File Operations

| Key | Action |
|-----|--------|
| `<Leader>w` | Save |
| `<Leader>q` | Quit |
| `<Leader>wq` | Save and quit |

### Terminal

| Key | Action |
|-----|--------|
| `<Leader>tt` | Open terminal |
| `<Leader>tv` | Open terminal (vertical split) |
| `<Leader>ts` | Open terminal (horizontal split) |
| `<Esc>` | Exit terminal mode |

### Insert Mode Navigation

| Key | Action |
|-----|--------|
| `<C-h/j/k/l>` | Move cursor in insert mode |

### Other

| Key | Action |
|-----|--------|
| `<C-_>` | Toggle comment |
| `<Leader>d` | Show diagnostics float |

### Telescope

| Key | Action |
|-----|--------|
| `<Leader>p` | Find files |
| `<Leader>g` | Live grep |
| `<Leader>b` | Browse buffers |
| `sf` | File browser |

File browser (normal mode):

| Key | Action |
|-----|--------|
| `N` | New file |
| `h` | Parent directory |
| `l` | Select / open |
| `.` | Toggle hidden files |
| `/` | Search mode |

### LSP

| Key | Action |
|-----|--------|
| `gD` | Go to declaration |
| `gd` | Go to definition |
| `gi` | Go to implementation |
| `gr` | References |
| `<Leader>sh` | Signature help |
| `<Leader>D` | Type definition |
| `<Leader>ca` | Code action |
| `<Leader>rn` | Rename |

### Formatting

| Key | Action |
|-----|--------|
| `<Leader>i` | Format code |

`:Format` command is also available.

## LSP Servers

| Server | Language |
|--------|----------|
| `lua_ls` | Lua |
| `ts_ls` | TypeScript / JavaScript |
| `gopls` | Go |
| `ruby_lsp` | Ruby |

## Completion (nvim-cmp)

| Mode | Sources |
|------|---------|
| Insert | LSP, Neovim Lua, Buffer |
| Search (`/`, `?`) | Buffer |
| Command (`:`) | Path, Cmdline |

| Key | Action |
|-----|--------|
| `<C-b>` / `<C-f>` | Scroll docs |
| `<C-Space>` | Trigger completion |
| `<C-e>` | Abort |
| `<CR>` | Confirm |

## Treesitter

Installed parsers: ruby, go, zig, tsx, javascript, typescript, rust, json, yaml, html, css, lua, vim, markdown, sql, python

## Formatting (conform.nvim)

| Filetype | Formatter |
|----------|-----------|
| Lua | stylua |
| Go | goimports, gofmt |
| JavaScript / TypeScript (JSX) | prettierd |
| JSON | prettierd |
| SQL | sql-formatter |
| All | trim_whitespace |

Format on save is enabled (500ms timeout, LSP fallback).
