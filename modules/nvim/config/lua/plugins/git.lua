return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signs_staged = { add = { text = "▎" }, change = { text = "▎" }, delete = { text = "" } },
      current_line_blame = false,
      preview_config = { border = "rounded" },
      attach_to_untracked = true,
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        map("n", "]h", function() gs.nav_hunk("next") end, "次の変更へ")
        map("n", "[h", function() gs.nav_hunk("prev") end, "前の変更へ")
        map("n", "<leader>gs", gs.stage_hunk, "変更をステージ")
        map("n", "<leader>gr", gs.reset_hunk, "変更を元に戻す")
        map("n", "<leader>gp", gs.preview_hunk, "変更をプレビュー")
        map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "この行の blame")
        map("n", "<leader>gB", gs.toggle_current_line_blame, "行ごとの blame 切替")
        map("n", "<leader>gd", gs.diffthis, "このファイルの差分")
        map("n", "<leader>gD", function() gs.diffthis("~") end, "前回コミットとの差分")
        map("n", "<leader>gu", gs.undo_stage_hunk, "ステージを取り消す")
        map("n", "<leader>gS", gs.stage_buffer, "バッファ全体をステージ")
        map("n", "<leader>gR", gs.reset_buffer, "バッファ全体を戻す")
      end,
    },
    keys = {
      { "<leader>gt", "<cmd>Gitsigns toggle_signs<cr>", desc = "git サイン表示切替" },
    },
  },
}
