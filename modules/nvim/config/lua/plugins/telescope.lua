return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "ファイルを探す" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "文字列を検索 (grep)" },
      { "<leader>fw", "<cmd>Telescope grep_string<cr>", desc = "カーソル下の単語を検索" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "バッファ一覧" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "最近開いたファイル" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "ヘルプを検索" },
      { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "キーマップを検索" },
      { "<leader>fc", "<cmd>Telescope commands<cr>", desc = "コマンドを検索" },
      { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "診断一覧" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "バッファ内シンボル" },
      { "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "ワークスペースシンボル" },
      { "<leader>f/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "バッファ内を絞り込み" },
      { "<leader>fx", "<cmd>Telescope git_status<cr>", desc = "git 変更ファイル" },
      { "<leader>fm", "<cmd>Telescope git_commits<cr>", desc = "git コミット履歴" },
      { "<leader>fp", "<cmd>Telescope projects<cr>", desc = "プロジェクト一覧" },
      { "<leader>f.", "<cmd>Telescope resume<cr>", desc = "前回の検索を再開" },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          prompt_prefix = " ",
          selection_caret = " ",
          path_display = { "smart" },
          sorting_strategy = "ascending",
          layout_strategy = "horizontal",
          layout_config = { prompt_position = "top", width = 0.9, height = 0.85 },
          file_ignore_patterns = { "%.git/", "node_modules/", "Library/", "Temp/", "%.meta" },
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
              ["<Esc>"] = actions.close,
            },
            n = {
              ["q"] = actions.close,
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
            },
          },
        },
        pickers = {
          find_files = { hidden = true },
          buffers = { sort_lastused = true, mappings = { i = { ["<C-d>"] = actions.delete_buffer } } },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })

      pcall(telescope.load_extension, "fzf")
      pcall(require("telescope").load_extension, "projects")
    end,
  },
}
