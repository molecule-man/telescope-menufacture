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

function generate_opt_key_for_flag(flag_key, flag_value)
  return 'flag_' .. flag_key .. flag_value
end

M.toggle_flag = function(flag_key, flag_value)
  local key = generate_opt_key_for_flag(flag_key, flag_value)
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
    local args = { '-t', 'd' }
    if opts.hidden or opts['flag_additional_args--hidden'] then
      table.insert(args, '-H')
    end
    if opts.no_ignore or opts['flag_additional_args--no-ignore'] then
      table.insert(args, '--no-ignore')
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

    opts.original_prompt_title = opts.original_prompt_title or opts.prompt_title

    if opts.original_prompt_title then
      local flags = {}
      for _, mode_map in pairs(menu) do
        for _, menu_actions in pairs(mode_map) do
          local action_entries = vim.tbl_keys(menu_actions)
          table.sort(action_entries)
          for _, action_text in pairs(action_entries) do
            local action_info = menu_actions[action_text]
            if type(action_info) == 'table' then
              if action_info.state_short then
                local state_short = action_info.state_short(opts)
                if state_short then
                  table.insert(flags, state_short)
                end
              end
            end
          end
        end
      end

      opts.prompt_title = opts.original_prompt_title
      if #flags > 0 then
        opts.prompt_title = opts.prompt_title .. ' [' .. table.concat(flags, ' ') .. ']'
      end
    end

    local user_attach_mappings = opts.attach_mappings

    opts.attach_mappings = function(bufnr, map)
      local ret_val = true
      if user_attach_mappings then
        ret_val = user_attach_mappings(bufnr, map)
      end

      local actions_indexed_by_name = {}

      for mode, mode_map in pairs(menu) do
        for key_bind, menu_actions in pairs(mode_map) do
          local action_entries = vim.tbl_keys(menu_actions)
          table.sort(action_entries)
          local results = {}
          for i, action_text in pairs(action_entries) do
            local action_info = menu_actions[action_text]
            if type(action_info) == 'function' then
              action_info = { action = action_info, text = action_text, action_name = action_text:gsub('%s+', '_') }
              menu_actions[action_text] = action_info
            end

            local display_text = string.format('%d: %s', i, action_text)
            if action_info.state then
              display_text = display_text .. ' (current value: ' .. action_info.state(opts) .. ')'
            end
            table.insert(results, { display_text, action_text })

            actions_indexed_by_name[action_info.action_name] = action_info.action
          end
          for _, value in pairs(mode) do
            map(value, key_bind, function(prompt_bufnr)
              local picker = action_state.get_current_picker(prompt_bufnr)
              opts.prompt_value = picker:_get_prompt()
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
                      menu_actions[selection.value[2]].action(opts, launch)
                    end)
                    return true
                  end,
                })
                :find()
            end, { desc = 'menufacture|launch_menu' })
          end
        end
      end

      local action_mapper = function(action)
        return function(prompt_bufnr)
          opts.prompt_value = action_state.get_current_picker(prompt_bufnr):_get_prompt()
          actions.close(prompt_bufnr)
          action(opts, launch)
        end
      end

      for action_name, mappings in pairs(M.config.mappings) do
        for mode, key in pairs(mappings) do
          if actions_indexed_by_name[action_name] then
            map(mode, key, action_mapper(actions_indexed_by_name[action_name]), { desc = 'menufacture|' .. action_name })
          end
        end
      end

      local menufacture_obj = opts.menufacture or {}
      local mappings = menufacture_obj.mappings or {}
      for mode, binding in pairs(mappings) do
        for key, action in pairs(binding) do
          map(mode, key, action_mapper(action))
        end
      end

      return ret_val
    end

    fn(vim.tbl_extend('force', opts, { default_text = opts.prompt_value }))
  end

  return launch
end

M.add_menu_with_default_mapping = function(fn, menu, default_opts)
  return function(opts)
    opts = vim.tbl_extend('keep', opts or {}, default_opts or {})

    local menus = {}

    for mode, key_bind in pairs(M.config.mappings.main_menu) do
      menus[mode] = {}
      menus[mode][key_bind] = menu
    end

    M.add_menu(fn, menus)(opts)
  end
end

local function snake_to_acronym(snake_case)
  local acronym = ''
  for word in snake_case:gmatch '[^_]+' do
    acronym = acronym .. word:sub(1, 1):upper()
  end
  return acronym
end

generate_menu_action_toggle = function(key)
  return {
    action = M.toggle(key),
    text = 'toggle ' .. key,
    state = function(opts)
      return opts[key] and 'enabled' or 'disabled'
    end,
    state_short = function(opts)
      if opts[key] then
        return snake_to_acronym(key)
      end
      return nil
    end,
  }
end

generate_menu_action_toggle_flag = function(key, flag_key, flag_value)
  return {
    action = M.toggle_flag(flag_key, flag_value),
    action_name = 'toggle_' .. key,
    text = 'toggle ' .. key,
    state = function(opts)
      local opt_key = generate_opt_key_for_flag(flag_key, flag_value)
      return opts[opt_key] and 'enabled' or 'disabled'
    end,
    state_short = function(opts)
      local opt_key = generate_opt_key_for_flag(flag_key, flag_value)
      if opts[opt_key] then
        return snake_to_acronym(key)
      end
      return nil
    end,
  }
end

M.menu_actions = {
  search_relative_to_current_buffer = {
    action = M.set_cwd_to_current_buffer,
    text = 'search relative to current buffer',
  },
  search_by_filename = {
    action = M.input('search_file', 'Filename: '),
    text = 'search by filename',
  },
  toggle_hidden = generate_menu_action_toggle 'hidden',
  toggle_no_ignore = generate_menu_action_toggle 'no_ignore',
  toggle_no_ignore_parent = generate_menu_action_toggle 'no_ignore_parent',
  toggle_follow = generate_menu_action_toggle 'follow',
  search_in_directory = {
    action = M.search_in_directory 'search_dirs',
    text = 'search in directory',
  },
  toggle_flag_hidden = generate_menu_action_toggle_flag('hidden', 'additional_args', '--hidden'),
  toggle_flag_no_ignore = generate_menu_action_toggle_flag('no_ignore', 'additional_args', '--no-ignore'),
  toggle_flag_no_ignore_parent = generate_menu_action_toggle_flag('no_ignore_parent', 'additional_args', '--no-ignore-parent'),
  toggle_flag_follow = generate_menu_action_toggle_flag('follow', 'additional_args', '-L'),
  toggle_grep_open_files = generate_menu_action_toggle 'grep_open_files',
  toggle_use_regex = generate_menu_action_toggle 'use_regex',
  change_glob_pattern = {
    action = M.input('glob_pattern', 'Glob pattern: '),
    text = 'change glob_pattern',
  },
  change_type_filter = {
    action = M.input('type_filter', 'Type filter: '),
    text = 'change type_filter',
  },
  change_query = {
    action = M.input('search', 'Query: '),
    text = 'change query',
  },
  toggle_show_untracked = generate_menu_action_toggle 'show_untracked',
  toggle_recurse_submodules = generate_menu_action_toggle 'recurse_submodules',
  toggle_include_current_session = generate_menu_action_toggle 'include_current_session',
  toggle_cwd_only = generate_menu_action_toggle 'cwd_only',
}

for default_action_name, menu_action_info in pairs(M.menu_actions) do
  menu_action_info.action_name = menu_action_info.action_name or default_action_name
end

local set_menu = function(menu, menu_action_info)
  menu[menu_action_info.text] = menu_action_info
end

M.find_files_menu = {}
set_menu(M.find_files_menu, M.menu_actions.search_relative_to_current_buffer)
set_menu(M.find_files_menu, M.menu_actions.search_by_filename)
set_menu(M.find_files_menu, M.menu_actions.toggle_hidden)
set_menu(M.find_files_menu, M.menu_actions.toggle_no_ignore)
set_menu(M.find_files_menu, M.menu_actions.toggle_no_ignore_parent)
set_menu(M.find_files_menu, M.menu_actions.toggle_follow)
set_menu(M.find_files_menu, M.menu_actions.search_in_directory)

M.live_grep_menu = {}
set_menu(M.live_grep_menu, M.menu_actions.search_relative_to_current_buffer)
set_menu(M.live_grep_menu, M.menu_actions.search_in_directory)
set_menu(M.live_grep_menu, M.menu_actions.toggle_grep_open_files)
set_menu(M.live_grep_menu, M.menu_actions.change_glob_pattern)
set_menu(M.live_grep_menu, M.menu_actions.change_type_filter)
set_menu(M.live_grep_menu, M.menu_actions.toggle_flag_hidden)
set_menu(M.live_grep_menu, M.menu_actions.toggle_flag_no_ignore)
set_menu(M.live_grep_menu, M.menu_actions.toggle_flag_no_ignore_parent)
set_menu(M.live_grep_menu, M.menu_actions.toggle_flag_follow)

M.grep_string_menu = {}
set_menu(M.grep_string_menu, M.menu_actions.search_relative_to_current_buffer)
set_menu(M.grep_string_menu, M.menu_actions.search_in_directory)
set_menu(M.grep_string_menu, M.menu_actions.toggle_grep_open_files)
set_menu(M.grep_string_menu, M.menu_actions.toggle_use_regex)
set_menu(M.grep_string_menu, M.menu_actions.toggle_flag_hidden)
set_menu(M.grep_string_menu, M.menu_actions.toggle_flag_no_ignore)
set_menu(M.grep_string_menu, M.menu_actions.toggle_flag_no_ignore_parent)
set_menu(M.grep_string_menu, M.menu_actions.toggle_flag_follow)
set_menu(M.grep_string_menu, M.menu_actions.change_query)

M.git_files_menu = {}
set_menu(M.git_files_menu, M.menu_actions.search_relative_to_current_buffer)
set_menu(M.git_files_menu, M.menu_actions.toggle_show_untracked)
set_menu(M.git_files_menu, M.menu_actions.toggle_recurse_submodules)

M.oldfiles_menu = {}
set_menu(M.oldfiles_menu, M.menu_actions.search_relative_to_current_buffer)
set_menu(M.oldfiles_menu, M.menu_actions.toggle_include_current_session)
set_menu(M.oldfiles_menu, M.menu_actions.toggle_cwd_only)

M.find_files = M.add_menu_with_default_mapping(builtin.find_files, M.find_files_menu, { prompt_title = 'Find Files' })
M.live_grep = M.add_menu_with_default_mapping(builtin.live_grep, M.live_grep_menu, { prompt_title = 'Live Grep' })
M.grep_string = M.add_menu_with_default_mapping(builtin.grep_string, M.grep_string_menu, { prompt_title = 'Grep String' })
M.git_files = M.add_menu_with_default_mapping(builtin.git_files, M.git_files_menu, { prompt_title = 'Git Files' })
M.oldfiles = M.add_menu_with_default_mapping(builtin.oldfiles, M.oldfiles_menu, { prompt_title = 'Oldfiles' })

return telescope.register_extension {
  setup = function(opts)
    M.config = vim.tbl_deep_extend('force', M.config, opts)
  end,
  exports = M,
}
