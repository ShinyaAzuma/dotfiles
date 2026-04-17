return {
  {
    "ahmedkhalf/project.nvim",
    config = function()
      require("project_nvim").setup({
        detection_methods = { "pattern", "lsp" },
        patterns = { ".git", "package.json", "Makefile", "Cargo.toml" },
        show_hidden = false,
        silent_chdir = true,
      })
    end,
  },
}
