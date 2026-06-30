-- LSP: mason (installs prebuilt server binaries) + mason-lspconfig
-- (auto-enables them via nvim 0.11+/0.12 native vim.lsp).
--
-- Server matrix on a node-/pip-free box:
--   lua_ls               Lua (Neovim config)        mason prebuilt binary
--   clangd               C / C++                    mason prebuilt binary
--   ruff                 Python lint/format/fix     uv tool (mason only has a
--                                                    pypi source -> needs pip)
--   jedi_language_server Python nav/hover/complete  uv tool (pip-free)
--
-- ruff + jedi are installed with: `uv tool install ruff jedi-language-server`
-- and live on ~/.local/bin (PATH). We enable them ourselves, guarded on the
-- binary existing, so this config stays portable to machines without them.
local UV_SERVERS = {
  ruff = "ruff",
  jedi_language_server = "jedi-language-server",
}

return {
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonLog", "MasonUninstall" },
    build = ":MasonUpdate",
    opts = { ui = { border = "rounded" } },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig", -- ships the lsp/<server>.lua config definitions
      "hrsh7th/cmp-nvim-lsp", -- completion capabilities
    },
    opts = {
      ensure_installed = { "lua_ls", "clangd" }, -- mason-installable (prebuilt)
      -- DON'T auto-enable: it enables every mason-installed package that has an
      -- lspconfig def (e.g. the `stylua` formatter) and was unreliable in the
      -- event-driven path. We enable exactly what we want, explicitly, below.
      automatic_enable = false,
    },
    config = function(_, opts)
      -- advertise nvim-cmp's completion capabilities to every server
      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })

      -- lua_ls: teach it about the `vim` global and skip third-party scans
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })

      -- buffer-local keymaps on attach (version-independent; namespaced under
      -- <Leader>l to avoid <Leader>c which polish.lua binds to :bd)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = function(ev)
          -- let jedi own hover/nav for Python; ruff stays lint/format/fix only
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end

          local function map(lhs, rhs, desc, mode)
            vim.keymap.set(mode or "n", lhs, rhs, { buffer = ev.buf, desc = "LSP: " .. desc })
          end
          map("gd", vim.lsp.buf.definition, "Goto definition")
          map("gD", vim.lsp.buf.declaration, "Goto declaration")
          map("gr", vim.lsp.buf.references, "References")
          map("gi", vim.lsp.buf.implementation, "Goto implementation")
          map("gy", vim.lsp.buf.type_definition, "Goto type definition")
          map("K", vim.lsp.buf.hover, "Hover docs")
          map("<Leader>la", vim.lsp.buf.code_action, "Code action", { "n", "v" })
          map("<Leader>lr", vim.lsp.buf.rename, "Rename symbol")
          map("<Leader>ld", vim.diagnostic.open_float, "Line diagnostics")
          map("<Leader>ls", vim.lsp.buf.document_symbol, "Document symbols")
        end,
      })

      require("mason-lspconfig").setup(opts) -- only for ensure_installed

      -- the ONE enable mechanism: turn on exactly these servers. mason-managed
      -- (lua_ls, clangd) always; uv-managed (jedi, ruff) only when present, so
      -- the config stays portable to machines without them.
      local servers = { "lua_ls", "clangd" }
      for server, bin in pairs(UV_SERVERS) do
        if vim.fn.executable(bin) == 1 then
          servers[#servers + 1] = server
        end
      end
      vim.lsp.enable(servers)
    end,
  },
}
