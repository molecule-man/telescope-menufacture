# telescope-menufacture

`telescope-menufacture` is an extension for [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim). It extends built-in pickers (`find_files`, `live_grep` and `grep_string`) with the menu that allows to toggle/change such picker options as include hidden dirs, include ignored files, search in particular folders etc.

# Demo

![Demo](https://user-images.githubusercontent.com/1415116/217057418-599761f2-0487-475e-9fce-4ed6352a0547.gif)

# Installation

```lua
-- install as usual e.g. with packer
use { "nvim-telescope/telescope-menufacture" }

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

# Menus available by default

## find_files

| Menu item                         | Description                                                                                        |
| --------------------------------- | -------------------------------------------------------------------------------------------------- |
| search by filename                | specify a filename to search for                                                                   |
| search in directory               | specify directory/directories/files to search in                                                   |
| search relative to current buffer |                                                                                                    |
| toggle follow                     | toggle option regulating whether to follow symlinks (i.e. uses `-L` flag for the `find` command)   |
| toggle hidden                     | toggle option regulating whether to show hidden files                                              |
| toggle no_ignore                  | toggle option regulating whether to show files ignored by .gitignore, .ignore, etc.                |
| toggle no_ignore_parent           | toggle option regulating whether to show files ignored by .gitignore, .ignore, etc. in parent dirs |

## live_grep

| Menu item                         | Description                                                                                        |
| --------------------------------- | -------------------------------------------------------------------------------------------------- |
| change glob_pattern               | specify argument to be used with `--glob`, e.g. "*.toml", or the opposite "!*.toml"                |
| change type_filter                | specify argument to be used with `--type`, e.g. "rust"                                             |
| search in directory               | specify directory/directories/files to search in                                                   |
| search relative to current buffer |                                                                                                    |
| toggle follow                     | toggle option regulating whether to follow symlinks (i.e. uses `-L` flag for the `find` command)   |
| toggle grep_open_files            | toggle option regulating whether to restrict search to open files only                             |
| toggle hidden                     | toggle option regulating whether to show hidden files                                              |
| toggle no_ignore                  | toggle option regulating whether to show files ignored by .gitignore, .ignore, etc.                |
| toggle no_ignore_parent           | toggle option regulating whether to show files ignored by .gitignore, .ignore, etc. in parent dirs |

## grep_string

| Menu item                         | Description                                                                                        |
| --------------------------------- | -------------------------------------------------------------------------------------------------- |
| change query                      |                                                                                                    |
| search in directory               | specify directory/directories/files to search in                                                   |
| search relative to current buffer |                                                                                                    |
| toggle follow                     | toggle option regulating whether to follow symlinks (i.e. uses `-L` flag for the `find` command)   |
| toggle grep_open_files            | toggle option regulating whether to restrict search to open files only                             |
| toggle hidden                     | toggle option regulating whether to show hidden files                                              |
| toggle no_ignore                  | toggle option regulating whether to show files ignored by .gitignore, .ignore, etc.                |
| toggle no_ignore_parent           | toggle option regulating whether to show files ignored by .gitignore, .ignore, etc. in parent dirs |
| toggle use_regex                  | toggle option regulating whether to escape special characters                                      |
