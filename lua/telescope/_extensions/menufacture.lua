local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
  error 'This extension requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)'
end

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local utils = require 'telescope.utils'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local action_utils = require 'telescope.actions.utils'
local make_entry = require 'telescope.make_entry'
local async_oneshot_finder = require 'telescope.finders.async_oneshot_finder'
local scan = require 'plenary.scandir'
local builtin = require 'telescope.builtin'

local M = {
  config = {
    mappings = {
      main_menu = { [{ 'i', 'n' }] = '<C-^>' },
    },
  },
}

M.toggle = function(key)
  return function(opts, callback)
    opts[key] = not opts[key]
    callback(opts)
  end
end

M.toggle_flag = function(flag_key, flag_value)
  local key = 'flag_' .. flag_key .. flag_value
  return function(opts, callback)
    opts[key] = not opts[key]

    local old_flags = opts[flag_key] or {}
    if type(old_flags) == 'function' then
      old_flags = old_flags(opts)
    end
    local new_flags = {}
    for _, v in pairs(old_flags) do
      if v ~= flag_value then
        table.insert(new_flags, v)
      end
    end
    if opts[key] then
      table.insert(new_flags, flag_value)
    end
    opts[flag_key] = new_flags
    callback(opts)
  end
end

M.input = function(key, prompt)
  return function(opts, callback)
    vim.ui.input({ prompt = prompt, default = opts[key] }, function(input)
      opts[key] = input
      callback(opts)
    end)
  end
end

M.set_cwd_to_current_buffer = function(opts, callback)
  opts.cwd = utils.buffer_dir()
  callback(opts)
end

M.folder_finder = function(opts)
  local cwd = vim.fn.expand(opts.cwd or vim.loop.cwd())
  local entry_maker = make_entry.gen_from_file(opts)
  if 1 == vim.fn.executable 'fd' then
    local args = { '-t', 'd', '-a' }
    if opts.hidden then
      table.insert(args, '-H')
    end
    if opts.no_ignore then
      table.insert(args, '--no-ignore-vcs')
    end
    return async_oneshot_finder {
      fn_command = function()
        return { command = 'fd', args = args }
      end,
      entry_maker = entry_maker,
      results = { entry_maker(cwd) },
      cwd = cwd,
    }
  else
    local data = scan.scan_dir(cwd, {
      hidden = opts.hidden,
      only_dirs = true,
      respect_gitignore = opts.respect_gitignore,
    })
    table.insert(data, 1, cwd)
    return finders.new_table { results = data, entry_maker = entry_maker }
  end
end

M.search_in_directory = function(key)
  return function(opts, callback)
    pickers
      .new({}, {
        prompt_title = 'select directory',
        finder = M.folder_finder(opts),
        sorter = conf.generic_sorter {},
        attach_mappings = function(prompt_bufnr, _)
          actions.select_default:replace(function()
            local dirs = {}
            action_utils.map_selections(prompt_bufnr, function(entry)
              table.insert(dirs, entry.path or entry.filename or entry.value)
            end)
            if vim.tbl_count(dirs) == 0 then
              local entry = action_state.get_selected_entry()
              table.insert(dirs, entry.path or entry.filename or entry.value)
            end
            actions.close(prompt_bufnr)
            opts[key] = dirs
            callback(opts)
          end)
          return true
        end,
      })
      :find()
    return opts
  end
end

M.add_menu = function(fn, menu)
  local function launch(opts)
    opts = opts or {}

    opts.attach_mappings = function(_, map)
      for mode, mode_map in pairs(menu) do
        for key_bind, menu_actions in pairs(mode_map) do
          local action_entries = vim.tbl_keys(menu_actions)
          table.sort(action_entries)
          local results = {}
          for i, action in pairs(action_entries) do
            table.insert(results, { string.format('%d: %s', i, action), action })
          end
          map(mode, key_bind, function(prompt_bufnr)
            opts.prompt_value = action_state.get_current_picker(prompt_bufnr):_get_prompt()
            pickers
              .new({}, {
                prompt_title = 'actions',
                finder = finders.new_table {
                  results = results,
                  entry_maker = function(entry)
                    return {
                      value = entry,
                      display = entry[1],
                      ordinal = entry[1],
                    }
                  end,
                },
                sorter = conf.generic_sorter {},
                attach_mappings = function(prompt_bufnr)
                  actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    if selection == nil then
                      utils.__warn_no_selection 'menufacture'
                      return
                    end
                    menu_actions[selection.value[2]](opts, launch)
                  end)
                  return true
                end,
              })
              :find()
          end)
        end
      end

      return true
    end

    fn(vim.tbl_extend('force', opts, { default_text = opts.prompt_value }))
  end

  return launch
end

M.add_menu_with_default_mapping = function(fn, menu)
  return function(opts)
    local menus = {}

    for mode, key_bind in pairs(M.config.mappings.main_menu) do
      menus[mode] = {}
      menus[mode][key_bind] = menu
    end

    M.add_menu(fn, menus)(opts)
  end
end

M.find_files_menu = {
  ['search relative to current buffer'] = M.set_cwd_to_current_buffer,
  ['search by filename'] = M.input('search_file', 'Filename: '),
  ['toggle hidden'] = M.toggle 'hidden',
  ['toggle no_ignore'] = M.toggle 'no_ignore',
  ['toggle no_ignore_parent'] = M.toggle 'no_ignore_parent',
  ['toggle follow'] = M.toggle 'follow',
  ['search in directory'] = M.search_in_directory 'search_dirs',
}

M.live_grep_menu = {
  ['search relative to current buffer'] = M.set_cwd_to_current_buffer,
  ['search in directory'] = M.search_in_directory 'search_dirs',
  ['toggle grep_open_files'] = M.toggle 'grep_open_files',
  ['change glob_pattern'] = M.input('glob_pattern', 'Glob pattern: '),
  ['change type_filter'] = M.input('type_filter', 'Type filter: '),
  ['toggle hidden'] = M.toggle_flag('additional_args', '--hidden'),
  ['toggle no_ignore'] = M.toggle_flag('additional_args', '--no-ignore'),
  ['toggle no_ignore_parent'] = M.toggle_flag('additional_args', '--no-ignore-parent'),
  ['toggle follow'] = M.toggle_flag('additional_args', '-L'),
}

M.grep_string_menu = {
  ['search relative to current buffer'] = M.set_cwd_to_current_buffer,
  ['search in directory'] = M.search_in_directory 'search_dirs',
  ['toggle grep_open_files'] = M.toggle 'grep_open_files',
  ['toggle use_regex'] = M.toggle 'use_regex',
  ['toggle hidden'] = M.toggle_flag('additional_args', '--hidden'),
  ['toggle no_ignore'] = M.toggle_flag('additional_args', '--no-ignore'),
  ['toggle no_ignore_parent'] = M.toggle_flag('additional_args', '--no-ignore-parent'),
  ['toggle follow'] = M.toggle_flag('additional_args', '-L'),
  ['change query'] = M.input('search', 'Query: '),
}

M.git_files_menu = {
  ['search relative to current buffer'] = M.set_cwd_to_current_buffer,
  ['toggle show_untracked'] = M.toggle 'show_untracked',
  ['toggle recurse_submodules'] = M.toggle 'recurse_submodules',
}

M.find_files = M.add_menu_with_default_mapping(builtin.find_files, M.find_files_menu)
M.live_grep = M.add_menu_with_default_mapping(builtin.live_grep, M.live_grep_menu)
M.grep_string = M.add_menu_with_default_mapping(builtin.grep_string, M.grep_string_menu)
M.git_files = M.add_menu_with_default_mapping(builtin.git_files, M.git_files_menu)

return telescope.register_extension {
  setup = function(opts)
    M.config = vim.tbl_deep_extend('force', M.config, opts)
  end,
  exports = M,
}
