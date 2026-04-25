vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

for key, value in pairs {
  number = true,
  relativenumber = true,
  mouse = 'a',
  showmode = false,
  breakindent = true,
  undofile = true,
  ignorecase = true,
  smartcase = true,
  signcolumn = 'yes',
  updatetime = 250,
  timeoutlen = 300,
  splitright = true,
  splitbelow = true,
  termguicolors = true,
  cursorline = true,
  scrolloff = 8,
  confirm = true,
} do
  vim.o[key] = value
end

vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>')
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)
for _, key in ipairs { 'h', 'j', 'k', 'l' } do
  vim.keymap.set('n', '<C-' .. key .. '>', '<C-w><C-' .. key .. '>')
end

vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Detect Omarchy theme if available
local omarchy_theme_path = vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua")
local omarchy_colorscheme = nil
local omarchy_plugin = nil

if vim.fn.filereadable(omarchy_theme_path) == 1 then
  local ok, spec = pcall(dofile, omarchy_theme_path)
  if ok and type(spec) == "table" then
    for _, item in ipairs(spec) do
      if type(item) == "table" then
        if item.opts and item.opts.colorscheme then
          omarchy_colorscheme = item.opts.colorscheme
        elseif item[1] and item[1] ~= "LazyVim/LazyVim" then
          omarchy_plugin = item[1]
        end
      end
    end
  end
end

local gh = function(repo)
  return 'https://github.com/' .. repo
end

local plugins = {
  gh 'nvim-lua/plenary.nvim',
  gh 'nvim-telescope/telescope.nvim',
  gh 'stevearc/oil.nvim',
  gh 'nvim-treesitter/nvim-treesitter',
  gh 'stevearc/conform.nvim',
  gh 'folke/lazydev.nvim',
  { src = gh 'saghen/blink.cmp', version = vim.version.range '1' },
  gh 'lewis6991/gitsigns.nvim',
  gh 'kdheepak/lazygit.nvim',
  gh 'mason-org/mason.nvim',
  gh 'mason-org/mason-lspconfig.nvim',
  gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
  gh 'neovim/nvim-lspconfig',
}

-- Include Omarchy theme plugin if detected and not already in list
if omarchy_plugin and omarchy_plugin ~= "rebelot/kanagawa.nvim" and omarchy_plugin ~= "shaunsingh/nord.nvim" then
  table.insert(plugins, gh(omarchy_plugin))
end

-- Always include fallback themes
table.insert(plugins, gh 'rebelot/kanagawa.nvim')
table.insert(plugins, gh 'shaunsingh/nord.nvim')

vim.pack.add(plugins, { confirm = false })

-- Apply Omarchy colorscheme or fallback to nord
vim.cmd.colorscheme(omarchy_colorscheme or "nord")

local builtin = require 'telescope.builtin'

vim.keymap.set('n', '<leader>sf', builtin.find_files)
vim.keymap.set('n', '<leader>sg', builtin.live_grep)
vim.keymap.set('n', '<leader>sr', builtin.resume)
vim.keymap.set('n', '<leader><leader>', builtin.buffers)
vim.keymap.set('n', '<leader>lg', '<cmd>LazyGit<CR>', { desc = 'LazyGit' })

require('oil').setup {
  columns = {},
  view_options = { show_hidden = true },
  float = {
    padding = 2,
    max_width = 0.8,
    max_height = 0.8,
    border = 'rounded',
  },
  win_options = {
    signcolumn = 'no',
    number = false,
    relativenumber = false,
    wrap = false,
  },
}
vim.keymap.set('n', '-', '<cmd>Oil<CR>', { desc = 'Open parent directory' })
vim.keymap.set('n', '<leader>e', function()
  require('oil').toggle_float()
end, { desc = 'Open file explorer' })

local ok, treesitter = pcall(require, 'nvim-treesitter.configs')
if not ok then
  treesitter = require 'nvim-treesitter.config'
end
treesitter.setup {
  install_dir = vim.fs.joinpath(vim.fn.stdpath 'data', 'site'),
  ensure_installed = { 'bash', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
  auto_install = true,
  highlight = { enable = true },
}

require('conform').setup {
  format_on_save = { timeout_ms = 500, lsp_format = 'fallback' },
  formatters_by_ft = { lua = { 'stylua' } },
}
vim.keymap.set('n', '<leader>f', function()
  require('conform').format { async = true, lsp_format = 'fallback' }
end, { desc = 'Format buffer' })

require('blink.cmp').setup {
  completion = { documentation = { auto_show = true } },
  fuzzy = { implementation = 'lua' },
}

require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '-' },
    changedelete = { text = '~' },
  },
}

require('lazydev').setup()
require('mason').setup()
require('mason-tool-installer').setup { ensure_installed = { 'lua_ls', 'stylua' } }

local capabilities = require('blink.cmp').get_lsp_capabilities()
vim.diagnostic.config { virtual_text = true, severity_sort = true }

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    local opts = { buffer = event.buf }
    vim.keymap.set('n', 'gd', builtin.lsp_definitions, opts)
    vim.keymap.set('n', 'gr', builtin.lsp_references, opts)
    vim.keymap.set('n', 'gi', builtin.lsp_implementations, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action, opts)
  end,
})

require('mason-lspconfig').setup {
  ensure_installed = { 'lua_ls' },
  handlers = {
    function(server)
      require('lspconfig')[server].setup {
        capabilities = capabilities,
        settings = server == 'lua_ls' and { Lua = { completion = { callSnippet = 'Replace' } } } or nil,
      }
    end,
  },
}
