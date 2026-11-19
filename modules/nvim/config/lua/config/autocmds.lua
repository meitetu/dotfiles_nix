local augroup = vim.api.nvim_create_augroup("user_autocmds", { clear = true })

-- ヤンク時にハイライト
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    if vim.hl and vim.hl.on_yank then
      vim.hl.on_yank({ higroup = "IncSearch", timeout = 150 })
    else
      vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
    end
  end,
})

-- 前回のカーソル位置を復元
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- 全角スペースを可視化
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "ColorScheme" }, {
  group = augroup,
  callback = function()
    vim.api.nvim_set_hl(0, "ZenSpace", { bg = "#4b3a56", default = true })
    pcall(vim.fn.matchadd, "ZenSpace", "　", 10, -1)
  end,
})

-- IME(fcitx5)を Insert モードを抜けたら自動でオフにする
if vim.fn.executable("fcitx5-remote") == 1 then
  vim.api.nvim_create_autocmd({ "InsertLeave", "CmdlineLeave" }, {
    group = augroup,
    callback = function()
      vim.system({ "fcitx5-remote", "-c" }, { detach = true })
    end,
  })
end

-- iminsert 系は常にオフ(挿入モードの一時的な言語切替を使わない)
vim.opt.iminsert = 0
vim.opt.imsearch = -1

-- 分割ウィンドウを画面サイズに合わせる
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup,
  command = "tabdo wincmd =",
})

-- 末尾の空行を残してスクロールしやすくする
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "qf", "help", "man", "lspinfo", "checkhealth", "lazy", "mason", "notify" },
  callback = function(event)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, desc = "閉じる" })
  end,
})

-- ファイル保存時に親ディレクトリがなければ作る
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  callback = function(event)
    if event.match:match("^%w%w+://") then return end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- ターミナルバッファで行番号を消す
vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup,
  callback = function()
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = "no"
  end,
})
