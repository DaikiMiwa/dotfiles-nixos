return {
  {
    "ibhagwan/fzf-lua",
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
    -- or if using mini.icons/mini.nvim
    -- dependencies = { "nvim-mini/mini.icons" },
    ---@module "fzf-lua"
    ---@type fzf-lua.Config|{}
    ---@diagnostics disable: missing-fields
    opts = {
      files = {
        actions = {
          ["ctrl-o"] = function(selected)
            local oil = require("oil")

            -- ▼ ここが修正ポイント ▼
            -- selected[1] は "  path/to/file" のようになっているので、
            -- fzf-lua の機能を使ってパス部分だけを抽出します。
            local entry = require("fzf-lua").path.entry_to_file(selected[1])
            local clean_path = entry.path

            if clean_path then
              -- ファイルのパスから親ディレクトリ(:h)を取得
              local dir = vim.fn.fnamemodify(clean_path, ":h")
              oil.open(dir)
            end
          end,
        },
      },
    },
    ---@diagnostics enable: missing-fields
    keys = {
      -- 【基本: ファイル・検索】
      {
        "<leader>ff",
        function()
          require("fzf-lua").files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>fg",
        function()
          require("fzf-lua").live_grep()
        end,
        desc = "Live Grep",
      },
      {
        "<leader>fb",
        function()
          require("fzf-lua").buffers()
        end,
        desc = "Find Buffers",
      },
      {
        "<leader>fh",
        function()
          require("fzf-lua").help_tags()
        end,
        desc = "Find Help",
      },
      {
        "<leader>fo",
        function()
          require("fzf-lua").oldfiles()
        end,
        desc = "Find Old Files",
      },
      {
        "<leader>fr",
        function()
          require("fzf-lua").resume()
        end,
        desc = "Fzf Resume",
      },
      {
        "<leader>fd",
        function()
          local fzf = require("fzf-lua")
          -- oilは遅延ロードされている可能性があるのでここでrequireしてもOK
          local oil = require("oil")

          -- fdコマンドでディレクトリのみを検索
          -- (fdがない場合は find . -type d ... などに書き換えてください)
          local cmd = "fd --type d --hidden --follow --exclude .git"

          fzf.fzf_exec(cmd, {
            prompt = "Oil Dirs> ",
            previewer = false, -- ディレクトリ一覧なのでプレビューはオフでも良いかも
            actions = {
              ["default"] = function(selected)
                if selected and selected[1] then
                  -- 選択されたパスをOilで開く
                  oil.open(selected[1])
                end
              end,
            },
          })
        end,
        desc = "Fzf to Oil (Directories)",
      },

      -- 【Git系】
      {
        "<leader>gs",
        function()
          require("fzf-lua").git_status()
        end,
        desc = "Git Status",
      },
      {
        "<leader>gc",
        function()
          require("fzf-lua").git_commits()
        end,
        desc = "Git Commits",
      },
      {
        "<leader>gf",
        function()
          require("fzf-lua").git_files()
        end,
        desc = "Git Files",
      },

      -- Gitステータス (変更があったファイル一覧)
      -- ※ここでEnterを押すとDiffが見れます。便利です。
      {
        "<leader>gs",
        function()
          require("fzf-lua").git_status()
        end,
        desc = "Git Status",
      },

      -- コミット履歴 (プロジェクト全体)
      {
        "<leader>gc",
        function()
          require("fzf-lua").git_commits()
        end,
        desc = "Git Commits",
      },

      -- コミット履歴 (現在開いているファイルのみ)
      -- ※「この行、いつ誰が変えた？」を調べるときに重宝します
      {
        "<leader>gC",
        function()
          require("fzf-lua").git_bcommits()
        end,
        desc = "Git Buffer Commits",
      },

      -- ブランチ検索 & 切り替え
      {
        "<leader>gb",
        function()
          require("fzf-lua").git_branches()
        end,
        desc = "Git Branches",
      },

      -- スタッシュ一覧
      {
        "<leader>gS",
        function()
          require("fzf-lua").git_stash()
        end,
        desc = "Git Stash",
      },

      -- 【LSP系】(コードアクションは特によく使います)
      {
        "<leader>ca",
        function()
          require("fzf-lua").lsp_code_actions()
        end,
        desc = "Code Actions",
      },

      -- 【LSP系】(定義ジャンプなどをfzfで行いたい場合)
      -- ※ すでにLSP設定で gd などを定義している場合は競合に注意してください
      {
        "gd",
        function()
          require("fzf-lua").lsp_definitions()
        end,
        desc = "Goto Definition",
      },
      {
        "gr",
        function()
          require("fzf-lua").lsp_references()
        end,
        desc = "Goto References",
      },
    },
  },
}
