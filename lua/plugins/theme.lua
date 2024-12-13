return {
    "shaunsingh/nord.nvim",
    lazy = false,
    name = "nord",
    priority = 1000,
    config = function()
        vim.cmd('colorscheme nord')
    end
}