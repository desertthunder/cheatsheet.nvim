local M = {}

function M.create_window(grouped_keymaps)
  local config = require('config').get()
  local buf = M.create_buffer()
  local win = M.open_floating_window(buf, config.window)

  M.render_content(buf, grouped_keymaps, config)
  M.setup_buffer(buf, win)

  return buf, win
end

function M.create_buffer()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].filetype = 'cheatsheet'
  vim.bo[buf].bufhidden = 'wipe'
  return buf
end

function M.open_floating_window(buf, window_config)
  local ui = vim.api.nvim_list_uis()[1]
  local width = ui.width
  local height = ui.height

  local win_width = math.floor(width * window_config.width)
  local win_height = math.floor(height * window_config.height)

  local row = math.floor((height - win_height) / 2)
  local col = math.floor((width - win_width) / 2)

  local opts = {
    relative = 'editor',
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = 'minimal',
    border = window_config.border,
    title = ' Cheatsheet ',
    title_pos = 'center',
  }

  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.wo[win].winhl = 'Normal:Normal'
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
  vim.wo[win].scrolloff = 0
  vim.api.nvim_set_option_value('fillchars', 'eob: ', { win = win })

  return win
end

function M.format_category_block(category, keymaps, width)
  local lines = {}
  local col_width = math.floor((width - 6) / 2)

  local category_text = ' ' .. category .. ' '
  local border_fill = string.rep('─', width - vim.fn.strdisplaywidth(category_text) - 3)
  table.insert(lines, '╭─' .. category_text .. border_fill .. '╮')

  for i = 1, #keymaps, 2 do
    local left_keymap = keymaps[i]
    local right_keymap = keymaps[i + 1]

    local left_col = M.format_keymap_compact(left_keymap, col_width)
    local right_col = right_keymap and M.format_keymap_compact(right_keymap, col_width) or string.rep(' ', col_width)

    table.insert(lines, '│ ' .. left_col .. '  ' .. right_col .. ' │')
  end

  table.insert(lines, '╰' .. string.rep('─', width - 2) .. '╯')
  return lines
end

function M.format_keymap_compact(keymap, width)
  local mode_indicator = string.format('[%s]', keymap.mode)
  local key_part = string.format('%s %-12s', mode_indicator, keymap.key)
  local key_len = vim.fn.strdisplaywidth(key_part)
  local desc_width = width - key_len - 1

  local desc = keymap.description
  if vim.fn.strdisplaywidth(desc) > desc_width then desc = string.sub(desc, 1, desc_width - 1) .. '…' end

  return M.pad_string(key_part .. ' ' .. desc, width)
end

function M.render_content(buf, grouped_keymaps, config)
  local lines = {}
  local ui = vim.api.nvim_list_uis()[1]
  local win_width = math.floor(ui.width * config.window.width)

  if config.header then
    for _, line in ipairs(config.header) do
      table.insert(lines, M.center_string(line, win_width))
    end
    table.insert(lines, '')
  end

  for _, group in ipairs(grouped_keymaps) do
    local block_lines = M.format_category_block(group.category, group.keymaps, win_width)
    for _, line in ipairs(block_lines) do
      table.insert(lines, line)
    end
    table.insert(lines, '')
  end

  table.insert(lines, '')
  table.insert(lines, M.center_string(string.rep('─', win_width - 4), win_width))
  table.insert(lines, M.center_string('Press q or <Esc> to close', win_width))

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  M.apply_highlights(buf, lines, config)
end

function M.format_keymap_line(keymap)
  local mode_width = 3
  local key_width = 20
  local mode_indicator = string.format('[%s]', keymap.mode)
  local padded_key = M.pad_string(keymap.key, key_width)
  return string.format('  %s %s  %s', M.pad_string(mode_indicator, mode_width), padded_key, keymap.description)
end

function M.pad_string(str, width)
  local len = vim.fn.strdisplaywidth(str)
  if len >= width then return str end
  return str .. string.rep(' ', width - len)
end

function M.center_string(str, width)
  local len = vim.fn.strdisplaywidth(str)
  if len >= width then return str end
  local padding = math.floor((width - len) / 2)
  return string.rep(' ', padding) .. str
end

function M.apply_highlights(buf, lines, config)
  local ns = vim.api.nvim_create_namespace 'cheatsheet'
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  for i, line in ipairs(lines) do
    local line_idx = i - 1

    if i <= #config.header then
      vim.api.nvim_buf_set_extmark(buf, ns, line_idx, 0, {
        hl_group = config.highlights.header,
        end_line = line_idx + 1,
      })
    elseif line:match '^╭─' or line:match '^╰' then
      vim.api.nvim_buf_set_extmark(buf, ns, line_idx, 0, {
        hl_group = config.highlights.category,
        end_line = line_idx + 1,
      })
    elseif line:match '^│' then
      -- Highlight left border
      vim.api.nvim_buf_set_extmark(buf, ns, line_idx, 0, {
        hl_group = config.highlights.category,
        end_col = 3,  -- │ is 3 bytes in UTF-8
      })
      -- Highlight right border (│ is 3 bytes in UTF-8)
      local line_byte_len = #line
      if line_byte_len > 0 then
        vim.api.nvim_buf_set_extmark(buf, ns, line_idx, line_byte_len - 3, {
          hl_group = config.highlights.category,
          end_col = line_byte_len,
        })
      end
    end
  end
end

function M.setup_buffer(buf, win)
  local opts = { buffer = buf, noremap = true, silent = true }

  local function close_window()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
  end

  vim.keymap.set('n', 'q', close_window, opts)
  vim.keymap.set('n', '<Esc>', close_window, opts)

  local function safe_move(key)
    return function()
      local line_count = vim.api.nvim_buf_line_count(buf)
      local current_line = vim.api.nvim_win_get_cursor(win)[1]

      if key == 'j' or key == '<Down>' then
        if current_line < line_count then vim.cmd('normal! ' .. key) end
      elseif key == 'k' or key == '<Up>' then
        if current_line > 1 then vim.cmd('normal! ' .. key) end
      else
        vim.cmd('normal! ' .. key)
      end
    end
  end

  vim.keymap.set('n', 'j', safe_move 'j', opts)
  vim.keymap.set('n', 'k', safe_move 'k', opts)
  vim.keymap.set('n', '<Down>', safe_move '<Down>', opts)
  vim.keymap.set('n', '<Up>', safe_move '<Up>', opts)
  vim.keymap.set('n', 'G', safe_move 'G', opts)

  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = buf,
    callback = close_window,
    once = true,
  })
end

return M
