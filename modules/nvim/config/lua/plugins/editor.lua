return {
  -- シンタックスハイライト (treesitter)
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ok, ts = pcall(require, "nvim-treesitter")
      if not ok then return end

      local parsers = {
        "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline",
        "bash", "python", "javascript", "typescript", "tsx",
        "json", "yaml", "toml", "html", "css", "regex", "c", "cpp", "c_sharp",
        "go", "rust", "diff", "gitcommit", "dockerfile",
      }

      -- 初回のみ: 足りないパーサをバックグラウンドで取得(起動をブロックしない)
      vim.schedule(function()
        local installed = ts.get_installed and ts.get_installed("parsers") or {}
        local missing = vim.tbl_filter(function(p)
          return not vim.tbl_contains(installed, p)
        end, parsers)
        if #missing > 0 then
          pcall(ts.install, missing)
        end
      end)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
        callback = function(event)
          local buf = event.buf
          if vim.bo[buf].buftype ~= "" then return end
          pcall(vim.treesitter.start, buf)
          -- インデントを treesitter に任せる
          if vim.treesitter.language.get_lang then
            local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
            if lang and pcall(vim.treesitter.language.add, lang) then
              vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
          end
        end,
      })
    end,
  },

  -- 囲み文字の追加・変更・削除
  {
    "kylechui/nvim-surround",
    event = { "BufReadPre", "BufNewFile" },
    version = "*",
    opts = {},
  },

  -- フローティングターミナル
  {
    "akinsho/toggleterm.nvim",
    cmd = { "ToggleTerm" },
    version = "*",
    keys = {
      { "<leader>tt", "<cmd>ToggleTerm direction=float<cr>", desc = "ターミナルを開閉" },
      { "<leader>th", "<cmd>ToggleTerm direction=horizontal size=12<cr>", desc = "下にターミナル" },
      { "<leader>tv", "<cmd>ToggleTerm direction=vertical size=80<cr>", desc = "右にターミナル" },
    },
    opts = {
      size = 20,
      open_mapping = false,
      shade_terminals = true,
      start_in_insert = true,
      persist_size = true,
      direction = "float",
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = { border = "rounded", winblend = 0 },
    },
  },

  -- 変更点の一覧から元に戻せる Undo ツリー
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Undo ツリー" },
    },
    config = function()
      vim.g.undotree_SetFocusWhenToggle = 1
    end,
  },

  -- マークダウンのプレビューをブラウザで開く
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    init = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 0
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "Markdown プレビュー" },
    },
  },
}
