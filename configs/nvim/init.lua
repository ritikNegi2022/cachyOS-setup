-- Full IDE: monochrome black/white, performant, production-ready. No AI.
-- Stack: JS/TS (Next/React/Angular/Expo + Tailwind), Python, Rust, C/C++, Lua.
-- No plugin manager needed: native vim.pack (nvim 0.12+).
-- First launch: plugins auto-install, then restart nvim.
-- Binaries on PATH (see scripts/install.sh):
--   typescript-language-server tailwindcss-language-server eslint-language-server
--   eslint_d prettier emmet-ls pyright ruff rust-analyzer clangd stylua rg fd lazygit

-- Must be first: leader before any <leader> mappings or plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ---------------------------------------------------------------------------
-- Performance: disable unused providers / builtin plugins (faster startup)
-- ---------------------------------------------------------------------------
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_gzip = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_logiPat = 1
vim.g.loaded_rrhelper = 1
-- Python host only if it exists (avoids startup probe cost when missing)
if vim.fn.executable("python3") == 1 then
    vim.g.python3_host_prog = vim.fn.exepath("python3")
end

-- ---------------------------------------------------------------------------
-- Monochrome theme: pure black <-> white, grays only. No hue anywhere.
-- Uses no-clown-fiesta (true grayscale theme) when installed, else habamax
-- fallback, then forces a full grayscale override + gray terminal palette.
-- ---------------------------------------------------------------------------
vim.opt.termguicolors = true
vim.opt.background = "dark"

local MONO = {
    bg        = "#000000",
    bg1       = "#0a0a0a",
    bg2       = "#111111",
    bg3       = "#1a1a1a",
    bg4       = "#222222",
    sel       = "#333333",
    border    = "#444444",
    muted     = "#555555",
    dim       = "#777777",
    mid       = "#aaaaaa",
    fg        = "#dddddd",
    bright    = "#eeeeee",
    white     = "#ffffff",
}

-- Terminal palette: black bg + the same 3 accent families + grays, so
-- :terminal / lazygit agree with the editor without adding new hues
for i, c in ipairs({
    "#000000", "#a08850", "#9ab89a", "#c9a86a",
    "#7fa8c9", "#7a9a7a", "#5a8ab0", "#dddddd",
    "#555555", "#e0c090", "#b8d0b8", "#f0d8a8",
    "#a8c8e0", "#8a9a8a", "#a8a080", "#ffffff",
}) do
    vim.g["terminal_color_" .. (i - 1)] = c
end

-- Color scheme: black & white base + exactly 3 accent hues (each with shades).
--   BLUE  (control + callable): keywords, loops, functions, tags
--   GREEN (data / literals):    strings, numbers, constants
--   AMBER (structure / types):   classes, types, modules, decorators
-- Variables / fields / params / operators stay pure B&W (brightness + italic).
local ACC = {
    blue     = "#7fa8c9",
    blue_lt  = "#a8c8e0",
    green    = "#9ab89a",
    green_lt = "#b8d0b8",
    amber    = "#c9a86a",
    amber_lt = "#e0c090",
    amber_dk = "#a08850",
}

local function apply_mono()
    local hl = vim.api.nvim_set_hl
    -- Base
    hl(0, "Normal", { bg = MONO.bg, fg = MONO.bright })
    hl(0, "NormalFloat", { bg = MONO.bg1, fg = MONO.bright })
    hl(0, "FloatBorder", { bg = MONO.bg1, fg = MONO.border })
    hl(0, "FloatTitle", { bg = MONO.bg1, fg = MONO.white, bold = true })
    hl(0, "SignColumn", { bg = MONO.bg, fg = MONO.dim })
    hl(0, "LineNr", { fg = MONO.muted })
    hl(0, "CursorLine", { bg = MONO.bg3 })
    hl(0, "CursorLineNr", { fg = MONO.mid })
    hl(0, "CursorColumn", { bg = MONO.bg3 })
    hl(0, "ColorColumn", { bg = MONO.bg2 })
    hl(0, "Visual", { bg = MONO.sel, fg = MONO.white })
    hl(0, "Search", { bg = MONO.muted, fg = MONO.white })
    hl(0, "IncSearch", { bg = MONO.bright, fg = MONO.bg })
    hl(0, "CurSearch", { bg = MONO.bright, fg = MONO.bg })
    hl(0, "MatchParen", { fg = MONO.white, bold = true, underline = true })
    hl(0, "WinSeparator", { fg = MONO.border })
    hl(0, "VertSplit", { fg = MONO.border })
    hl(0, "EndOfBuffer", { fg = MONO.bg2 })
    hl(0, "NonText", { fg = MONO.muted })
    hl(0, "SpecialKey", { fg = MONO.muted })
    hl(0, "Whitespace", { fg = MONO.muted })
    hl(0, "Folded", { bg = MONO.bg2, fg = MONO.dim })
    hl(0, "FoldColumn", { bg = MONO.bg, fg = MONO.muted })
    hl(0, "Title", { fg = MONO.white, bold = true })
    hl(0, "Directory", { fg = MONO.bright })
    hl(0, "ErrorMsg", { fg = MONO.white, bold = true })
    hl(0, "WarningMsg", { fg = MONO.mid, bold = true })
    hl(0, "ModeMsg", { fg = MONO.mid })
    hl(0, "MoreMsg", { fg = MONO.mid })
    hl(0, "Question", { fg = MONO.white })
    -- Popup menu (completion stays readable, still grayscale)
    hl(0, "Pmenu", { bg = MONO.bg2, fg = MONO.bright })
    hl(0, "PmenuSel", { bg = MONO.sel, fg = MONO.white, bold = true })
    hl(0, "PmenuSbar", { bg = MONO.bg2 })
    hl(0, "PmenuThumb", { bg = MONO.border })
    hl(0, "PmenuKind", { fg = MONO.dim })
    hl(0, "PmenuKindSel", { fg = MONO.white })
    hl(0, "PmenuExtra", { fg = MONO.dim })
    hl(0, "PmenuExtraSel", { fg = MONO.white })
    -- Status / tab line (matches custom statusline below)
    hl(0, "StatusLine", { bg = MONO.bg2, fg = MONO.bright })
    hl(0, "StatusLineNC", { bg = MONO.bg1, fg = MONO.muted })
    hl(0, "TabLine", { bg = MONO.bg1, fg = MONO.dim })
    hl(0, "TabLineSel", { bg = MONO.bg3, fg = MONO.white, bold = true })
    hl(0, "TabLineFill", { bg = MONO.bg })
    hl(0, "WildMenu", { bg = MONO.sel, fg = MONO.white })
    -- Classic syntax: B&W base + 3 accent families (blue/green/amber)
    hl(0, "Comment", { fg = MONO.dim, italic = true })
    hl(0, "Constant", { fg = ACC.green_lt })
    hl(0, "String", { fg = ACC.green })
    hl(0, "Character", { fg = ACC.green })
    hl(0, "Number", { fg = ACC.green_lt, bold = true })
    hl(0, "Boolean", { fg = ACC.green_lt, bold = true })
    hl(0, "Float", { fg = ACC.green_lt })
    hl(0, "Identifier", { fg = MONO.bright })
    hl(0, "Function", { fg = ACC.blue_lt, bold = true })
    hl(0, "Statement", { fg = ACC.blue, bold = true })
    hl(0, "Keyword", { fg = ACC.blue, bold = true })
    hl(0, "Conditional", { fg = ACC.blue, bold = true })
    hl(0, "Repeat", { fg = ACC.blue, bold = true })
    hl(0, "Label", { fg = ACC.blue })
    hl(0, "Exception", { fg = ACC.blue, bold = true })
    hl(0, "Operator", { fg = MONO.mid })
    hl(0, "PreProc", { fg = ACC.blue })
    hl(0, "Include", { fg = ACC.blue, bold = true })
    hl(0, "Define", { fg = ACC.amber_lt })
    hl(0, "Macro", { fg = ACC.amber_lt })
    hl(0, "Type", { fg = ACC.amber })
    hl(0, "StorageClass", { fg = ACC.blue })
    hl(0, "Structure", { fg = ACC.amber, bold = true })
    hl(0, "Typedef", { fg = ACC.amber })
    hl(0, "Special", { fg = MONO.mid })
    hl(0, "SpecialChar", { fg = ACC.green })
    hl(0, "Tag", { fg = ACC.blue })
    hl(0, "Delimiter", { fg = MONO.dim })
    hl(0, "SpecialComment", { fg = MONO.dim, italic = true })
    hl(0, "Debug", { fg = ACC.green_lt })
    hl(0, "Underlined", { fg = ACC.blue, underline = true })
    hl(0, "Todo", { bg = MONO.sel, fg = MONO.white, bold = true })
    -- Treesitter: B&W for variables/structure, 3 hues for the rest
    local ts = {
        -- Comments / strings / numbers (green family = data)
        ["@comment"] = { fg = MONO.dim, italic = true },
        ["@comment.error"] = { fg = MONO.white, bold = true },
        ["@comment.warning"] = { fg = ACC.amber, bold = true },
        ["@comment.todo"] = { bg = MONO.sel, fg = MONO.white, bold = true },
        ["@string"] = { fg = ACC.green },
        ["@string.escape"] = { fg = ACC.green_lt },
        ["@string.regexp"] = { fg = ACC.green, italic = true },
        ["@string.special"] = { fg = ACC.green },
        ["@string.special.symbol"] = { fg = MONO.bright },
        ["@character"] = { fg = ACC.green },
        ["@character.special"] = { fg = ACC.green_lt },
        ["@number"] = { fg = ACC.green_lt, bold = true },
        ["@number.float"] = { fg = ACC.green_lt },
        ["@boolean"] = { fg = ACC.green_lt, bold = true },
        ["@constant"] = { fg = ACC.green_lt },
        ["@constant.builtin"] = { fg = ACC.green_lt, bold = true },
        ["@constant.macro"] = { fg = ACC.amber_lt },
        -- Variables / fields / params stay B&W (brightness + italic only)
        ["@variable"] = { fg = MONO.bright },
        ["@variable.builtin"] = { fg = MONO.bright, italic = true },
        ["@variable.member"] = { fg = MONO.mid },
        ["@parameter"] = { fg = MONO.bright, italic = true },
        ["@parameter.builtin"] = { fg = MONO.bright, italic = true, bold = true },
        ["@property"] = { fg = MONO.mid },
        ["@field"] = { fg = MONO.mid },
        -- Functions / methods / calls (blue family, light shade)
        ["@function"] = { fg = ACC.blue_lt, bold = true },
        ["@function.builtin"] = { fg = ACC.blue_lt },
        ["@function.call"] = { fg = ACC.blue_lt },
        ["@function.macro"] = { fg = ACC.amber_lt, bold = true },
        ["@method"] = { fg = ACC.blue_lt, bold = true },
        ["@method.call"] = { fg = ACC.blue_lt },
        -- Classes / types / constructors (amber family)
        ["@constructor"] = { fg = ACC.amber, bold = true },
        ["@type"] = { fg = ACC.amber },
        ["@type.builtin"] = { fg = ACC.amber, bold = true },
        ["@type.definition"] = { fg = ACC.amber, bold = true },
        ["@type.qualifier"] = { fg = ACC.blue },
        ["@storageclass"] = { fg = ACC.blue },
        -- Modules / namespaces (amber family, dark shade)
        ["@module"] = { fg = ACC.amber_dk },
        ["@module.builtin"] = { fg = ACC.amber_dk, bold = true },
        ["@namespace"] = { fg = ACC.amber_dk },
        ["@namespace.builtin"] = { fg = ACC.amber_dk, bold = true },
        ["@symbol"] = { fg = MONO.bright },
        -- Keywords / control flow / imports / exceptions (blue family)
        ["@keyword"] = { fg = ACC.blue, bold = true },
        ["@keyword.function"] = { fg = ACC.blue, bold = true },
        ["@keyword.operator"] = { fg = ACC.blue },
        ["@keyword.import"] = { fg = ACC.blue, bold = true },
        ["@keyword.storage"] = { fg = ACC.blue },
        ["@keyword.repeat"] = { fg = ACC.blue, bold = true },
        ["@keyword.return"] = { fg = ACC.blue, bold = true },
        ["@keyword.exception"] = { fg = ACC.blue, bold = true },
        ["@keyword.debug"] = { fg = ACC.green_lt },
        ["@conditional"] = { fg = ACC.blue, bold = true },
        ["@repeat"] = { fg = ACC.blue, bold = true },
        ["@exception"] = { fg = ACC.blue, bold = true },
        ["@include"] = { fg = ACC.blue, bold = true },
        ["@label"] = { fg = ACC.blue },
        ["@operator"] = { fg = MONO.mid },
        -- Decorators / annotations / macros / defines (amber family, light)
        ["@attribute"] = { fg = ACC.amber_lt },
        ["@attribute.builtin"] = { fg = ACC.amber_lt, bold = true },
        ["@macro"] = { fg = ACC.amber_lt },
        ["@define"] = { fg = ACC.amber_lt },
        ["@debug"] = { fg = ACC.green_lt },
        ["@punctuation.bracket"] = { fg = MONO.dim },
        ["@punctuation.delimiter"] = { fg = MONO.dim },
        ["@punctuation.special"] = { fg = MONO.mid },
        ["@tag"] = { fg = ACC.blue },
        ["@tag.attribute"] = { fg = ACC.green, italic = true },
        ["@tag.delimiter"] = { fg = MONO.dim },
        ["@markup.heading"] = { fg = MONO.white, bold = true },
        ["@markup.bold"] = { fg = MONO.white, bold = true },
        ["@markup.italic"] = { fg = MONO.bright, italic = true },
        ["@markup.link"] = { fg = ACC.blue, underline = true },
        ["@markup.raw"] = { fg = ACC.green },
        ["@markup.list"] = { fg = MONO.mid },
        ["@diff.plus"] = { fg = MONO.white },
        ["@diff.minus"] = { fg = MONO.muted },
        ["@diff.delta"] = { fg = MONO.mid },
    }
    for g, v in pairs(ts) do hl(0, g, v) end
    -- LSP semantic tokens (what pyright/ts_ls/rust-analyzer actually emit for
    -- classes, structs, enums, interfaces, namespaces, decorators...). Without
    -- these, class names fall back to the theme default and look uncolored.
    local lsp = {
        ["@lsp.type.class"] = { fg = ACC.amber, bold = true },
        ["@lsp.type.struct"] = { fg = ACC.amber, bold = true },
        ["@lsp.type.enum"] = { fg = ACC.amber },
        ["@lsp.type.enumMember"] = { fg = ACC.green_lt },
        ["@lsp.type.interface"] = { fg = ACC.amber, italic = true },
        ["@lsp.type.type"] = { fg = ACC.amber },
        ["@lsp.type.typeParameter"] = { fg = ACC.amber, italic = true },
        ["@lsp.type.namespace"] = { fg = ACC.amber_dk },
        ["@lsp.type.module"] = { fg = ACC.amber_dk },
        ["@lsp.type.function"] = { fg = ACC.blue_lt, bold = true },
        ["@lsp.type.method"] = { fg = ACC.blue_lt, bold = true },
        ["@lsp.type.macro"] = { fg = ACC.amber_lt },
        ["@lsp.type.decorator"] = { fg = ACC.amber_lt },
        ["@lsp.type.variable"] = { fg = MONO.bright },
        ["@lsp.type.parameter"] = { fg = MONO.bright, italic = true },
        ["@lsp.type.property"] = { fg = MONO.mid },
        ["@lsp.type.field"] = { fg = MONO.mid },
        ["@lsp.type.string"] = { fg = ACC.green },
        ["@lsp.type.number"] = { fg = ACC.green_lt },
        ["@lsp.type.boolean"] = { fg = ACC.green_lt, bold = true },
        ["@lsp.type.keyword"] = { fg = ACC.blue, bold = true },
        ["@lsp.type.operator"] = { fg = MONO.mid },
        ["@lsp.type.comment"] = { fg = MONO.dim, italic = true },
        ["@lsp.mod.readonly"] = { italic = true },
        ["@lsp.mod.static"] = { bold = true },
    }
    for g, v in pairs(lsp) do hl(0, g, v) end
    -- Diagnostics: grayscale + distinct prefixes (no red/yellow/blue/green)
    hl(0, "DiagnosticError", { fg = MONO.white, bold = true })
    hl(0, "DiagnosticWarn", { fg = MONO.bright })
    hl(0, "DiagnosticInfo", { fg = MONO.mid })
    hl(0, "DiagnosticHint", { fg = MONO.dim, italic = true })
    hl(0, "DiagnosticUnderlineError", { sp = MONO.white, undercurl = true })
    hl(0, "DiagnosticUnderlineWarn", { sp = MONO.mid, undercurl = true })
    hl(0, "DiagnosticUnderlineInfo", { sp = MONO.dim, undercurl = true })
    hl(0, "DiagnosticUnderlineHint", { sp = MONO.muted, undercurl = true })
    hl(0, "DiagnosticSignError", { fg = MONO.white })
    hl(0, "DiagnosticSignWarn", { fg = MONO.mid })
    hl(0, "DiagnosticSignInfo", { fg = MONO.dim })
    hl(0, "DiagnosticSignHint", { fg = MONO.muted })
    -- Diff / git: light-vs-dark gray only (plus=+white, minus=dim)
    hl(0, "DiffAdd", { bg = MONO.bg2, fg = MONO.white })
    hl(0, "DiffChange", { bg = MONO.bg2, fg = MONO.mid })
    hl(0, "DiffDelete", { bg = MONO.bg, fg = MONO.muted })
    hl(0, "DiffText", { bg = MONO.sel, fg = MONO.white, bold = true })
    hl(0, "Added", { fg = MONO.white })
    hl(0, "Removed", { fg = MONO.muted })
    hl(0, "Changed", { fg = MONO.mid })
    hl(0, "GitSignsAdd", { fg = MONO.bright })
    hl(0, "GitSignsChange", { fg = MONO.mid })
    hl(0, "GitSignsDelete", { fg = MONO.muted })
    hl(0, "GitSignsUntracked", { fg = MONO.dim })
    -- Telescope / Trouble / WhichKey / completion menus
    hl(0, "TelescopeNormal", { bg = MONO.bg, fg = MONO.bright })
    hl(0, "TelescopeBorder", { bg = MONO.bg, fg = MONO.border })
    hl(0, "TelescopePromptNormal", { bg = MONO.bg1, fg = MONO.white })
    hl(0, "TelescopePromptBorder", { bg = MONO.bg1, fg = MONO.border })
    hl(0, "TelescopeResultsNormal", { bg = MONO.bg, fg = MONO.bright })
    hl(0, "TelescopePreviewNormal", { bg = MONO.bg, fg = MONO.bright })
    hl(0, "TelescopeSelection", { bg = MONO.sel, fg = MONO.white })
    hl(0, "TelescopeSelectionCaret", { fg = MONO.white })
    hl(0, "TelescopeMatching", { fg = MONO.white, bold = true })
    hl(0, "TroubleNormal", { bg = MONO.bg, fg = MONO.bright })
    hl(0, "TroubleText", { fg = MONO.bright })
    hl(0, "TroubleCount", { bg = MONO.sel, fg = MONO.white, bold = true })
    hl(0, "WhichKey", { fg = MONO.white, bold = true })
    hl(0, "WhichKeyDesc", { fg = MONO.bright })
    hl(0, "WhichKeyGroup", { fg = MONO.mid })
    hl(0, "CmpItemAbbr", { fg = MONO.bright })
    hl(0, "CmpItemAbbrMatch", { fg = MONO.white, bold = true })
    hl(0, "CmpItemAbbrMatchFuzzy", { fg = MONO.white, bold = true })
    hl(0, "CmpItemMenu", { fg = MONO.dim })
    hl(0, "CmpItemKind", { fg = MONO.mid })
    -- LSP extras
    hl(0, "LspInlayHint", { bg = MONO.bg1, fg = MONO.muted, italic = true })
    hl(0, "LspReferenceText", { bg = MONO.sel })
    hl(0, "LspReferenceRead", { bg = MONO.sel })
    hl(0, "LspReferenceWrite", { bg = MONO.sel })
    hl(0, "LspSignatureActiveParameter", { fg = MONO.white, bold = true })
    -- Custom statusline segments
    hl(0, "User1", { bg = MONO.bg2, fg = MONO.white, bold = true })
    hl(0, "User2", { bg = MONO.bg2, fg = MONO.dim })
    hl(0, "User3", { bg = MONO.bg2, fg = MONO.mid })
end

-- Prefer true-grayscale theme plugin; fall back to built-in habamax.
-- Either way apply_mono() forces pure black/white afterwards.
if not pcall(vim.cmd.colorscheme, "no-clown-fiesta") then
    pcall(vim.cmd.colorscheme, "habamax")
end
apply_mono()
vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function() apply_mono() end,
    desc = "Re-enforce monochrome after any colorscheme change",
})

-- ---------------------------------------------------------------------------
-- Options: editor behavior + performance
-- ---------------------------------------------------------------------------
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 10
opt.wrap = false -- production code: no soft wrap; <leader>uw toggles
opt.linebreak = true
opt.breakindent = true
opt.showbreak = "  "

-- Indent: 2 spaces default (JS/TS/JSON/YAML/TOML/Markdown), 4 for C/C++/Python/Rust/Lua
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
opt.iskeyword:append("-")

opt.backspace = "indent,eol,start"
opt.clipboard = "unnamedplus"
opt.splitright = true
opt.splitbelow = true
opt.equalalways = false

-- No swap/backup (fast + clean), persistent undo, snappy keys
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.undofile = true
opt.undolevels = 10000
opt.timeoutlen = 300
opt.ttimeoutlen = 10
opt.updatetime = 200 -- fast diagnostics + gitsigns + hover
opt.scrollback = 10000
opt.shada = "!,'200,<50,s10,h" -- small shada = faster startup
opt.history = 200
opt.synmaxcol = 300 -- don't syntax-highlight absurdly long lines (minified files)
opt.redrawtime = 1500
opt.ttyfast = true
opt.lazyredraw = false -- keep false on nvim (flicker-free); perf comes from below
opt.hidden = true
opt.confirm = true -- ask to save instead of erroring on :q with changes
opt.autoread = true
opt.mouse = "a"
opt.mousescroll = "ver:3,hor:6"

-- Completion popup behavior
opt.completeopt = "menu,menuone,noselect"
opt.pumheight = 12
opt.pumblend = 0
opt.winblend = 0

-- Splits / folds / grep integration
opt.winminwidth = 5
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99 -- start unfolded
opt.foldtext = ""
opt.grepprg = "rg --vimgrep --smart-case --hidden --glob '!{.git,node_modules,target,dist,build,.venv}/**'"
opt.grepformat = "%f:%l:%c:%m"

-- netrw already disabled (oil.nvim replaces :Ex)

-- ---------------------------------------------------------------------------
-- Plugins (native vim.pack, no manager overhead). :PackUpdate to update.
-- No AI / no icon-color plugins on purpose (monochrome + fast).
-- ---------------------------------------------------------------------------
pcall(vim.pack.add, {
    "https://github.com/aktersnurra/no-clown-fiesta.nvim", -- true B&W theme
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/nvim-telescope/telescope.nvim",
    "https://github.com/nvim-treesitter/nvim-treesitter",
    "https://github.com/stevearc/oil.nvim",
    "https://github.com/lewis6991/gitsigns.nvim",
    "https://github.com/stevearc/conform.nvim",
    "https://github.com/folke/which-key.nvim",
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/hrsh7th/nvim-cmp",
    "https://github.com/hrsh7th/cmp-nvim-lsp",
    "https://github.com/hrsh7th/cmp-buffer",
    "https://github.com/hrsh7th/cmp-path",
    "https://github.com/L3MON4D3/LuaSnip",
    "https://github.com/rafamadriz/friendly-snippets",
    "https://github.com/windwp/nvim-autopairs",
    "https://github.com/mfussenegger/nvim-lint",
    -- IDE essentials (tiny, no AI):
    "https://github.com/numToStr/Comment.nvim", -- gc commenting
    "https://github.com/kylechui/nvim-surround", -- ys/cs/ds surround
    "https://github.com/smjonas/inc-rename.nvim", -- live project-wide LSP rename
    "https://github.com/folke/trouble.nvim", -- diagnostics / references list
})

-- Plugin setup (all guarded so first run before :PackUpdate still works)
pcall(function() require("oil").setup({ view_options = { show_hidden = true } }) end)
pcall(function()
    require("gitsigns").setup({
        signcolumn = true,
        numhl = false,
        current_line_blame = false, -- toggle with <leader>gb (off = faster)
        update_debounce = 200,
        preview_config = { border = "single" },
    })
end)
pcall(function()
    require("conform").setup({
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
            prettier = { prepend_args = { "--single-quote", "--trailing-comma", "all", "--print-width", "1000" } },
            ruff_format = { args = { "format", "--line-length", "1000", "-" } },
        },
    })
end)
pcall(function() require("which-key").setup({ preset = "helix" }) end)
pcall(function()
    require("telescope").setup({
        defaults = {
            layout_strategy = "horizontal",
            sorting_strategy = "ascending",
            -- rg-backed, respects .gitignore, skips heavy dirs
            vimgrep_arguments = {
                "rg", "--color=never", "--no-heading", "--with-filename",
                "--line-number", "--column", "--smart-case", "--hidden",
                "--glob", "!{.git,node_modules,target,dist,build,coverage,.venv,__pycache__}/**",
            },
            file_ignore_patterns = {
                "%.git/", "node_modules/", "target/", "dist/", "build/",
                "%.venv/", "__pycache__/", "%.lock", "%.min%.js",
            },
            borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        },
        pickers = {
            find_files = {
                hidden = true,
                find_command = {
                    "fd", "--type", "f", "--hidden", "--strip-cwd-prefix",
                    "--exclude", ".git", "--exclude", "node_modules",
                    "--exclude", "target", "--exclude", "dist",
                    "--exclude", "build", "--exclude", ".venv",
                    "--exclude", "__pycache__",
                },
            },
            live_grep = { additional_args = { "--hidden" } },
            buffers = { sort_mru = true, ignore_current_buffer = true },
        },
    })
end)
-- Treesitter: new main-branch API (0.12). install() self-heals missing parsers.
pcall(function()
    require("nvim-treesitter").setup({
        ensure_install = {},
        auto_install = false,
        highlight = { enable = true },
        indent = { enable = true },
    })
    require("nvim-treesitter").install({
        "javascript", "typescript", "tsx", "html", "css",
        "json", "python", "rust", "lua", "c", "cpp",
        "markdown", "markdown_inline", "yaml", "toml", "bash",
    })
end)

pcall(function()
    require("luasnip.loaders.from_vscode").lazy_load()
end)

-- Completion: LSP + snippets + path + buffer. No AI source.
pcall(function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    cmp.setup({
        preselect = cmp.PreselectMode.Item,
        performance = { max_view_entries = 30, fetching_timeout = 100 },
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
            { name = "nvim_lsp", max_item_count = 30 },
            { name = "luasnip", max_item_count = 10 },
            { name = "path", max_item_count = 10 },
        }, {
            { name = "buffer", max_item_count = 10, keyword_length = 3 },
        }),
        window = {
            completion = cmp.config.window.bordered(),
            documentation = cmp.config.window.bordered(),
        },
    })
end)

pcall(function()
    require("nvim-autopairs").setup({ check_ts = true })
    local ok_cmp, cmp = pcall(require, "cmp")
    if ok_cmp then
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end
end)

-- Auto-lint: eslint_d (fast daemon) w/ eslint fallback; python via ruff.
pcall(function()
    local lint = require("lint")
    lint.linters_by_ft = {
        javascript = { vim.fn.executable("eslint_d") == 1 and "eslint_d" or "eslint" },
        typescript = { vim.fn.executable("eslint_d") == 1 and "eslint_d" or "eslint" },
        javascriptreact = { vim.fn.executable("eslint_d") == 1 and "eslint_d" or "eslint" },
        typescriptreact = { vim.fn.executable("eslint_d") == 1 and "eslint_d" or "eslint" },
        python = { "ruff" },
    }
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

-- Commenting (gc / gcc / visual gc) + surround (ysiw" / cs"' / ds")
pcall(function() require("Comment").setup() end)
pcall(function() require("nvim-surround").setup() end)
-- Live rename preview: :IncRename <new-name> renames ALL refs project-wide via LSP
pcall(function() require("inc_rename").setup({ preview_empty_name = true }) end)
-- Trouble: single diagnostics / references / symbols list
pcall(function()
    require("trouble").setup({
        auto_close = false,
        focus = true,
        warn_no_results = false,
        open_no_results = false,
    })
end)

-- ---------------------------------------------------------------------------
-- Minimal monochrome statusline (no plugin = fastest). Mode + branch + file
-- + LSP + diagnostics + position. Hidden entirely in zen mode.
-- ---------------------------------------------------------------------------
function _G.MonoStatus()
    local mode_map = {
        n = "N", i = "I", v = "V", V = "V", ["\22"] = "V",
        c = "C", s = "S", S = "S", R = "R", t = "T",
    }
    local m = mode_map[vim.fn.mode()] or vim.fn.mode()
    local branch = vim.b.gitsigns_head or vim.g.gitsigns_head or ""
    if branch ~= "" then branch = " " .. branch end
    local name = vim.fn.expand("%:t")
    if name == "" then name = "[no name]" end
    local mod = vim.bo.modified and " +" or ""
    local ro = vim.bo.readonly and " [ro]" or ""
    -- LSP clients attached to this buffer
    local clients = ""
    local ok, attached = pcall(vim.lsp.get_clients, { bufnr = 0 })
    if ok and attached and #attached > 0 then
        local names = {}
        for _, c in ipairs(attached) do names[#names + 1] = c.name end
        clients = " [" .. table.concat(names, ",") .. "]"
    end
    -- Diagnostics counts (E/W/I/H, grayscale by letter not color)
    local d = ""
    local okd, counts = pcall(vim.diagnostic.count, 0)
    if okd and counts then
        local parts = {}
        if (counts[1] or 0) > 0 then parts[#parts + 1] = "E" .. counts[1] end
        if (counts[2] or 0) > 0 then parts[#parts + 1] = "W" .. counts[2] end
        if (counts[3] or 0) > 0 then parts[#parts + 1] = "I" .. counts[3] end
        if (counts[4] or 0) > 0 then parts[#parts + 1] = "H" .. counts[4] end
        if #parts > 0 then d = " " .. table.concat(parts, " ") end
    end
    local pos = "%l:%c %p%%"
    return string.format("%%#User1# %s%s %%#User2#%%f%s%s%%#User3#%s%s %%=%%#User2#%s ", m, branch, mod, ro, clients, d, pos)
end
vim.o.laststatus = 3 -- single global statusline (faster than per-window)
vim.o.statusline = "%!v:lua.MonoStatus()"
vim.o.showmode = false -- mode already in statusline
vim.o.showcmd = true
vim.o.ruler = false -- position already in statusline

-- ---------------------------------------------------------------------------
-- Keymaps (which-key groups: <leader>f find, <leader>l lsp, <leader>g git,
-- <leader>b buffer, <leader>r refactor/rename, <leader>x diagnostics,
-- <leader>t terminal/session, <leader>u toggle)
-- ---------------------------------------------------------------------------
local keymap = vim.keymap.set

-- File explorer / save / quit
keymap("n", "<leader>e", function() pcall(require("oil").open) end, { desc = "File explorer (oil)" })
keymap("n", "<leader>w", ":w<CR>", { desc = "Save" })
keymap("n", "<leader>q", ":q<CR>", { desc = "Quit" })
keymap("n", "<leader>Q", ":qa!<CR>", { desc = "Quit all (no save)" })

-- Find (telescope, rg-backed)
keymap("n", "<leader>ff", function() pcall(require("telescope.builtin").find_files) end, { desc = "Find files" })
keymap("n", "<leader>fg", function() pcall(require("telescope.builtin").live_grep) end, { desc = "Live grep (project)" })
keymap("n", "<leader>fG", function()
    pcall(require("telescope.builtin").grep_string, { search = vim.fn.expand("<cword>") })
end, { desc = "Grep word under cursor" })
keymap("v", "<leader>fg", function()
    local text = vim.fn.getreg('"')
    pcall(require("telescope.builtin").live_grep, { default_text = text })
end, { desc = "Grep selection" })
keymap("n", "<leader>fb", function() pcall(require("telescope.builtin").buffers) end, { desc = "Buffers" })
keymap("n", "<leader>fo", function() pcall(require("telescope.builtin").oldfiles) end, { desc = "Recent files" })
keymap("n", "<leader>fh", function() pcall(require("telescope.builtin").help_tags) end, { desc = "Help" })
keymap("n", "<leader>fk", function() pcall(require("telescope.builtin").keymaps) end, { desc = "Keymaps" })
keymap("n", "<leader>fr", function() pcall(require("telescope.builtin").resume) end, { desc = "Resume last picker" })
keymap("n", "<leader>fd", function() pcall(require("telescope.builtin").diagnostics) end, { desc = "Diagnostics" })
keymap("n", "<leader>fs", function() pcall(require("telescope.builtin").lsp_document_symbols) end, { desc = "Document symbols" })
keymap("n", "<leader>fS", function() pcall(require("telescope.builtin").lsp_workspace_symbols) end, { desc = "Workspace symbols" })
keymap("n", "<leader>gc", function() pcall(require("telescope.builtin").git_commits) end, { desc = "Git commits" })
keymap("n", "<leader>gS", function() pcall(require("telescope.builtin").git_status) end, { desc = "Git status files" })

-- Project-wide search via :grep (quickfix) as a telescope alternative
if vim.fn.executable("rg") == 1 then
    keymap("n", "<leader>R", function()
        local query = vim.fn.input("Rg: ")
        if query ~= "" then
            vim.cmd("grep! " .. vim.fn.shellescape(query))
            vim.cmd("copen")
        end
    end, { desc = "Ripgrep -> quickfix" })
end

-- Buffers: fast cycle + close without losing splits
keymap("n", "<S-h>", ":bprevious<CR>", { desc = "Prev buffer" })
keymap("n", "<S-l>", ":bnext<CR>", { desc = "Next buffer" })
keymap("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
keymap("n", "<leader>bp", ":bprevious<CR>", { desc = "Prev buffer" })
keymap("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })
keymap("n", "<leader>bD", ":bdelete!<CR>", { desc = "Delete buffer (force)" })

-- Windows: navigation + resize + splits
keymap("n", "<C-h>", "<C-w>h", { desc = "Window left" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Window down" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Window up" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Window right" })
keymap("n", "<C-Up>", ":resize +2<CR>", { desc = "Taller split" })
keymap("n", "<C-Down>", ":resize -2<CR>", { desc = "Shorter split" })
keymap("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Narrower split" })
keymap("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Wider split" })
keymap("n", "<leader>sv", ":vsp<CR>", { desc = "Vertical split" })
keymap("n", "<leader>sh", ":sp<CR>", { desc = "Horizontal split" })
keymap("n", "<leader>sx", ":close<CR>", { desc = "Close split" })
keymap("n", "<leader>se", "<C-w>=", { desc = "Equalize splits" })

-- Move lines (visual) + keep cursor centered + better indent behavior
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
keymap("n", "n", "nzzzv", { desc = "Next search (centered)" })
keymap("n", "N", "Nzzzv", { desc = "Prev search (centered)" })
keymap("n", "<C-d>", "<C-d>zz", { desc = "Half-page down (centered)" })
keymap("n", "<C-u>", "<C-u>zz", { desc = "Half-page up (centered)" })
keymap("v", "<", "<gv", { desc = "Indent left (stay visual)" })
keymap("v", ">", ">gv", { desc = "Indent right (stay visual)" })
keymap("v", "p", '"_dP', { desc = "Paste (keep yank)" })

-- Quickfix / location list navigation (project search + diagnostics flow)
keymap("n", "]q", ":cnext<CR>zz", { desc = "Next quickfix" })
keymap("n", "[q", ":cprev<CR>zz", { desc = "Prev quickfix" })
keymap("n", "<leader>qo", ":copen<CR>", { desc = "Open quickfix" })
keymap("n", "<leader>qc", ":cclose<CR>", { desc = "Close quickfix" })

-- Diagnostics UI
vim.diagnostic.config({
    virtual_text = { spacing = 2, prefix = "●" },
    signs = { text = { [1] = "E", [2] = "W", [3] = "I", [4] = "H" } },
    underline = true,
    update_in_insert = false,
    severity_sort = true,
})
keymap("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })
keymap("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
keymap("n", "<leader>xx", function() pcall(require("trouble").toggle, "diagnostics") end, { desc = "Trouble: diagnostics" })
keymap("n", "<leader>xb", function() pcall(require("trouble").toggle, "diagnostics", { filter = { buf = 0 } }) end, { desc = "Trouble: buffer diagnostics" })
keymap("n", "<leader>xq", function() pcall(require("trouble").toggle, "quickfix") end, { desc = "Trouble: quickfix" })
keymap("n", "<leader>xl", function() pcall(require("trouble").toggle, "loclist") end, { desc = "Trouble: loclist" })
keymap("n", "<leader>xs", function() pcall(require("trouble").toggle, "symbols") end, { desc = "Trouble: symbols" })

-- Toggles (production ergonomics)
keymap("n", "<leader>uw", function() vim.wo.wrap = not vim.wo.wrap end, { desc = "Toggle wrap" })
keymap("n", "<leader>us", function() vim.wo.spell = not vim.wo.spell end, { desc = "Toggle spell" })
keymap("n", "<leader>uv", function()
    local vt = vim.diagnostic.config().virtual_text
    vim.diagnostic.config({ virtual_text = not vt })
end, { desc = "Toggle diagnostic text" })
keymap("n", "<leader>uh", function()
    local cur = vim.lsp.inlay_hint and vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
    if vim.lsp.inlay_hint then vim.lsp.inlay_hint.enable(not cur, { bufnr = 0 }) end
end, { desc = "Toggle inlay hints" })
keymap("n", "<leader>un", function()
    vim.wo.number = not vim.wo.number
    vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = "Toggle line numbers" })

-- Zen mode: hide statusline/tabline/ruler/mode — silent toggle
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

-- Terminal: split + lazygit (no plugin, built-in terminal)
keymap("n", "<leader>tt", ":split | terminal<CR>", { desc = "Terminal (split)" })
keymap("n", "<leader>tv", ":vsplit | terminal<CR>", { desc = "Terminal (vsplit)" })
keymap("n", "<leader>gg", function()
    if vim.fn.executable("lazygit") ~= 1 then
        vim.notify("lazygit not installed", vim.log.levels.WARN)
        return
    end
    vim.cmd("tabnew | terminal lazygit")
end, { desc = "Lazygit" })
keymap("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
keymap("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Window left (term)" })
keymap("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Window down (term)" })
keymap("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Window up (term)" })
keymap("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Window right (term)" })

-- Session: save / restore without plugins (uses :mksession)
keymap("n", "<leader>qs", ":mksession! Session.vim<CR>", { desc = "Save session" })
keymap("n", "<leader>qr", ":source Session.vim<CR>", { desc = "Restore session" })

-- Refactor entry points (global fallback; LspAttach redefines per-buffer with
-- richer behavior). Guarantees <leader>rn exists even before any LSP attaches.
keymap("n", "<leader>rn", function()
    local ok, _ = pcall(vim.cmd, "IncRename " .. vim.fn.expand("<cword>"))
    if not ok then
        if vim.lsp.buf.rename then
            vim.lsp.buf.rename()
        else
            vim.notify("No LSP attached — rename unavailable", vim.log.levels.WARN)
        end
    end
end, { desc = "Rename all refs (project)" })

-- ---------------------------------------------------------------------------
-- LSP
-- ---------------------------------------------------------------------------
-- Let servers know nvim-cmp is available (full suggestion lists)
pcall(function()
    local ok_cmp = pcall(require, "cmp_nvim_lsp")
    if ok_cmp then
        local capabilities = require("cmp_nvim_lsp").default_capabilities()
        pcall(vim.lsp.config, "*", { capabilities = capabilities })
    end
end)

local ok_lsp, lspconfig = pcall(require, "lspconfig")
if ok_lsp then
    local servers = {
        ts_ls = "typescript-language-server",
        tailwindcss = "tailwindcss-language-server",
        eslint = "vscode-eslint-language-server",
        emmet_ls = "emmet-ls",
        html = "vscode-html-language-server",
        cssls = "vscode-css-language-server",
        jsonls = "vscode-json-language-server",
        pyright = "pyright",
        ruff = "ruff",
        rust_analyzer = "rust-analyzer",
        clangd = "clangd",
        lua_ls = "lua-language-server",
    }
    for ls, bin in pairs(servers) do
        if vim.fn.executable(bin) == 1 then
            if ls == "eslint" then
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
            elseif ls == "clangd" then
                pcall(vim.lsp.config, ls, {
                    cmd = {
                        "clangd", "--background-index", "--clang-tidy",
                        "--completion-style=detailed", "--header-insertion=iwyu",
                    },
                })
            end
            pcall(function() vim.lsp.enable(ls) end)
        end
    end
end

-- Auto-fix ESLint issues on save (JS/TS/JSX/TSX)
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
    callback = function() pcall(vim.cmd, "EslintFixAll") end,
})

-- Project-wide replace helper: grep word -> quickfix -> :cfdo substitute
local function project_replace()
    local word = vim.fn.expand("<cword>")
    local replacement = vim.fn.input("Replace '" .. word .. "' with: ")
    if replacement == "" then return end
    vim.cmd("grep! " .. vim.fn.shellescape(word))
    vim.cmd("copen")
    local cmd = "cfdo %s/\\<" .. word .. "\\>/" .. replacement .. "/g | update"
    vim.fn.setreg(":", cmd)
    vim.notify("Run :" .. cmd .. "  (loaded in : register — press : then <Up>)", vim.log.levels.INFO)
end

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local km = vim.keymap.set
        local buf = args.buf
        -- Navigation (production core)
        km("n", "gd", vim.lsp.buf.definition, { buffer = buf, desc = "Go to definition" })
        km("n", "gD", vim.lsp.buf.declaration, { buffer = buf, desc = "Go to declaration" })
        km("n", "gi", vim.lsp.buf.implementation, { buffer = buf, desc = "Go to implementation" })
        km("n", "go", vim.lsp.buf.type_definition, { buffer = buf, desc = "Go to type definition" })
        km("n", "gr", function() pcall(require("telescope.builtin").lsp_references) end, { buffer = buf, desc = "References (telescope)" })
        km("n", "K", vim.lsp.buf.hover, { buffer = buf, desc = "Hover" })
        km({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, { buffer = buf, desc = "Signature help" })
        -- Refactor / actions: rename is PROJECT-WIDE via LSP (all refs updated)
        km("n", "<leader>rn", function()
            local ok, _ = pcall(vim.cmd, "IncRename " .. vim.fn.expand("<cword>"))
            if not ok then vim.lsp.buf.rename() end
        end, { buffer = buf, desc = "Rename all refs (project)" })
        km("n", "<leader>rN", vim.lsp.buf.rename, { buffer = buf, desc = "Rename (plain LSP)" })
        km("n", "<leader>rp", project_replace, { buffer = buf, desc = "Replace word project-wide" })
        km("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = buf, desc = "Code action" })
        km("v", "<leader>ca", vim.lsp.buf.code_action, { buffer = buf, desc = "Code action" })
        km("n", "<leader>oi", function()
            vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
        end, { buffer = buf, desc = "Organize imports" })
        km("n", "<leader>f", function()
            pcall(function() require("conform").format({ async = false }) end)
        end, { buffer = buf, desc = "Format buffer" })
        -- Symbols
        km("n", "<leader>ds", function() pcall(require("telescope.builtin").lsp_document_symbols) end, { buffer = buf, desc = "Document symbols" })
        km("n", "<leader>ws", function() pcall(require("telescope.builtin").lsp_workspace_symbols) end, { buffer = buf, desc = "Workspace symbols" })
        -- Inlay hints on by default when server supports them (toggle: <leader>uh)
        if vim.lsp.inlay_hint then
            pcall(vim.lsp.inlay_hint.enable, true, { bufnr = buf })
        end
    end,
})

-- Gitsigns IDE keymaps (buffer-local, set on attach for zero cost elsewhere)
vim.api.nvim_create_autocmd("User", {
    pattern = "GitsignsAttach",
    callback = function(args)
        local gs = package.loaded.gitsigns
        if not gs then return end
        local km = vim.keymap.set
        local buf = args.buf or args.data and args.data.buf
        local o = { buffer = buf }
        km("n", "]h", function() gs.nav_hunk("next") end, vim.tbl_extend("force", o, { desc = "Next hunk" }))
        km("n", "[h", function() gs.nav_hunk("prev") end, vim.tbl_extend("force", o, { desc = "Prev hunk" }))
        km("n", "<leader>hs", gs.stage_hunk, vim.tbl_extend("force", o, { desc = "Stage hunk" }))
        km("n", "<leader>hr", gs.reset_hunk, vim.tbl_extend("force", o, { desc = "Reset hunk" }))
        km("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, vim.tbl_extend("force", o, { desc = "Stage selection" }))
        km("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, vim.tbl_extend("force", o, { desc = "Reset selection" }))
        km("n", "<leader>hS", gs.stage_buffer, vim.tbl_extend("force", o, { desc = "Stage buffer" }))
        km("n", "<leader>hR", gs.reset_buffer, vim.tbl_extend("force", o, { desc = "Reset buffer" }))
        km("n", "<leader>hp", gs.preview_hunk, vim.tbl_extend("force", o, { desc = "Preview hunk" }))
        km("n", "<leader>hb", function() gs.blame_line({ full = true }) end, vim.tbl_extend("force", o, { desc = "Blame line" }))
        km("n", "<leader>gb", gs.toggle_current_line_blame, vim.tbl_extend("force", o, { desc = "Toggle blame" }))
        km("n", "<leader>hd", gs.diffthis, vim.tbl_extend("force", o, { desc = "Diff this" }))
    end,
})

-- ---------------------------------------------------------------------------
-- Autocmds: production behavior + performance guards
-- ---------------------------------------------------------------------------
-- Highlight yank (confirms copy)
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function() vim.highlight.on_yank({ higroup = "Visual", timeout = 150 }) end,
})
-- Restore cursor position on reopen
vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})
-- Trim trailing whitespace on save (keeps diffs clean; formatter handles rest)
vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function()
        local view = vim.fn.winsaveview()
        pcall(vim.cmd, [[%s/\s\+$//e]])
        vim.fn.winrestview(view)
    end,
})
-- Auto-resize splits when terminal window changes
vim.api.nvim_create_autocmd("VimResized", {
    callback = function() vim.cmd("tabdo wincmd =") end,
})
-- Large files (>1MB): disable heavy features for speed
vim.api.nvim_create_autocmd("BufReadPre", {
    callback = function(args)
        local ok, stat = pcall(vim.loop.fs_stat, args.match)
        if ok and stat and stat.size > 1024 * 1024 then
            vim.b.large_file = true
            vim.opt_local.foldmethod = "manual"
            vim.opt_local.undofile = false
            vim.opt_local.swapfile = false
            vim.schedule(function()
                pcall(vim.treesitter.stop, args.buf)
                vim.notify("Large file: treesitter disabled for speed", vim.log.levels.INFO)
            end)
        end
    end,
})
-- Close help/quickfix/man with q
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "help", "qf", "man", "checkhealth" },
    callback = function(args)
        vim.keymap.set("n", "q", ":close<CR>", { buffer = args.buf, silent = true })
    end,
})
