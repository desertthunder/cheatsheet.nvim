local M = {}

M.defaults = {
  header = {
    '╔═══════════════════════════════════════════╗',
    '║           NEOVIM CHEATSHEET               ║',
    '╚═══════════════════════════════════════════╝',
  },

  exclude_patterns = { '<Plug>', '<SNR>' },
  window = { width = 0.8, height = 0.8, border = 'rounded' },
  highlights = { header = 'Title', category = 'Function', key = 'String', description = 'Comment' },
}

M.current = vim.deepcopy(M.defaults)

function M.setup(user_opts) M.current = vim.tbl_deep_extend('force', M.defaults, user_opts or {}) end

function M.get() return M.current end

return M
