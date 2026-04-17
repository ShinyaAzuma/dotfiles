return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "saghen/blink.cmp",
  },
  config = function()
    local map = vim.keymap.set
    local capabilities = require('blink.cmp').get_lsp_capabilities()

    -- LSP接続時のキーマップ設定
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local bufnr = args.buf
        local function opts(desc)
          return { buffer = bufnr, desc = "LSP " .. desc }
        end

        map("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
        map("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
        map("n", "gi", vim.lsp.buf.implementation, opts("Go to implementation"))
        map("n", "<leader>sh", vim.lsp.buf.signature_help, opts("Show signature help"))
        map("n", "<leader>D", vim.lsp.buf.type_definition, opts("Go to type definition"))
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts("Code action"))
        map("n", "gr", vim.lsp.buf.references, opts("Show references"))
        map("n", "<leader>rn", vim.lsp.buf.rename, opts("Rename"))
      end,
    })

    -- LSP サーバー設定
    vim.lsp.config("lua_ls", {
      capabilities = capabilities,
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" },
          },
        },
      },
    })

    vim.lsp.config("ts_ls", { capabilities = capabilities })
    vim.lsp.config("gopls", { capabilities = capabilities })
    vim.lsp.config("ruby_lsp", { capabilities = capabilities })

    -- LSP を有効化
    vim.lsp.enable({ "lua_ls", "ts_ls", "gopls", "ruby_lsp" })
  end
}
