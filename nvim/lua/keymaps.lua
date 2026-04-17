local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Split window
map('n', 'ss', ':split<CR>', opts)
map('n', 'sv', ':vsplit<CR>', opts)

-- Move window
map('n', 'sh', '<C-w>h', opts)
map('n', 'sj', '<C-w>j', opts)
map('n', 'sk', '<C-w>k', opts)
map('n', 'sl', '<C-w>l', opts)

-- Resize window
map('n', '<C-w><Left>', '<C-w><', opts)
map('n', '<C-w><Right>', '<C-w>>', opts)
map('n', '<C-w><Up>', '<C-w>+', opts)
map('n', '<C-w><Down>', '<C-w>-', opts)

-- Tabs
map('n', '<S-Tab>', ':tabprev<CR>', opts)
map('n', '<Tab>', ':tabnext<CR>', opts)
map('n', 'te', ':tabedit<CR>', opts)

-- Close window
map('n', '<Leader>w', ':w<CR>', opts)
map('n', '<Leader>q', ':q<CR>', opts)
map('n', '<Leader>wq', ':wq<CR>', opts)

-- Terminal
map('n', '<Leader>tv', ':vs | terminal<CR>', opts)
map('n', '<Leader>ts', ':belowright sp | terminal<CR>', opts)
map('t', '<Esc>', '<C-\\><C-n>', opts)

-- Diagnostics
map('n', '<Leader>d', ':lua vim.diagnostic.open_float()<CR>', opts)

-- Comment toggle
map('n', '<C-_>', 'gcc', { noremap = false })
map('v', '<C-_>', 'gc', { noremap = false })

-- Select all
map('n', '<C-a>', 'gg<S-v>G', opts)

-- oil.nvimで開く
map('n', '<Leader>e', '<cmd>Oil<cr>', opts)
