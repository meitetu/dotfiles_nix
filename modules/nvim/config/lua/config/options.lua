local opt = vim.opt

-- leader はプラグイン読み込みより前に設定する
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- クリップボード: 使えるプロバイダがあるときだけ unnamedplus にする
local function clipboard_provider()
  if vim.fn.has("wsl") == 1 then return "unnamedplus" end
  if vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-copy") == 1 then return "unnamedplus" end
  if vim.env.DISPLAY and (vim.fn.executable("xclip") == 1 or vim.fn.executable("xsel") == 1) then
    return "unnamedplus"
  end
  return ""
end

-- 表示
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.laststatus = 3 -- グローバルステータスライン(lualine と相性が良い)
opt.cmdheight = 1
opt.showmode = false
opt.ruler = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.linebreak = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣", extends = "›", precedes = "‹" }
opt.fillchars = { eob = " ", fold = " ", vert = "│", msgsep = "‾" }
opt.pumheight = 14
opt.smoothscroll = true

-- 編集
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.shiftround = true
opt.smartindent = true
opt.autoindent = true
opt.undofile = true
opt.undolevels = 10000
opt.backup = false
opt.swapfile = false
opt.mouse = "a"
opt.clipboard = clipboard_provider()
opt.splitright = true
opt.splitbelow = true
opt.equalalways = false

-- 検索
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true
opt.wrapscan = true

-- 挙動
opt.updatetime = 250
opt.timeoutlen = 400
opt.confirm = true
opt.wildmode = "longest:full,full"
opt.completeopt = { "menu", "menuone", "noselect" }
opt.jumpoptions = "view"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

-- ファイルタイプごとのインデント幅
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user_indent", { clear = true }),
  pattern = { "lua", "javascript", "javascriptreact", "typescript", "typescriptreact",
    "json", "jsonc", "yaml", "html", "css", "scss", "vue", "svelte", "markdown" },
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
  end,
})

-- 折り返しを有効にしたいファイルタイプ
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user_wrap", { clear = true }),
  pattern = { "markdown", "text", "gitcommit", "help", "tex" },
  callback = function()
    vim.wo.wrap = true
    vim.wo.spell = true
    vim.wo.linebreak = true
  end,
})
