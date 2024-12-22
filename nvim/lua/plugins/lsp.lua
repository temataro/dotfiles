-- Enable LSP support
require("lspconfig").pyright.setup({}) -- Example: Python LSP

-- Keymaps for LSP
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(event)
        local opts = { buffer = event.buf }

        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<F3>", function() vim.lsp.buf.format({ async = true }) end, opts)
    end,
})

