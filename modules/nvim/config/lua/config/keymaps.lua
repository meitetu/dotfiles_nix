local map = vim.keymap.set

-- 保存 / 終了
map({ "n", "i", "v" }, "<C-s>", "<cmd>write<cr>", { desc = "保存" })
map({ "n", "v" }, "<leader>w", "<cmd>write<cr>", { desc = "保存" })
map("n", "<leader>W", "<cmd>write!<cr>", { desc = "強制保存" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "ウィンドウを閉じる" })
map("n", "<leader>Q", "<cmd>quitall!<cr>", { desc = "Neovim を終了" })

-- 検索ハイライトを消す
map("n", "<Esc>", "<cmd>nohlsearch<cr><Esc>", { desc = "検索ハイライト解除" })

-- ウィンドウ移動
map("n", "<C-h>", "<C-w>h", { desc = "左のウィンドウ" })
map("n", "<C-j>", "<C-w>j", { desc = "下のウィンドウ" })
map("n", "<C-k>", "<C-w>k", { desc = "上のウィンドウ" })
map("n", "<C-l>", "<C-w>l", { desc = "右のウィンドウ" })

-- ウィンドウサイズ
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "高さを広げる" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "高さを狭める" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "幅を狭める" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "幅を広げる" })

-- 行移動(ビジュアルモードでも維持)
map("n", "<A-j>", "<cmd>move +1<cr>==", { desc = "行を下へ移動" })
map("n", "<A-k>", "<cmd>move -1<cr>==", { desc = "行を上へ移動" })
map("v", "<A-j>", ":move '>+1<cr>gv=gv", { desc = "選択行を下へ移動" })
map("v", "<A-k>", ":move '<-2<cr>gv=gv", { desc = "選択行を上へ移動" })

-- インデントを維持して再選択
map("v", "<", "<gv", { desc = "インデントを減らす" })
map("v", ">", ">gv", { desc = "インデントを増やす" })

-- 貼り付けでレジスタを壊さない
map("x", "p", '"_dP', { desc = "レジスタを保って貼り付け" })

-- バッファ操作
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "次のバッファ" })
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "前のバッファ" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "バッファを閉じる" })

-- タブライン操作
map("n", "<leader><tab>n", "<cmd>tabnew<cr>", { desc = "新しいタブ" })
map("n", "<leader><tab>]}", "<cmd>tabnext<cr>", { desc = "次のタブ" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "前のタブ" })

-- 設定ファイルをすぐ開く
map("n", "<leader>vc", "<cmd>edit $MYVIMRC<cr>", { desc = "init.lua を開く" })
map("n", "<leader>vr", "<cmd>source $MYVIMRC<cr>", { desc = "設定を再読み込み" })

-- 使い方(キーマップ一覧)
map("n", "<leader>?", "<cmd>Cheat<cr>", { desc = "キーマップ一覧を表示" })

-- その他の便利系
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "カーソル行の診断を表示" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "前の診断" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "次の診断" })
