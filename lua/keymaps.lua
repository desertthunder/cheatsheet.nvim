local M = {}

function M.extract()
  local config = require('config').get()
  local modes = { 'n', 'v', 'i', 't' }
  local all_keymaps = {}

  for _, mode in ipairs(modes) do
    local mode_maps = M.get_mode_keymaps(mode)
    for _, keymap in ipairs(mode_maps) do
      if M.should_include(keymap, config.exclude_patterns) then table.insert(all_keymaps, keymap) end
    end
  end

  return M.group_keymaps(all_keymaps)
end

-- Replaces literal leader with <Leader>
function M.normalize_key(key)
  local leader = vim.g.mapleader or ' ' -- I use space as my leader key
  if key:sub(1, 1) == leader then
    key = '<Leader>' .. key:sub(2)
  end
  return key
end

function M.get_mode_keymaps(mode)
  local keymaps = {}
  local raw_maps = vim.api.nvim_get_keymap(mode)

  for _, map in ipairs(raw_maps) do
    if map.desc and map.desc ~= '' then
      table.insert(keymaps, {
        mode = mode,
        key = M.normalize_key(map.lhs),
        description = map.desc,
        rhs = map.rhs,
      })
    end
  end

  return keymaps
end

function M.should_include(keymap, exclude_patterns)
  for _, pattern in ipairs(exclude_patterns) do
    if keymap.key:find(pattern, 1, true) then return false end
  end

  if not keymap.description or keymap.description == '' then return false end

  return true
end

function M.group_keymaps(keymaps)
  local groups = {}
  local group_map = {}

  for _, keymap in ipairs(keymaps) do
    local category = M.infer_category(keymap)

    if not group_map[category] then
      group_map[category] = {
        category = category,
        keymaps = {},
      }
      table.insert(groups, group_map[category])
    end

    table.insert(group_map[category].keymaps, keymap)
  end

  table.sort(groups, function(a, b) return a.category < b.category end)

  return groups
end

function M.infer_category(keymap)
  local key = keymap.key
  local desc = keymap.description

  if key:match '^<[Ll]eader>s' then return 'Search' end
  if key:match '^<[Ll]eader>t' then return 'Toggle' end
  if key:match '^<[Ll]eader>h' then return 'Git Hunk' end

  if desc:lower():find 'search' or desc:lower():find 'find' then return 'Search' end
  if desc:lower():find 'git' or desc:lower():find 'hunk' then return 'Git' end
  if desc:lower():find 'lsp' or desc:lower():find 'code' then return 'LSP' end
  if desc:lower():find 'window' or desc:lower():find 'split' then return 'Windows' end
  if desc:lower():find 'buffer' then return 'Buffers' end

  local mode_names = {
    n = 'Normal',
    v = 'Visual',
    i = 'Insert',
    t = 'Terminal',
  }

  return mode_names[keymap.mode] or 'Other'
end

return M
