# telescope-menufacture.nvim

`telescope-menufacture.nvim` is an extension for [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim). It extends built-in pickers (`find_files`, `live_grep` and `grep_string`) with the menu that allows to toggle/change such picker options as include hidden dirs, include ignored files, search in particular folders etc.


# Installation

```lua
-- install as usual e.g. with packer
use { "nvim-telescope/telescope-menufacture.nvim" }

-- To get telescope-menufacture loaded and working with telescope,
-- you need to call load_extension:
require("telescope").load_extension "menufacture"
```

# Usage
replace your standard `find_files` `grep_string` and `live_grep` mappings
```lua
vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files)
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string)
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep)
```
with the ones provided by this extension:
```lua
vim.keymap.set('n', '<leader>sf', require('telescope').extensions.menufacture.find_files)
vim.keymap.set('n', '<leader>sg', require('telescope').extensions.menufacture.live_grep)
vim.keymap.set('n', '<leader>sw', require('telescope').extensions.menufacture.grep_string)
```
then, while using this pickers, press `ctrl-^` (`ctrl-6`) and this will open the menu.

## Use mapping other than ctrl-^
Let's say you want to use `ctrl-i` instead of `ctrl-^` then the setup should look like this:
```lua
vim.keymap.set(
  'n',
  '<leader>sf',
  require('telescope').extensions.menufacture.add_menu(require('telescope.builtin').find_files, {
    [{ 'i', 'n' }] = {
      ['<C-i>'] = require('telescope').extensions.menufacture.find_files_menu,
    },
  })
)
vim.keymap.set(
  'n',
  '<leader>sg',
  require('telescope').extensions.menufacture.add_menu(require('telescope.builtin').live_grep, {
    [{ 'i', 'n' }] = {
      ['<C-i>'] = require('telescope').extensions.menufacture.live_grep_menu,
    },
  })
)
vim.keymap.set(
  'n',
  '<leader>sw',
  require('telescope').extensions.menufacture.add_menu(require('telescope.builtin').grep_string, {
    [{ 'i', 'n' }] = {
      ['<C-i>'] = require('telescope').extensions.menufacture.grep_string_menu,
    },
  })
)
```
