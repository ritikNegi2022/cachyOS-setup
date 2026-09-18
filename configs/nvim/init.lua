-- Full IDE setup for web dev (JS/TS: Next.js/React/Angular/Expo + Tailwind),
-- Python and Rust — with automatic suggestions, auto-lint and auto-format.
-- Fast startup, no plugin manager: native vim.pack (nvim 0.12+).
-- After copying this file: plugins auto-install on first launch, then restart.
-- Binaries needed on PATH (see scripts/install.sh):
--   pacman: typescript-language-server tailwindcss-language-server
--           eslint-language-server eslint_d stylua rust-analyzer pyright ruff
--   npm -g: prettier eslint vscode-langservers-extracted emmet-ls @tailwindcss/language-server

-- Must be first: leader before any <leader> mappings or plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

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

-- Mirror Zed: 2 spaces default (JS/TS/JSON/YAML/TOML/Markdown), 4 for C/C++/Python/Rust/Lua
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp", "python", "rust", "lua" },
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
    end,
})

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 10 -- mirror Zed horizontal_scroll_margin
opt.iskeyword:append("-")

opt.backspace = "indent,eol,start"
opt.clipboard = "unnamedplus"
opt.splitright = true
opt.splitbelow = true

opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.timeoutlen = 300 -- snappy leader + which-key
opt.updatetime = 250 -- fast diagnostics (auto-lint feel) + gitsigns / hover
opt.scrollback = 10000

-- Completion popup behavior: suggestions appear automatically, <CR> accepts
opt.completeopt = "menu,menuone,noselect"
opt.pumheight = 12

-- Native plugin manager (nvim 0.12+): :PackUpdate to update, no lazy.nvim needed
pcall(vim.pack.add, {
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/nvim-telescope/telescope.nvim",
    "https://github.com/nvim-treesitter/nvim-treesitter",
    "https://github.com/stevearc/oil.nvim",
    "https://github.com/lewis6991/gitsigns.nvim",
    "https://github.com/stevearc/conform.nvim",
    "https://github.com/folke/which-key.nvim",
    "https://github.com/neovim/nvim-lspconfig",
    -- Automatic suggestions (completion) + snippets
    "https://github.com/hrsh7th/nvim-cmp",
    "https://github.com/hrsh7th/cmp-nvim-lsp",
    "https://github.com/hrsh7th/cmp-buffer",
    "https://github.com/hrsh7th/cmp-path",
    "https://github.com/L3MON4D3/LuaSnip",
    "https://github.com/rafamadriz/friendly-snippets",
    -- Autoclose brackets and quotes (+ adds () on function accept from completion)
    "https://github.com/windwp/nvim-autopairs",
    -- Auto-lint (runs linters on save / buffer enter)
    "https://github.com/mfussenegger/nvim-lint",
})

-- Plugin setup (all guarded so first run before :PackUpdate still works)
pcall(function() require("oil").setup({ view_options = { show_hidden = true } }) end)
pcall(function() require("gitsigns").setup({ signcolumn = true }) end)
pcall(function()
    require("conform").setup({
        -- Auto-format on save (the "specially auto formatting" part)
        format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
        formatters_by_ft = {
            javascript = { "prettier" },
            typescript = { "prettier" },
            javascriptreact = { "prettier" },
            typescriptreact = { "prettier" },
            html = { "prettier" },
            css = { "prettier" },
            json = { "prettier" },
            jsonc = { "prettier" },
            yaml = { "prettier" },
            toml = { "prettier" },
            markdown = { "prettier" },
            python = { "ruff_format" },
            rust = { "rustfmt" },
            c = { "clang_format" },
            cpp = { "clang_format" },
            lua = { "stylua" },
        },
        formatters = {
            -- No width-based wrapping: effectively-unlimited print width
            prettier = { prepend_args = { "--single-quote", "--trailing-comma", "all", "--print-width", "1000" } },
            ruff_format = { args = { "format", "--line-length", "1000", "-" } },
        },
    })
end)
pcall(function() require("which-key").setup() end)
pcall(function()
    require("telescope").setup({
        defaults = {
            layout_strategy = "horizontal",
            sorting_strategy = "ascending",
        },
        pickers = { find_files = { hidden = false } },
    })
end)
-- Treesitter: new main-branch API (0.12). setup() never installs parsers;
-- the install() call below self-heals missing ones (async, skips installed).
pcall(function()
    require("nvim-treesitter").setup({
        ensure_install = {},
        auto_install = false,
        highlight = { enable = true },
        indent = { enable = true },
    })
    require("nvim-treesitter").install({
        "javascript", "typescript", "tsx", "html", "css",
        "json", "python", "rust", "lua",
        "markdown", "markdown_inline", "yaml", "toml", "bash",
    })
end)

-- Snippets (VSCode-style collection: React hooks, Tailwind-unaware but broad,
-- python/rust/lua basics). Loaded lazily so startup stays fast.
pcall(function()
    require("luasnip.loaders.from_vscode").lazy_load()
end)

-- Automatic suggestions: LSP + snippets + path + buffer words, popup as you type
pcall(function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    cmp.setup({
        snippet = {
            expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<C-e>"] = cmp.mapping.abort(),
            ["<C-u>"] = cmp.mapping.scroll_docs(-4),
            ["<C-d>"] = cmp.mapping.scroll_docs(4),
            ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
            ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
            -- <CR> accepts the selected suggestion; <Tab> walks / expands
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
            ["<Tab>"] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_next_item()
                elseif luasnip.expand_or_locally_jumpable() then
                    luasnip.expand_or_jump()
                else
                    fallback()
                end
            end, { "i", "s" }),
            ["<S-Tab>"] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item()
                elseif luasnip.locally_jumpable(-1) then
                    luasnip.jump(-1)
                else
                    fallback()
                end
            end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
            { name = "nvim_lsp" }, -- LSP suggestions (TS, tailwind classes, ruff, rust…)
            { name = "luasnip" }, -- snippet suggestions
            { name = "path" }, -- file-path suggestions
        }, {
            { name = "buffer" }, -- words from open buffers
        }),
    })
end)

-- Autoclose brackets/quotes (treesitter-aware: won't pair inside strings, etc.)
pcall(function()
    require("nvim-autopairs").setup({ check_ts = true })
    -- Accepting a function/method from completion inserts () automatically
    local ok_cmp, cmp = pcall(require, "cmp")
    if ok_cmp then
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end
end)

-- Auto-lint (the "specially auto linting" part): linters run on save/enter.
-- Web uses eslint_d (fast daemon) with eslint fallback; python uses ruff.
pcall(function()
    local lint = require("lint")
    lint.linters_by_ft = {
        javascript = { vim.fn.executable("eslint_d") == 1 and "eslint_d" or "eslint" },
        typescript = { vim.fn.executable("eslint_d") == 1 and "eslint_d" or "eslint" },
        javascriptreact = { vim.fn.executable("eslint_d") == 1 and "eslint_d" or "eslint" },
        typescriptreact = { vim.fn.executable("eslint_d") == 1 and "eslint_d" or "eslint" },
        python = { "ruff" },
    }
    -- Never lint line length: E501 stays off even if a project's ruff config
    -- enables it, and the length threshold itself is effectively unlimited.
    local ruff = lint.linters.ruff
    if ruff and ruff.args then
        table.insert(ruff.args, #ruff.args, "--line-length")
        table.insert(ruff.args, #ruff.args, "1000")
        table.insert(ruff.args, #ruff.args, "--ignore")
        table.insert(ruff.args, #ruff.args, "E501")
    end
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        callback = function() pcall(lint.try_lint) end,
    })
end)

local keymap = vim.keymap.set
-- Oil replaces :Ex (netrw is disabled above)
keymap("n", "<leader>e", function() pcall(require("oil").open) end, { desc = "File explorer (oil)" })
keymap("n", "<leader>w", ":w<CR>", { desc = "Save" })
keymap("n", "<leader>q", ":q<CR>", { desc = "Quit" })
keymap("n", "<leader>ff", function() pcall(require("telescope.builtin").find_files) end, { desc = "Find files" })
keymap("n", "<leader>fg", function() pcall(require("telescope.builtin").live_grep) end, { desc = "Live grep" })
keymap("n", "<leader>fb", function() pcall(require("telescope.builtin").buffers) end, { desc = "Buffers" })
keymap("n", "<leader>fd", function() pcall(require("telescope.builtin").diagnostics) end, { desc = "Diagnostics" })
keymap("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })
keymap("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
keymap("n", "<leader>sv", ":vsp<CR>", { desc = "Vertical split" })
keymap("n", "<leader>sh", ":sp<CR>", { desc = "Horizontal split" })
keymap("n", "<leader>f", function()
    pcall(function() require("conform").format({ async = false }) end)
end, { desc = "Format buffer" })

-- Zen mode: hide the statusbar (and tab bar, ruler, mode messages) — silent,
-- no "zen on" text. Code, line numbers, gutter and suggestions stay as-is.
-- <leader>z toggles; original options are saved and restored exactly.
local zen_saved = nil
function ToggleZen()
    if zen_saved == nil then
        zen_saved = {
            laststatus = vim.o.laststatus,
            showtabline = vim.o.showtabline,
            ruler = vim.o.ruler,
            showmode = vim.o.showmode,
            showcmd = vim.o.showcmd,
        }
        vim.o.laststatus = 0
        vim.o.showtabline = 0
        vim.o.ruler = false
        vim.o.showmode = false
        vim.o.showcmd = false
    else
        for k, v in pairs(zen_saved) do
            vim.o[k] = v
        end
        zen_saved = nil
    end
end
keymap("n", "<leader>z", ToggleZen, { desc = "Toggle zen mode" })

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

-- Diagnostics UI: virtual text + signs + underline, sorted by severity
vim.diagnostic.config({
    virtual_text = { spacing = 2, prefix = "●" },
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
})

-- LSP capabilities: let servers know completion (nvim-cmp) is available so
-- they send full suggestion lists (auto-imports, tailwind class docs, …).
pcall(function()
    local caps = pcall(require, "cmp_nvim_lsp")
    if caps then
        local capabilities = require("cmp_nvim_lsp").default_capabilities()
        pcall(vim.lsp.config, "*", { capabilities = capabilities })
    end
end)

-- LSP: nvim-lspconfig (installed via pacman) provides server definitions;
-- enable the ones whose binaries exist on this machine.
local ok, lspconfig = pcall(require, "lspconfig")
if ok then
    -- Per-server tuning for web + python + rust
    pcall(function()
        lspconfig.util.default_config = vim.tbl_deep_extend("force", lspconfig.util.default_config or {}, {})
    end)
    local servers = {
        -- Web core: types + completions + auto-imports (Next.js/React/Expo/Angular)
        ts_ls = "typescript-language-server",
        -- Tailwind: class completions + warnings in JS/TS/JSX/TSX/HTML/CSS
        tailwindcss = "tailwindcss-language-server",
        -- ESLint: live lint diagnostics + code actions (:EslintFixAll)
        eslint = "vscode-eslint-language-server",
        -- Emmet: rapid markup (html/css/jsx/tsx abbreviation expansion)
        emmet_ls = "emmet-ls",
        -- HTML / CSS / JSON incl. embedded completions
        html = "vscode-html-language-server",
        cssls = "vscode-css-language-server",
        jsonls = "vscode-json-language-server",
        -- Python: types (pyright) + lint/format (ruff)
        pyright = "pyright",
        ruff = "ruff",
        -- Rust: analyzer + clippy lint
        rust_analyzer = "rust-analyzer",
        clangd = "clangd",
        lua_ls = "lua-language-server",
    }
    for ls, bin in pairs(servers) do
        if vim.fn.executable(bin) == 1 then
            if ls == "eslint" then
                -- Flat config (eslint v9+): without this the server errors out
                -- in Next.js / Vite / Expo projects using eslint.config.*
                pcall(vim.lsp.config, ls, {
                    settings = { useFlatConfig = true, run = "onType", validate = "on" },
                })
            elseif ls == "tailwindcss" then
                pcall(vim.lsp.config, ls, {
                    settings = { tailwindCSS = { emmetCompletions = true } },
                })
            elseif ls == "pyright" then
                pcall(vim.lsp.config, ls, {
                    settings = {
                        python = {
                            analysis = {
                                typeCheckingMode = "standard",
                                autoSearchPaths = true,
                                useLibraryCodeForTypes = true,
                                diagnosticSeverityOverrides = {
                                    reportUnusedImport = "warning",
                                    reportMissingTypeStubs = "none",
                                },
                            },
                        },
                    },
                })
            elseif ls == "rust_analyzer" then
                pcall(vim.lsp.config, ls, {
                    settings = {
                        ["rust-analyzer"] = {
                            check = { command = "clippy" },
                            inlayHints = { enable = true },
                        },
                    },
                })
            elseif ls == "ts_ls" then
                pcall(vim.lsp.config, ls, {
                    init_options = {
                        preferences = {
                            importModuleSpecifierPreference = "relative",
                            includeInlayParameterNameHints = "none",
                        },
                    },
                })
            end
            pcall(function() vim.lsp.enable(ls) end)
        end
    end
end

-- Auto-fix ESLint issues on save (JS/TS/JSX/TSX): runs the server's fix-all,
-- so unused imports / fixable lint errors disappear without manual work.
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
    callback = function() pcall(vim.cmd, "EslintFixAll") end,
})

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
