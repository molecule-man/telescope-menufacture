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

## Add direct mapping to invoke menu actions

It's possible to specify mappings that can invoke menufacture menu actions
directly (without telescope picker that allows you to select the menu item):

```lua
vim.keymap.set('n', '<leader>sg', function()
  telescope.extensions.menufacture.live_grep {
    menufacture = {
      mappings = {
        -- [{ 'i', 'n' }] = {
        i = {
          ['<c-d>'] = telescope.extensions.menufacture.menu_actions.search_in_directory.action,
        },
      },
    },
  }
end, { desc = '[S]earch using [G]rep (live_grep)' })
```

In this example ctrl-d should invoke `search_in_directory` action as if you
selected it in menu picker. `search_in_directory` is only one of multiple
actions that can be mapped. Full list of actions can be found in `menu_action`
column in the tables in [the next section](#menus-available-by-default).

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

| Menu item                         | Description                                                                                        | menu_action                       |
| --------------------------------- | -------------------------------------------------------------------------------------------------- | --------------------------------- |
| search by filename                | specify a filename to search for                                                                   | search_by_filename |
| search in directory               | specify directory/directories/files to search in                                                   | search_in_directory |
| search relative to current buffer |                                                                                                    | search_relative_to_current_buffer |
| toggle follow                     | toggle option regulating whether to follow symlinks (i.e. uses `-L` flag for the `find` command)   | toggle_follow |
| toggle hidden                     | toggle option regulating whether to show hidden files                                              | toggle_hidden |
| toggle no_ignore                  | toggle option regulating whether to show files ignored by .gitignore, .ignore, etc.                | toggle_no_ignore |
| toggle no_ignore_parent           | toggle option regulating whether to show files ignored by .gitignore, .ignore, etc. in parent dirs | toggle_no_ignore_parent |

## live_grep

| Menu item                         | Description                                                                                        | menu_action                       |
| --------------------------------- | -------------------------------------------------------------------------------------------------- | --------------------------------- |
| change glob_pattern               | specify argument to be used with `--glob`, e.g. "*.toml", or the opposite "!*.toml"                | change_glob_pattern |
| change type_filter                | specify argument to be used with `--type`, e.g. "rust"                                             | change_type_filter |
| search in directory               | specify directory/directories/files to search in                                                   | search_in_directory |
| search relative to current buffer |                                                                                                    | search_relative_to_current_buffer |
| toggle follow                     | toggle option regulating whether to follow symlinks (i.e. uses `-L` flag for the `find` command)   | toggle_flag_follow |
| toggle grep_open_files            | toggle option regulating whether to restrict search to open files only                             | toggle_grep_open_files |
| toggle hidden                     | toggle option regulating whether to show hidden files                                              | toggle_flag_hidden |
| toggle no_ignore                  | toggle option regulating whether to show files ignored by .gitignore, .ignore, etc.                | toggle_flag_no_ignore |
| toggle no_ignore_parent           | toggle option regulating whether to show files ignored by .gitignore, .ignore, etc. in parent dirs | toggle_flag_no_ignore_parent |

## grep_string

| Menu item                         | Description                                                                                        | menu_action                       |
| --------------------------------- | -------------------------------------------------------------------------------------------------- | --------------------------------- |
| change query                      |                                                                                                    | change_query |
| search in directory               | specify directory/directories/files to search in                                                   | search_in_directory |
| search relative to current buffer |                                                                                                    | search_relative_to_current_buffer |
| toggle follow                     | toggle option regulating whether to follow symlinks (i.e. uses `-L` flag for the `find` command)   | toggle_flag_follow |
| toggle grep_open_files            | toggle option regulating whether to restrict search to open files only                             | toggle_grep_open_files |
| toggle hidden                     | toggle option regulating whether to show hidden files                                              | toggle_flag_hidden |
| toggle no_ignore                  | toggle option regulating whether to show files ignored by .gitignore, .ignore, etc.                | toggle_flag_no_ignore |
| toggle no_ignore_parent           | toggle option regulating whether to show files ignored by .gitignore, .ignore, etc. in parent dirs | toggle_flag_no_ignore_parent |
| toggle use_regex                  | toggle option regulating whether to escape special characters                                      | toggle_use_regex |

## git_files

| Menu item                         | Description                                                                                | menu_action                       |
| --------------------------------- | ------------------------------------------------------------------------------------------ | --------------------------------- |
| search relative to current buffer |                                                                                            | search_relative_to_current_buffer |
| toggle show_untracked             | toggle option regulating whether to add `--other` flag to command and show untracked files | toggle_show_untracked |
| toggle recurse_submodules         | toggle option regulating whether to add `--recurse-submodules` flag to command             | toggle_recurse_submodules |
