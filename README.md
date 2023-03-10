# telescope-menufacture

`telescope-menufacture` is an extension for [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim). It extends built-in pickers (`find_files`, `live_grep`, `grep_string` and `git_files`) with the menu that allows to toggle/change such picker options as include hidden dirs, include ignored files, search in particular folders etc.

# Demo

![Demo](https://user-images.githubusercontent.com/1415116/217057418-599761f2-0487-475e-9fce-4ed6352a0547.gif)

# Installation

```lua
-- install as usual e.g. with packer
use { 'molecule-man/telescope-menufacture' }

-- To get telescope-menufacture loaded and working with telescope,
-- you need to call load_extension:
require('telescope').load_extension 'menufacture'
```

# Usage

replace your standard `find_files` `grep_string` `live_grep` and `git_files` mappings

```lua
vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files)
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string)
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep)
vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files)
```

with the ones provided by this extension:

```lua
vim.keymap.set('n', '<leader>sf', require('telescope').extensions.menufacture.find_files)
vim.keymap.set('n', '<leader>sg', require('telescope').extensions.menufacture.live_grep)
vim.keymap.set('n', '<leader>sw', require('telescope').extensions.menufacture.grep_string)
vim.keymap.set('n', '<leader>gf', require('telescope').extensions.menufacture.git_files)

```

then, while using this pickers, press `ctrl-^` (`ctrl-6`) and this will open the menu.

# Configuration

You can configure the `telescope-menufacture` like any other `telescope.nvim` extension.
Here you can change the default mapping `ctrl-^` to something else.

```lua
require('telescope').setup {
  extensions = {
    menufacture = {
      mappings = {
        main_menu = { [{ 'i', 'n' }] = '<C-^>' },
      },
    },
  },
}

```

# Customization

## Add your own menu item

It's possible to add your own menu items. To do that you have to extend (or create new one from scratch) the list of menu items with your additional menu entries and corresponding actions. The action takes picker's `opts` as the first argument and `callback` as the second argument. The `callback` must be called with `opts` in the end of the action. Let's add menu item that changes `cwd` to the parent of the current `cwd`:

```lua
vim.keymap.set(
  'n',
  '<leader>sf',
  require('telescope').extensions.menufacture.add_menu_with_default_mapping(
    require('telescope.builtin').find_files,
    vim.tbl_extend('force', require('telescope').extensions.menufacture.find_files_menu, {
      ['change cwd to parent'] = function(opts, callback)
        local cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.loop.cwd()
        opts.cwd = vim.fn.fnamemodify(cwd, ':p:h:h')
        callback(opts)
      end,
    })
  )
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

## git_files

| Menu item                         | Description                                                                                |
| --------------------------------- | ------------------------------------------------------------------------------------------ |
| search relative to current buffer |                                                                                            |
| toggle show_untracked             | toggle option regulating whether to add `--other` flag to command and show untracked files |
| toggle recurse_submodules         | toggle option regulating whether to add `--recurse-submodules` flag to command             |
