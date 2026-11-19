return {
  -- アイコン
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- which-key: leader を押すと候補が出る
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "classic",
      win = { border = "rounded" },
    },
    keys = {
      { "<leader>?", "<cmd>Cheat<cr>", desc = "キーマップ一覧" },
    },
  },

  -- ステータスライン
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin" },
    opts = {
      options = {
        theme = "catppuccin-macchiato",
        globalstatus = true,
        section_separators = { left = "", right = "" },
        component_separators = { left = "│", right = "│" },
        disabled_filetypes = { statusline = { "lazy", "mason" } },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", { "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = " " } } },
        lualine_c = { { "filename", path = 1, symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" } } },
        lualine_x = { "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      inactive_sections = {
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "filetype" },
      },
    },
  },

  -- バッファタブ
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin" },
    opts = {
      options = {
        mode = "buffers",
        separator_style = "thin",
        diagnostics = "nvim_lsp",
        always_show_bufferline = true,
        show_buffer_close_icons = true,
        show_close_icon = false,
        offsets = {
          { filetype = "NvimTree", text = "ファイル", separator = true },
        },
      },
    },
    keys = {
      { "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "バッファをピン留め" },
      { "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", desc = "ピン以外を閉じる" },
      { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "他のバッファを閉じる" },
    },
  },

  -- インデントガイド
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = { char = "│" },
      scope = { enabled = true, show_start = false, show_end = false },
    },
  },

  -- ファイルツリー
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "ファイルツリーを開閉" },
      { "<leader>o", "<cmd>NvimTreeFocus<cr>", desc = "ファイルツリーに移動" },
    },
    opts = {
      disable_netrw = true,
      hijack_netrw = true,
      respect_buf_cwd = true,
      sync_root_with_cwd = true,
      view = { width = 34, side = "left", relativenumber = true },
      renderer = {
        root_folder_label = false,
        group_empty = true,
        highlight_git = "name",
        indent_markers = { enable = true },
        icons = { show = { file = true, folder = true, git = true } },
      },
      update_focused_file = { enable = true, update_root = false },
      git = { enable = true },
      filters = { dotfiles = false },
      actions = { open_file = { quit_on_open = false } },
    },
  },

  -- 診断・シンボル一覧
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "診断一覧を開閉" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "このバッファの診断" },
      { "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "シンボル一覧" },
      { "<leader>xl", "<cmd>Trouble lsp toggle<cr>", desc = "LSP 定義・参照一覧" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "quickfix 一覧" },
    },
  },

  -- 起動画面
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")
      dashboard.section.header.val = {
        "                                                     ",
        "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
        "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
        "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
        "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
        "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
        "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
        "                                                     ",
      }
      dashboard.section.buttons.val = {
        dashboard.button("f", " ファイルを探す", "<cmd>Telescope find_files<cr>"),
        dashboard.button("g", " 文字列を検索 (<leader>fg)", "<cmd>Telescope live_grep<cr>"),
        dashboard.button("r", " 最近開いたファイル", "<cmd>Telescope oldfiles<cr>"),
        dashboard.button("c", " 設定を開く", "<cmd>edit $MYVIMRC<cr>"),
        dashboard.button("?", " 使い方", "<cmd>Cheat<cr>"),
        dashboard.button("q", " 終了", "<cmd>quitall<cr>"),
      }
      alpha.setup(dashboard.opts)
    end,
  },
}
