# Cheatsheet Plugin

A Neovim plugin that displays your keymaps in an organized, searchable floating window.

## Features

- Auto-extracts keymaps from Neovim
- Organizes keymaps by category (Search, Toggle, LSP, Git, etc.)
- Beautiful floating window with syntax highlighting
- Toggleable with `<leader>?` or `:Cheatsheet`
- Interactive: press `q` or `<Esc>` to close

## Usage

- `<leader>?` - Toggle cheatsheet window
- `:Cheatsheet` - Toggle cheatsheet window

Inside the cheatsheet window:

- `q` or `<Esc>` - Close window
- `j`/`k` or arrow keys - Scroll through keymaps
- Window auto-closes when you switch buffers

## Configuration

Edit `lua/plugins/cheatsheet.lua` to customize:

```lua
cheatsheet.setup({
  header = {
    '╔═══════════════════════════════════════════╗',
    '║           NEOVIM CHEATSHEET               ║',
    '╚═══════════════════════════════════════════╝',
  },

  -- Patterns to exclude from cheatsheet
  exclude_patterns = {
    '<Plug>',  -- Plugin-internal mappings
    '<SNR>',   -- Script-local mappings
  },

  -- Window size and appearance
  window = {
    width = 0.8,   -- 80% of screen width
    height = 0.8,  -- 80% of screen height
    border = 'rounded',  -- 'none', 'single', 'double', 'rounded', 'solid', 'shadow'
  },

  -- Highlight groups for colors
  highlights = {
    header = 'Title',
    category = 'Function',
    key = 'String',
    description = 'Comment',
  },
})
```

## API Reference

### Main Module (`require('cheatsheet')`)

#### `setup(opts)`

Initialize the plugin with optional configuration.

```lua
require('cheatsheet').setup({
  header = { ... },
  exclude_patterns = { ... },
  window = { ... },
  highlights = { ... },
})
```

#### `toggle()`

Toggle the cheatsheet window (show if hidden, hide if shown).

```lua
require('cheatsheet').toggle()
```

#### `open()`

Open the cheatsheet window.

```lua
require('cheatsheet').open()
```

#### `close()`

Close the cheatsheet window.

```lua
require('cheatsheet').close()
```

### Keymaps Module (`require('cheatsheet.keymaps')`)

#### `extract()`

Extract and organize all keymaps.

Returns: `table` - Array of `{ category, keymaps }` groups

### UI Module (`require('cheatsheet.ui')`)

#### `create_window(grouped_keymaps)`

Create and display the cheatsheet window.

Parameters:

- `grouped_keymaps` (table) - Organized keymap data from `keymaps.extract()`

Returns: `number, number` - buffer handle, window handle

## Extending the Plugin

### Add Custom Categories

Edit `lua/cheatsheet/keymaps.lua`, update `infer_category()`:

```lua
function M.infer_category(keymap)
  local key = keymap.key

  -- Add custom pattern
  if key:match('^<leader>d') then
    return 'Debug'
  end

  -- ... rest of function
end
```

### Add Custom Highlight Groups

Edit `lua/plugins/cheatsheet.lua`, update highlights in setup:

```lua
highlights = {
  header = 'Title',
  category = 'Function',
  key = 'String',
  description = 'Comment',
  footer = 'SpecialComment',  -- Custom group
},
```

### Add Filtering/Search

The plugin can be extended to support live filtering. Add to `ui.lua`:

```lua
-- In setup_buffer function
vim.keymap.set('n', '/', function()
  -- Implement search/filter logic
  -- Filter grouped_keymaps based on user input
  -- Re-render buffer with filtered results
end, { buffer = buf })
```

## Troubleshooting

### No keymaps showing up

Check that your keymaps have descriptions:

```lua
vim.keymap.set('n', '<leader>x', '<cmd>Foo<cr>', { desc = 'Do foo' })
                                                    ^^^^^^^^^^^^^^^^
```

### Window not opening

Check for errors with `:messages` and `:checkhealth`

### Keymaps not grouped correctly

The `infer_category()` function uses heuristics. Add custom patterns for your keymaps.

## Related Neovim Concepts

- `:help api-buffer` - Buffer API
- `:help api-window` - Window API
- `:help nvim_create_buf` - Create buffers
- `:help nvim_open_win` - Open windows
- `:help nvim_buf_set_lines` - Write to buffers
- `:help nvim_get_keymap` - Extract keymaps
- `:help nvim_create_autocmd` - Create autocommands
- `:help lua-guide` - Lua in Neovim

## CHANGELOG

### Updated

- 2025/10/17: added normalize_key to keymaps to transform leader from empty space to `<Leader>`

### Fixed

- 2025/10/17: Fixed table rendering
