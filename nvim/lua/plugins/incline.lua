return {
  "b0o/incline.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  event = "BufReadPre",
  opts = {
    highlight = {
      groups = {
        InclineNormal = { guibg = "#7aa2f7", guifg = "#1a1b26" },
        InclineNormalNC = { guibg = "#3b4261", guifg = "#737aa2" },
      },
    },
    window = {
      padding = 0,
      margin = { horizontal = 0 },
    },
    render = function(props)
      local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
      if filename == "" then
        filename = "[No Name]"
      end
      local ft_icon, ft_color = require("nvim-web-devicons").get_icon_color(filename)
      local modified = vim.bo[props.buf].modified
      return {
        ft_icon and { " ", ft_icon, " ", guifg = ft_color } or "",
        " ",
        { filename, gui = modified and "bold,italic" or "bold" },
        " ",
      }
    end,
  },
}
