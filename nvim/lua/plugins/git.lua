-- AI が書いた差分を自分の目で見るための3点セット。
-- gitsigns = 変更行をその場で、diffview = ブランチ単位で、lazygit = hunk 単位で採否。
--
-- キーは <leader>G 配下にまとめている。既存の <leader>g は Telescope live_grep で、
-- そこに <leader>gX を足すと live_grep が timeoutlen 分待たされるため避けている。
return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local gitsigns = require("gitsigns")

      gitsigns.setup({
        current_line_blame = true,
        current_line_blame_opts = {
          delay = 300,
          virt_text_pos = "eol",
        },
      })

      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
      end

      -- diffview の差分バッファでは組み込みの ]c / [c を残す
      map("n", "]c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gitsigns.nav_hunk("next")
        end
      end, "Next hunk")

      map("n", "[c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gitsigns.nav_hunk("prev")
        end
      end, "Prev hunk")

      map("n", "<leader>hp", gitsigns.preview_hunk, "Preview hunk")
      map("n", "<leader>hr", gitsigns.reset_hunk, "Reset hunk")
      map("v", "<leader>hr", function()
        gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Reset selected hunk")
      map("n", "<leader>hb", function()
        gitsigns.blame_line({ full = true })
      end, "Blame line")
    end,
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>Gw", "<cmd>DiffviewOpen<cr>", desc = "Diff working tree (未コミットの変更)" },
      { "<leader>Gd", "<cmd>DiffviewOpen main...HEAD<cr>", desc = "Review branch vs main" },
      { "<leader>Gf", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
      { "<leader>Gq", "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        merge_tool = { layout = "diff3_mixed" },
      },
    },
  },
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>Gg", "<cmd>LazyGit<cr>", desc = "lazygit" },
      { "<leader>Gc", "<cmd>LazyGitCurrentFile<cr>", desc = "lazygit (current file repo)" },
    },
  },
}
