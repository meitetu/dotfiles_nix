return {
  -- LSP サーバのインストール管理
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    keys = {
      { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason (LSP 管理)" },
    },
    opts = {
      ui = { border = "rounded", icons = { package_installed = "", package_pending = "→", package_uninstalled = "" } },
    },
    config = function(_, opts)
      require("mason").setup(opts)

      -- 初回起動時に必要なサーバをバックグラウンドで入れる
      local ensure_installed = {
        -- LSP
        "lua-language-server", "pyright", "typescript-language-server",
        -- フォーマッタ (conform.nvim が使う)
        "stylua", "shfmt", "prettierd", "ruff",
      }
      vim.schedule(function()
        local ok, registry = pcall(require, "mason-registry")
        if not ok then return end
        registry.refresh(function()
          for _, name in ipairs(ensure_installed) do
            local ok_pkg, pkg = pcall(registry.get_package, name)
            if ok_pkg and not pkg:is_installed() then
              pkg:install():on("exit", function()
                vim.notify(("mason: %s をインストールしました"):format(name), vim.log.levels.INFO)
              end)
            end
          end
        end)
      end)
    end,
  },

  -- LSP 本体(nvim 0.11+ の vim.lsp.config / vim.lsp.enable を使う)
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      -- mason で入れた実行ファイルを PATH に追加
      local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
      vim.env.PATH = mason_bin .. ":" .. vim.env.PATH

      -- サーバごとの設定。exe が見つからないものは有効化しない
      local servers = {
        lua_ls = {
          exe = "lua-language-server",
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              diagnostics = { globals = { "vim" } },
              workspace = { checkThirdParty = false, library = vim.api.nvim_get_runtime_file("", true) },
              telemetry = { enable = false },
              hint = { enable = true },
            },
          },
        },
        pyright = { exe = "pyright-langserver" },
        ts_ls = { exe = "typescript-language-server" },
        clangd = { exe = "clangd" },
        gopls = { exe = "gopls" },
        rust_analyzer = { exe = "rust-analyzer" },
        csharp_ls = { exe = "csharp-ls" },
        bashls = { exe = "bash-language-server" },
        jsonls = { exe = "vscode-json-language-server" },
        yamlls = { exe = "yaml-language-server" },
        html = { exe = "vscode-html-language-server" },
        cssls = { exe = "vscode-css-language-server" },
        taplo = { exe = "taplo" },
        marksman = { exe = "marksman" },
      }

      for name, cfg in pairs(servers) do
        if vim.fn.executable(cfg.exe) == 1 then
          local server = vim.deepcopy(cfg)
          server.exe = nil
          pcall(vim.lsp.config, name, server)
          pcall(vim.lsp.enable, name)
        end
      end

      -- 全体の診断表示設定
      vim.diagnostic.config({
        virtual_text = { spacing = 2, prefix = "●", source = "if_many" },
        signs = { text = { [vim.diagnostic.severity.ERROR] = "", [vim.diagnostic.severity.WARN] = "", [vim.diagnostic.severity.INFO] = "", [vim.diagnostic.severity.HINT] = "" } },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = { border = "rounded", source = true, header = "" },
      })

      -- 補完・エラー表示をすっきりさせる
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = function(event)
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = desc })
          end

          map("n", "<leader>rn", vim.lsp.buf.rename, "名前を変更 (rename)")
          map("n", "<leader>ca", vim.lsp.buf.code_action, "コードアクション")
          map("n", "<leader>cR", vim.lsp.buf.references, "参照を一覧")
          map("n", "gd", vim.lsp.buf.definition, "定義へジャンプ")
          map("n", "gD", vim.lsp.buf.declaration, "宣言へジャンプ")
          map("n", "gr", vim.lsp.buf.references, "参照へジャンプ")
          map("n", "gi", vim.lsp.buf.implementation, "実装へジャンプ")
          map("n", "K", vim.lsp.buf.hover, "ホバー情報")
          map("n", "<C-k>", vim.lsp.buf.signature_help, "シグネチャヘルプ")
          map("n", "<leader>cl", "<cmd>LspInfo<cr>", "LSP 情報")
          map("n", "<leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }), { bufnr = event.buf })
          end, "インレイヒント切替")
        end,
      })

      -- ルートマーカー: プロジェクトルートを自動判定
      vim.lsp.config("*", {
        root_markers = { ".git", "package.json", "pyproject.toml", "Cargo.toml", "go.mod", "Makefile", "*.sln", "*.csproj" },
      })
    end,
  },

  -- 補完
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "luasnip", priority = 750 },
          { name = "buffer", priority = 500 },
          { name = "path", priority = 250 },
        }),
        formatting = {
          format = function(entry, item)
            local icons = { nvim_lsp = "", luasnip = "", buffer = "", path = "" }
            item.menu = icons[entry.source.name] or ""
            return item
          end,
        },
      })

      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = "buffer" } },
      })
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
      })
    end,
  },

  -- 保存時フォーマット
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      { "<leader>cf", function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end, desc = "フォーマット" },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        jsonc = { "prettierd", "prettier", stop_after_first = true },
        css = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
        sh = { "shfmt" },
        go = { "goimports", "gofmt" },
        rust = { "rustfmt" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        cs = { "csharpier" },
      },
      format_on_save = function(bufnr)
        -- 大きいファイルや特定のファイルタイプでは自動整形しない
        local ft = vim.bo[bufnr].filetype
        if vim.tbl_contains({ "c", "cpp", "lua" }, ft) then return nil end
        if vim.api.nvim_buf_line_count(bufnr) > 2000 then return nil end
        return { timeout_ms = 1000, lsp_format = "fallback" }
      end,
    },
  },

  -- 括弧を自動で閉じる
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = { check_ts = true },
  },
}
