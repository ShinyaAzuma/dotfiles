vim.o.encoding = 'utf-8'
vim.o.number = true
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.clipboard = "unnamedplus"
vim.o.list = true
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.wrap = false
vim.o.termguicolors = true
vim.o.wildmenu = true
vim.o.ruler = true
vim.o.smartcase = true
vim.o.showmatch = true
vim.o.splitbelow = true
vim.o.splitright = true
vim.g.mapleader = ' '
vim.g.maplocalleader = "\\"
vim.o.softtabstop = 2
vim.o.backspace = "indent,eol,start"
vim.o.cursorline = true
vim.o.laststatus = 3
vim.o.scrolloff = 10
vim.o.cmdheight = 0
vim.cmd [[filetype plugin indent on]]


-- InsertLeaveで英数に切り替え
vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    vim.fn.system("osascript -e 'tell application \"System Events\" to key code 102'")
  end,
})

-- FocusGainedで英数に切り替え
vim.api.nvim_create_autocmd("FocusGained", {
  callback = function()
    vim.fn.system("osascript -e 'tell application \"System Events\" to key code 102'")
  end,
})


-- ファイルが外部で変更されたら自動で読み込み
vim.o.autoread = true

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  callback = function()
    vim.cmd("checktime")
  end,
})
