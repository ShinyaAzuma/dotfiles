return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function() 
    require('nvim-treesitter.configs').setup({
      ensure_installed = {
          "ruby",
          "go",
          "zig",
          "tsx",
          "javascript",
          "typescript",
          "rust",
          "json",
          "yaml",
          "html",
          "css",
          "lua",
          "vim",
          "markdown",
          "sql",
          "yaml",
          "python"
      },
      sync_install = false,
      highlight = { enable = true },
      indent = { enable = true },
    })
  end
}
