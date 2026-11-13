local uname = vim.uv.os_uname().sysname
if uname == "Windows_NT" then
    -- Sets terminal shell to powershell
    local powershell_options = {
      shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell",
      shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;",
      shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait",
      shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode",
      shellquote = "",
      shellxquote = "",
    }

    for option, value in pairs(powershell_options) do
      vim.opt[option] = value
    end
end

vim.loader.enable()
function map(mode, shortcut, command)
  vim.api.nvim_set_keymap(mode, shortcut, command, { noremap = true, silent = true })
end

function nmap(shortcut, command)
  map('n', shortcut, command)
end

function tmap(shortcut, command)
  map('t', shortcut, command)
end

function vmap(shortcut, command)
  map('v', shortcut, command)
end

function cmap(shortcut, command)
  map('c', shortcut, command)
end

tmap('<ESC>', '<C-\\><C-N>')
nmap('<C-Left>', ':bp<CR>')
nmap('<C-Right>', ':bn<CR>')
nmap('<A-h>', '<C-w>h')
nmap('<A-j>', '<C-w>j')
nmap('<A-k>', '<C-w>k')
nmap('<A-l>', '<C-w>l')
tmap('<A-h>', '<C-w>h')
tmap('<A-j>', '<C-w>j')
tmap('<A-k>', '<C-w>k')
tmap('<A-l>', '<C-w>l')
vmap('<A-h>', '<C-w>h')
vmap('<A-j>', '<C-w>j')
vmap('<A-k>', '<C-w>k')
vmap('<A-l>', '<C-w>l')
nmap('<C-Up>'  , '<C-w>+')
nmap('<C-Down>', '<C-w>-')
nmap('<Tab>', '>>')
nmap('<S-Tab>', '<<')
vmap('<Tab>', '>gv')
vmap('<S-Tab>', '<gv')
nmap('<C-Enter>', 'a<Enter><ESC>')
nmap('<S-Enter>', 'i<Enter><ESC>')
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.opt.tabstop     = 4
vim.opt.shiftwidth  = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.smartindent = true
vim.opt.guicursor='n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175'
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.swapfile = false
vim.g.zig_fmt_autosave = 0
vim.opt.foldmethod = 'marker'
-- Start
-- vim.wo.foldmethod= "expr"
-- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
-- vim.opt.foldtext = ""
-- vim.opt.foldcolumn = "0"
vim.api.nvim_create_user_command('Light', 
        function() vim.opt.background='light' end,
        {})
vim.api.nvim_create_user_command('Dark', 
        function() vim.opt.background='dark' end,
        {})
vim.api.nvim_create_user_command(
    'Terminal',
    function()
        vim.cmd('tabnew')
        vim.cmd('terminal')
    end, 
    {}
)
vim.api.nvim_create_user_command('Wd', 
        'w <CR> :bd',
        {desc="Write and close buffer"})
vim.api.nvim_create_user_command(
    'Prettier',
    function()
        vim.cmd('!prettier --write .')
    end, 
    {}
)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
    -- {{{
        'Shatur/neovim-ayu',
        {
            'folke/snacks.nvim',
        },
        'neovim/nvim-lspconfig',
        {
            'nvim-treesitter/nvim-treesitter',
            lazy = false,
            build = ":TSUpdate"
        },
        -- 'mrcjkb/rustaceanvim',
        {
            'nvim-telescope/telescope.nvim', version = '*',
            dependencies = {
                'nvim-lua/plenary.nvim',
                -- optional but recommended
                { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
            }
        },
        {
            'nvim-mini/mini.diff',
            event = "VeryLazy"
        },
        -- {
        --     "mason-org/mason.nvim",
        --     opts = {}
        -- },
        'nyoom-engineering/oxocarbon.nvim',
        "rebelot/kanagawa.nvim",
        {
            'nvim-lualine/lualine.nvim',
            dependencies = { 'nvim-tree/nvim-web-devicons' }
        },
        -- {
        --     'VonHeikemen/fine-cmdline.nvim',
        --     dependencies = {
        --         'MunifTanjim/nui.nvim'
        --     }
        -- },
        'morhetz/gruvbox',
        'sainnhe/everforest',
        { 'ccxnu/rosebones', 
            name = 'rosebones',
            lazy = false,
        },
        { "rose-pine/neovim", name = "rose-pine" },
        { "EdenEast/nightfox.nvim" },
        { "miikanissi/modus-themes.nvim", priority = 1000 },
        
        {
            "nvim-neo-tree/neo-tree.nvim",
            branch = "v3.x",
            dependencies = {
              "nvim-lua/plenary.nvim",
              "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
              "MunifTanjim/nui.nvim",
              -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
            }
        },
        {
          "xero/miasma.nvim",
          lazy = false,
          priority = 1000
          -- config = function()
          --   vim.cmd("colorscheme miasma")
          -- end,
        },
        
        {
            'nvimdev/dashboard-nvim',
             event = 'VimEnter',
             config = function()
             require('dashboard').setup{
                 -- config
             }
             end,
             dependencies = { {'nvim-tree/nvim-web-devicons'}}
        },
        {
          'ribru17/bamboo.nvim',
          lazy = false,
          priority = 1000,
          config = function()
            require('bamboo').setup {
              -- optional configuration here
            }
            require('bamboo').load()
          end,
        },

    	{
    	    'windwp/nvim-autopairs',
    	    event = "InsertEnter",
    	    config = true,
            opts = {
                disable_filetype = {"lisp"}
            }
    	    -- use opts = {} for passing setup options
    	    -- this is equivalent to setup({}) function
    	},
	{
	  "folke/which-key.nvim",
	  event = "VeryLazy",
	  opts = {
	    -- your configuration comes here
	    -- or leave it empty to use the default settings
	    -- refer to the configuration section below
	  },
	  keys = {
	    {
	      "<leader>?",
	      function()
		require("which-key").show({ global = false })
	      end,
	      desc = "Buffer Local Keymaps (which-key)",
	    },
	  },
	},
    {
      'stevearc/overseer.nvim',
      ---@module 'overseer'
      ---@type overseer.SetupOpts
      opts = {},
    },
    {'akinsho/toggleterm.nvim', version = "*", config = true},
    {
        "wstucco/c3.nvim",
        config = function()
            require("c3")
        end,
    },
    {
        'pineapplegiant/spaceduck'
    },
    {
      'maxmx03/solarized.nvim',
      lazy = false,
      priority = 1000,
      ---@type solarized.config
      opts = {},
      config = function(_, opts)
        vim.o.termguicolors = true
        vim.o.background = 'light'
        require('solarized').setup(opts)
        vim.cmd.colorscheme 'solarized'
      end,
    },
    {
        's1n7ax/nvim-window-picker',
        name = 'window-picker',
        event = 'VeryLazy',
        version = '2.*',
        config = function()
            require'window-picker'.setup()
        end,
    },
    -- 'andweeb/presence.nvim',
    -- }}}
})

-- vim.g.rustaceanvim = {
--   server = {
--     on_attach = function(client, bufnr)
--       -- You can put your keymaps here (e.g., go to definition)
--     end,
--     default_settings = {
--       ['rust-analyzer'] = {
--         checkOnSave = true, -- Use clippy for better warnings
--       },
--     },
--   },
-- }
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  update_in_insert = false, -- Only show errors when you stop typing/save
  underline = true,
})

vim.lsp.enable('ols')
vim.lsp.enable('c3lsp')
vim.lsp.config('ols', {
-- {{{
    settings = {
        ols = {
            init_options = {
                checker_args = '-strict-style',
            },
        }
    }
-- }}}
})
vim.lsp.enable('zls')
vim.lsp.enable('clangd')

require('telescope').setup({
    pickers = {
        colorscheme = {
            enable_preview = true
        }
    },
    defaults = {
        mappings = {
            n = {
                ['<c-s>'] = require('telescope.actions').delete_buffer,
            },
            i = {
                ['<c-s>'] = require('telescope.actions').delete_buffer,
            },
        }
    }
})

vim.keymap.set("n", "<leader>b", function()
  require("telescope.builtin").buffers({
    sort_mru = true,      -- Sort by most recently used
    -- ignore_current_buffer = true,
    show_all_buffers = false,
    initial_mode = "normal"
  })
end, {desc = "Telescope buffers"})

vim.keymap.set("n", "<leader>c", function()
    require("telescope.builtin").colorscheme({
        enable_preview= true,
        ignore_builtins=true,
    })
    end, {desc = "Telescope colorschemes"}
)

vim.keymap.set("n", "<leader>q", "<ESC>:q<CR>", {desc = "Close current window"})
vim.keymap.set("n", "<leader>t", 
    function() 
        if vim.o.background == 'dark' then
            vim.opt.background='light'
        elseif vim.o.background == 'light' then
            vim.opt.background='dark'
        end
    end,
    {desc="Toggle background"}
)

require('nvim-treesitter').install({'odin', 'rust', 'c3', 'toml'})
require('nvim-treesitter').setup({
    highlight = {
        enable = true,
    }
})
require('mini.diff').setup({
-- {{{
-- No need to copy this inside `setup()`. Will be used automatically.
  -- Options for how hunks are visualized
  view = {
    -- Visualization style. Possible values are 'sign' and 'number'.
    -- Default: 'number' if line numbers are enabled, 'sign' otherwise.
    style = vim.go.number and 'number' or 'sign',

    -- Signs used for hunks with 'sign' view
    signs = { add = '▒', change = '▒', delete = '▒' },

    -- Priority of used visualization extmarks
    priority = 199,
  },

  -- Source(s) for how reference text is computed/updated/etc
  -- Uses content from Git index by default
  source = nil,

  -- Delays (in ms) defining asynchronous processes
  delay = {
    -- How much to wait before update following every text change
    text_change = 200,
  },

  -- Module mappings. Use `''` (empty string) to disable one.
  mappings = {
    -- Apply hunks inside a visual/operator region
    apply = 'gh',

    -- Reset hunks inside a visual/operator region
    reset = 'gH',

    -- Hunk range textobject to be used inside operator
    -- Works also in Visual mode if mapping differs from apply and reset
    textobject = 'gh',

    -- Go to hunk range in corresponding direction
    goto_first = '[H',
    goto_prev = '[h',
    goto_next = ']h',
    goto_last = ']H',
  },

  -- Various options
  options = {
    -- Diff algorithm. See `:h vim.diff()`.
    algorithm = 'histogram',

    -- Whether to use "indent heuristic". See `:h vim.diff()`.
    indent_heuristic = true,

    -- The amount of second-stage diff to align lines
    linematch = 60,

    -- Whether to wrap around edges during hunk navigation
    wrap_goto = false,
  },
-- }}}
})

require('lualine').setup({
-- {{{
    options = {
        icons_enabled = true,
        theme = 'auto',
        component_separators = { left = '', right = ''},
        section_separators = { left = '', right = ''},
        disabled_filetypes = {
          statusline = {},
          winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = false,
        refresh = {
          statusline = 33,
          tabline = 33,
          winbar = 33,
        }
      },
      sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {
            {
                'filename',
                file_status = true,
                newfile_status = false,
                path = 4
            }
        },
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {
            {
                'filename',
                file_status = true,
                newfile_status = false,
                path = 4
            }
        },
        lualine_x = {'location'},
        lualine_y = {},
        lualine_z = {}
      },
      tabline = {},
      winbar = {},
      inactive_winbar = {},
      extensions = {}
-- }}}
  })
-- vim.api.nvim_set_keymap('n', '<CR>', '<cmd>FineCmdline<CR>', {noremap = true})
-- vim.api.nvim_set_keymap('n', ':', '<cmd>FineCmdline<CR>', {noremap = true})
require("rosebones").setup({
-- {{{
  style = "default",
    -- Enable this to disable setting the background color (Recommended)
  transparent = true, 
    -- Configure the colors used when opening a `:terminal` in Neovim
  terminal_colors = false, 
  styles = {
    -- Style to be applied to different syntax groups
    -- Value is any valid attr-list value for `:help nvim_set_hl`
    comments = { italic = true },
    keywords = { italic = true },
    functions = {},
    variables = {},
  },

    -- Enabling this option, will hide inactive statuslines and replace them 
    -- with a thin border instead. 
    -- Should work with the standard **StatusLine** and **LuaLine**.
  hide_inactive_statusline = false, 
  dim_inactive = false, -- dims inactive windows
  lualine_bold = false, -- When `true`, section headers in the lualine theme will be bold

  --- You can override specific color groups to use other groups or a hex color
  --- function will be called with a ColorScheme table
  ---@param colors ColorScheme
  on_colors = function(colors) end,

  --- You can override specific highlights to use other groups or a hex color
  --- function will be called with a Highlights and ColorScheme table
  ---@param highlights Highlights
  ---@param colors ColorScheme
  on_highlights = function(highlights, colors) end,
    -- can be light/dark/auto. When auto, background will be set to vim.o.background
  use_background = true, 
-- }}}
})

require("overseer").setup()

-- require("presence").setup({
--     -- General options
--     auto_update         = true,                       -- Update activity based on autocmd events (if `false`, map or manually execute `:lua package.loaded.presence:update()`)
--     neovim_image_text   = "The One True Text Editor", -- Text displayed when hovered over the Neovim image
--     main_image          = "neovim",                   -- Main image display (either "neovim" or "file")
--     client_id           = "793271441293967371",       -- Use your own Discord application client id (not recommended)
--     log_level           = nil,                        -- Log messages at or above this level (one of the following: "debug", "info", "warn", "error")
--     debounce_timeout    = 10,                         -- Number of seconds to debounce events (or calls to `:lua package.loaded.presence:update(<filename>, true)`)
--     enable_line_number  = false,                      -- Displays the current line number instead of the current project
--     blacklist           = {},                         -- A list of strings or Lua patterns that disable Rich Presence if the current file name, path, or workspace matches
--     buttons             = true,                       -- Configure Rich Presence button(s), either a boolean to enable/disable, a static table (`{{ label = "<label>", url = "<url>" }, ...}`, or a function(buffer: string, repo_url: string|nil): table)
--     file_assets         = {},                         -- Custom file asset definitions keyed by file names and extensions (see default config at `lua/presence/file_assets.lua` for reference)
--     show_time           = true,                       -- Show the timer
--
--     -- Rich Presence text options
--     editing_text        = "Editing %s",               -- Format string rendered when an editable file is loaded in the buffer (either string or function(filename: string): string)
--     file_explorer_text  = "Browsing %s",              -- Format string rendered when browsing a file explorer (either string or function(file_explorer_name: string): string)
--     git_commit_text     = "Committing changes",       -- Format string rendered when committing changes in git (either string or function(filename: string): string)
--     plugin_manager_text = "Managing plugins",         -- Format string rendered when managing plugins (either string or function(plugin_manager_name: string): string)
--     reading_text        = "Reading %s",               -- Format string rendered when a read-only or unmodifiable file is loaded in the buffer (either string or function(filename: string): string)
--     workspace_text      = "Working on %s",            -- Format string rendered when in a git repository (either string or function(project_name: string|nil, filename: string): string)
--     line_number_text    = "Line %s out of %s",        -- Format string rendered when `enable_line_number` is set to true (either string or function(line_number: number, line_count: number): string)
-- })

-- vim.keymap.set('n', '-', function()
--     local reveal_file = vim.fn.expand('%:p')
--     if (reveal_file == '') then
--       reveal_file = vim.fn.getcwd()
--     else
--       local f = io.open(reveal_file, "r")
--       if (f) then
--         f.close(f)
--       else
--         reveal_file = vim.fn.getcwd()
--       end
--     end
--     require('neo-tree.command').execute({
--       action = "focus",          -- OPTIONAL, this is the default value
--       source = "filesystem",     -- OPTIONAL, this is the default value
--       position = "left",         -- OPTIONAL, this is the default value
--       reveal_file = reveal_file, -- path to file or folder to reveal
--       reveal_force_cwd = true,   -- change cwd without asking if needed
--     })
--     end,
--     { desc = "Open neo-tree at current file or working directory" }
-- );
nmap('<F9>', ':OverseerRun<CR>')
nmap('<F10>', ':OverseerToggle<CR>')
nmap('<F12>', ':ToggleTerm<CR>')
tmap('<F12>', '<C-\\><C-N>:ToggleTerm<CR>')
vim.cmd("colorscheme rose-pine")
-- vim.api.nvim_create_autocmd(
--     "VimEnter",
--     {
--         callback=function()
--             vim.cmd("Terminal")
--             vim.cmd("tabnext")
--         end,
--     }
-- )
--
