# Neovim 設定

Neovim 0.12 / lazy.nvim ベースの設定。
leader キーは **Space**。

## 構成

```
~/.config/nvim/
├── init.lua                 # エントリポイント
└── lua/
    ├── config/
    │   ├── options.lua      # オプション(表示・編集・検索など)
    │   ├── keymaps.lua      # 基本キーマップ
    │   ├── autocmds.lua     # 自動処理(IMEオフ・全角スペース可視化など)
    │   ├── cheatsheet.lua   # :Cheat / <leader>? キーマップ一覧
    │   └── lazy.lua         # lazy.nvim のブートストラップ
    └── plugins/
        ├── colorscheme.lua  # catppuccin macchiato
        ├── ui.lua           # lualine / bufferline / which-key / nvim-tree / trouble / alpha / ibl
        ├── telescope.lua    # ファイル・文字列検索
        ├── lsp.lua          # mason / LSP / 補完 / conform / autopairs
        ├── git.lua          # gitsigns
        └── editor.lua       # treesitter / surround / toggleterm / undotree / markdown-preview
```

## 使い方

`<leader>?` または `:Cheat` で、実際に有効なキーマップの一覧をフローティング表示します。
`<leader>` を押しただけでも which-key が候補を出します。

### よく使うキー

| キー | 動作 |
| --- | --- |
| `<leader>ff` | ファイルを探す |
| `<leader>fg` | 文字列を検索 (grep) |
| `<leader>fw` | カーソル下の単語を検索 |
| `<leader>fb` | バッファ一覧 |
| `<leader>fr` | 最近開いたファイル |
| `<leader>f/` | 現在のバッファ内を絞り込み |
| `<leader>e` | ファイルツリー開閉 |
| `<leader>xx` | 診断(LSP エラー)一覧 |
| `<leader>tt` | フローティングターミナル |
| `<leader>w` / `<C-s>` | 保存 |
| `<leader>q` | ウィンドウを閉じる |
| `<S-h>` / `<S-l>` | 前 / 次のバッファ |
| `<C-h/j/k/l>` | ウィンドウ移動 |
| `<A-j>` / `<A-k>` | 行を上下に移動 |
| `<leader>?` | キーマップ一覧 |

### LSP (ファイルを開くと自動で起動)

| キー | 動作 |
| --- | --- |
| `gd` / `gD` | 定義 / 宣言へジャンプ |
| `gr` / `gi` | 参照 / 実装へジャンプ |
| `K` | ホバー情報 |
| `<C-k>` | シグネチャヘルプ |
| `<leader>rn` | 名前を変更 |
| `<leader>ca` | コードアクション |
| `<leader>cf` | フォーマット |
| `<leader>cR` | 参照一覧 |
| `[d` / `]d` | 前 / 次の診断 |
| `<leader>cd` | カーソル行の診断を表示 |
| `<leader>th` | インレイヒント切替 |
| `<leader>cm` | Mason (LSP・ツール管理画面) |

### git

| キー | 動作 |
| --- | --- |
| `]h` / `[h` | 前 / 次の変更 |
| `<leader>gp` | 変更をプレビュー |
| `<leader>gs` / `<leader>gr` | ステージ / 取り消し |
| `<leader>gb` | この行の blame |
| `<leader>gB` | 行ごとの blame 切替 |
| `<leader>gd` | このバッファの差分 |
| `<leader>fx` | git の変更ファイル一覧 |

### 設定編集

| キー | 動作 |
| --- | --- |
| `<leader>vc` | init.lua を開く |
| `<leader>vr` | 設定を再読み込み |
| `:Lazy` | プラグイン管理画面 |

## 依存している外部ツール

| ツール | 用途 | 状態 |
| --- | --- | --- |
| `git` | lazy.nvim | インストール済み |
| `rg` (ripgrep) | Telescope の grep | インストール済み |
| `make` + `gcc` | telescope-fzf-native, treesitter | インストール済み |
| `tree-sitter` CLI | treesitter パーサのビルド | `pnpm add -g --allow-build=tree-sitter-cli tree-sitter-cli` で導入済み |
| `fcitx5-remote` | Insert を抜けたら IME を自動オフ | インストール済み |
| `wl-copy` (wl-clipboard) | システムクリップボード連携 | **未インストール** |

### クリップボードを使うには

Wayland 環境では `wl-clipboard` が必要です。

```sh
sudo pacman -S wl-clipboard
```

インストール後は自動で `clipboard=unnamedplus` が有効になります
(`options.lua` の `clipboard_provider()` が検出します)。

## LSP・フォーマッタ

LSP サーバとフォーマッタは Mason が管理します。
初回起動時に以下をバックグラウンドで自動インストールします。

- LSP: `lua-language-server`, `pyright`, `typescript-language-server`
- フォーマッタ: `stylua`, `shfmt`, `prettierd`, `ruff`

`clangd` はシステムのもの (`/usr/bin/clangd`) をそのまま使います。
追加したいときは `:Mason` からインストールし、`lua/plugins/lsp.lua` の `servers`
テーブルに名前と実行ファイル名を追記してください。

## メモ

- 保存時フォーマットは `lua` / `c` / `cpp` と 2000 行超のファイルでは行いません。
  手動は `<leader>cf`。
- 全角スペースは背景色でハイライトされます。
- `iminsert=0` / `imsearch=-1` 固定。Insert を抜けると fcitx5 の IME を自動でオフにします。
- アンドゥ履歴は `~/.local/state/nvim/undo/` に保存されます。
- プラグインのバージョンは `lazy-lock.json` で固定されています。
  更新は `:Lazy update`。
