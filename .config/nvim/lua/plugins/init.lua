return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- 2. Resaltado y gestión de comentarios TODO/FIXME
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" }, -- Se carga al abrir un archivo
    config = function()
      require("todo-comments").setup({
        -- Aquí puedes añadir configuraciones personalizadas si lo deseas
      })
    end,
  },

  {
    "vyfor/cord.nvim",
    lazy = false,
    priority = 1000,

    build = ":Cord update",

    config = function()
      require("cord").setup({})
    end,
  },
  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
}

