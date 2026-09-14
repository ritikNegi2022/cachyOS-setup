-- Minimal neovim — fast startup, LSP, no plugin manager
-- Works on nvim 0.11+ (uses native vim.lsp.config); lspconfig used only if installed

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Monochrome palette: black ↔ white (no blue)
vim.opt.termguicolors = true
vim.opt.background = "dark"
-- Only set colorscheme if it actually exists (avoids E185 on startup)
pcall(vim.cmd.colorscheme, "habamax")
-- Enforce monochrome overrides (habamax is already muted, force grays)
vim.api.nvim_set_hl(0, "Normal", { bg = "#000000", fg = "#eeeeee" })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1a1a1a" })
vim.api.nvim_set_hl(0, "Visual", { bg = "#333333", fg = "#ffffff" })
vim.api.nvim_set_hl(0, "Comment", { fg = "#777777", italic = true })
vim.api.nvim_set_hl(0, "LineNr", { fg = "#555555" })
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#bbbbbb" })

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"

opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

opt.cursorline = true
opt.scrolloff = 8
opt.iskeyword:append("-")

opt.backspace = "indent,eol,start"
opt.clipboard = "unnamedplus"
opt.splitright = true
opt.splitbelow = true

opt.swapfile = false
opt.backup = false
opt.undofile = true

local keymap = vim.keymap.set
keymap("n", "<leader>e", ":Ex<CR>", { desc = "File explorer" })
keymap("n", "<leader>w", ":w<CR>", { desc = "Save" })
keymap("n", "<leader>q", ":q<CR>", { desc = "Quit" })
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
keymap("n", "<leader>sv", ":vsp<CR>", { desc = "Vertical split" })
keymap("n", "<leader>sh", ":sp<CR>", { desc = "Horizontal split" })

-- Project-wide search via ripgrep (guarded: only if rg is installed)
if vim.fn.executable("rg") == 1 then
    keymap("n", "<leader>R", function()
        local query = vim.fn.input("Rg: ")
        if query ~= "" then
            vim.cmd("grep! " .. vim.fn.shellescape(query))
            vim.cmd("copen")
        end
    end, { desc = "Ripgrep search" })
end

-- LSP: nvim-lspconfig (installed via pacman) provides server definitions;
-- enable the ones whose binaries exist on this machine.
local ok, lspconfig = pcall(require, "lspconfig")
if ok then
    local servers = {
        pyright = "pyright",
        ruff = "ruff",
        rust_analyzer = "rust-analyzer",
        clangd = "clangd",
        lua_ls = "lua-language-server",
        ts_ls = "typescript-language-server",
    }
    for ls, bin in pairs(servers) do
        if vim.fn.executable(bin) == 1 then
            pcall(function() vim.lsp.enable(ls) end)
        end
    end
end

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local km = vim.keymap.set
        local buf = args.buf
        km("n", "gd", vim.lsp.buf.definition, { buffer = buf, desc = "Go to definition" })
        km("n", "gr", vim.lsp.buf.references, { buffer = buf, desc = "Go to references" })
        km("n", "K", vim.lsp.buf.hover, { buffer = buf, desc = "Hover" })
        km("n", "<leader>rn", vim.lsp.buf.rename, { buffer = buf, desc = "Rename" })
        km("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = buf, desc = "Code action" })
    end,
})
