vim.api.nvim_create_augroup("ConfigReload", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
    group = "ConfigReload",
    pattern = { "*.lua", "*.vim" },
    callback = function()
        vim.cmd("source " .. vim.fn.stdpath("config") .. "/init.lua")
        vim.cmd("source " .. vim.fn.stdpath("config") .. "/lua/plugins/neotree.lua")
        vim.cmd("source " .. vim.fn.stdpath("config") .. "/lua/plugins/undotree.lua")
        print("GREAAT SUCCESS!")
    end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
    group = "ConfigReload",
    pattern = { "*.lua", "*.vim" },
    callback = function()
        vim.cmd("source " .. vim.fn.stdpath("config") .. "/init.lua")
        vim.cmd("source " .. vim.fn.stdpath("config") .. "/lua/plugins/neotree.lua")
        vim.cmd("source " .. vim.fn.stdpath("config") .. "/lua/plugins/undotree.lua")
        print("GREAAT SUCCESS!")
    end,
})

