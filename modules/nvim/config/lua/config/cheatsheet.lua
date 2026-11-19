-- :Cheat / <leader>? で実際に設定されているキーマップを一覧表示する
local M = {}

local mode_labels = {
  n = "ノーマル",
  i = "挿入",
  v = "ビジュアル",
  x = "ビジュアル",
  t = "ターミナル",
  c = "コマンド",
}

local function keytrans(lhs)
  local ok, out = pcall(vim.fn.keytrans, lhs)
  if ok and out ~= "" then
    return (out:gsub("<lt>", "<"))
  end
  return lhs
end

local function collect()
  local rows = {}
  local seen = {}
  local order = { "n", "v", "i", "t", "c" }
  for _, mode in ipairs(order) do
    local keys = vim.api.nvim_get_keymap(mode)
    for _, m in ipairs(keys) do
      local desc = m.desc
      -- 組み込みの「:help xx-default」的な説明は省く
      if desc and desc ~= "" and not desc:match("^:help ") and not desc:match("%-default$") then
        local lhs = keytrans(m.lhs)
        local id = mode .. "\0" .. lhs
        if not seen[id] then
          seen[id] = true
          rows[#rows + 1] = { mode = mode, lhs = lhs, desc = desc }
        end
      end
    end
  end
  table.sort(rows, function(a, b)
    if a.lhs ~= b.lhs then return a.lhs < b.lhs end
    return a.mode < b.mode
  end)
  return rows
end

function M.open()
  local rows = collect()
  local width = math.min(math.max(64, vim.o.columns - 20), 110)

  local lines = {
    "キーマップ一覧 (leader = Space)            q / Esc で閉じる",
    string.rep("─", math.max(width - 4, 20)),
  }

  local current_mode = nil
  for _, row in ipairs(rows) do
    if row.mode ~= current_mode then
      current_mode = row.mode
      lines[#lines + 1] = ""
      lines[#lines + 1] = "[" .. (mode_labels[current_mode] or current_mode) .. "]"
    end
    lines[#lines + 1] = string.format("  %-22s %s", row.lhs, row.desc)
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = string.rep("─", math.max(width - 4, 20))
  lines[#lines + 1] = "  ヒント: <leader> を押すだけでも which-key が候補を表示します"

  local height = math.min(#lines, vim.o.lines - 6)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "help"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " 使い方 (Cheat Sheet) ",
    title_pos = "center",
  })

  vim.wo[win].wrap = false
  vim.wo[win].cursorline = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"

  for _, lhs in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", lhs, "<cmd>close<cr>", { buffer = buf, desc = "閉じる" })
  end
end

vim.api.nvim_create_user_command("Cheat", M.open, { desc = "キーマップ一覧を表示" })

return M
