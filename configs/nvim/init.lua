-- Minimal neovim — fast startup, LSP built-in, no plugins
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.iskeyword:append("-")

vim.opt.backspace = "indent,eol,start"
vim.opt.clipboard = "unnamedplus"
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

vim.cmd.colorscheme("habanight")

local keymap = vim.keymap.set
keymap("n", "<leader>e", ":Ex<CR>", { desc = "File explorer" })
keymap("n", "<leader>ff", ":Rg<CR>", { desc = "Search" })
keymap("n", "<leader>w", ":w<CR>", { desc = "Save" })
keymap("n", "<leader>q", ":q<CR>", { desc = "Quit" })
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move down" })
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move up" })
keymap("n", "<leader>sv", ":vsp<CR>", { desc = "Vertical split" })
keymap("n", "<leader>sh", ":sp<CR>", { desc = "Horizontal split" })

-- LSP (built-in, no plugins)
local lspconfig = require("lspconfig")
lspconfig.lua_ls.setup({})
lspconfig.ts_ls.setup({})
lspconfig.html.setup({})
lspconfig.css_ls.setup({})
lspconfig.jsonls.setup({})

vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to def" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Go to refs" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
