local M = {}

local git = require('ts-pack.git')
local path = require('ts-pack.path')

local uv = vim.uv or vim.loop

local MIN_NVIM_VERSION = { major = 0, minor = 11, patch = 0 }

local function exists(target)
  return uv.fs_stat(target) ~= nil
end

local function read_first_line(target)
  if not exists(target) then
    return nil
  end
  return vim.fn.readfile(target, '', 1)[1]
end

local function sorted_keys(tbl)
  local result = {}
  for key in pairs(tbl) do
    result[#result + 1] = key
  end
  table.sort(result)
  return result
end

local function health()
  return vim.health
end

local function version_to_string(version)
  if type(version) ~= 'table' then
    return tostring(version or '<unknown>')
  end

  local result = ('%d.%d.%d'):format(version.major or 0, version.minor or 0, version.patch or 0)
  if version.prerelease then
    result = result .. '-' .. version.prerelease
  end
  return result
end

local function version_ge(left, right)
  for _, key in ipairs({ 'major', 'minor', 'patch' }) do
    local lvalue = left[key] or 0
    local rvalue = right[key] or 0
    if lvalue > rvalue then
      return true
    elseif lvalue < rvalue then
      return false
    end
  end
  return true
end

local function command_info(command)
  if vim.fn.executable(command) ~= 1 then
    return nil
  end

  local output = vim.fn.system({ command, '--version' })
  local first_line = vim.trim(vim.split(output or '', '\n', { plain = true })[1] or '')
  local parsed
  if first_line ~= '' and vim.version and type(vim.version.parse) == 'function' then
    local ok, version = pcall(vim.version.parse, first_line)
    if ok then
      parsed = version
    end
  end

  return {
    command = command,
    path = vim.fn.exepath(command),
    output = first_line,
    version = parsed,
  }
end

local function command_message(label, info)
  local output = info.output ~= '' and info.output or '<version unavailable>'
  local details = { info.path }
  if info.version then
    details[#details + 1] = 'parsed: ' .. version_to_string(info.version)
  end
  return ('%s: %s (%s)'):format(label, output, table.concat(details, ', '))
end

local function report_command(label, command, missing_message, missing_kind)
  local h = health()
  local info = command_info(command)
  if info then
    h.ok(command_message(label, info))
    return info
  end

  h[missing_kind or 'error'](missing_message)
  return nil
end

local function active_source_root(spec)
  local root = spec.path or git.checkout_path(spec)
  if spec.location then
    root = path.join(root, spec.location)
  end
  return root
end

local function active_tree_sitter_required_names(active)
  local result = {}
  for name, item in pairs(active) do
    local spec = item.spec
    if spec and spec.generate then
      result[#result + 1] = name
    elseif spec then
      local root = active_source_root(spec)
      if exists(root) and not exists(path.join(root, 'src', 'parser.c')) then
        result[#result + 1] = name
      end
    end
  end
  table.sort(result)
  return result
end

local function active_cpp_scanner_names(active)
  local result = {}
  for name, item in pairs(active) do
    local spec = item.spec
    if spec then
      local root = active_source_root(spec)
      if exists(path.join(root, 'src', 'scanner.cc')) then
        result[#result + 1] = name
      end
    end
  end
  table.sort(result)
  return result
end

local function env_or(name, fallback)
  local value = vim.env[name]
  if value and value ~= '' then
    return value
  end
  return fallback
end

local function report_neovim()
  local h = health()
  local current = vim.version()
  local current_version = version_to_string(current)
  local minimum = version_to_string(MIN_NVIM_VERSION)

  if version_ge(current, MIN_NVIM_VERSION) then
    h.ok(('Neovim %s (required >= %s)'):format(current_version, minimum))
  else
    h.error(('Neovim %s is too old; ts-pack requires >= %s'):format(current_version, minimum))
  end

  if type(vim.system) == 'function' then
    h.ok('vim.system is available')
  else
    h.error('vim.system is not available; parser installation cannot run subprocesses')
  end
end

local function report_treesitter_runtime()
  local h = health()
  if not vim.treesitter or vim.treesitter.language_version == nil then
    h.error('Neovim Tree-sitter runtime ABI is unavailable')
    return
  end

  local language_version = tostring(vim.treesitter.language_version)
  local minimum = vim.treesitter.minimum_language_version
  if minimum then
    h.ok(
      ('Neovim Tree-sitter runtime ABI: %s (minimum parser ABI: %s)'):format(
        language_version,
        minimum
      )
    )
  else
    h.ok(('Neovim Tree-sitter runtime ABI: %s'):format(language_version))
  end
end

local function report_os()
  if not uv or type(uv.os_uname) ~= 'function' then
    return
  end

  local ok, osinfo = pcall(uv.os_uname)
  if not ok or type(osinfo) ~= 'table' then
    return
  end

  health().info(
    ('OS: %s %s %s'):format(
      osinfo.sysname or '<unknown>',
      osinfo.release or '<unknown>',
      osinfo.machine or '<unknown>'
    )
  )
end

local function check_requirements(active)
  local h = health()
  h.start('ts-pack: requirements')

  report_neovim()
  report_treesitter_runtime()
  report_os()

  report_command('git', 'git', 'git not found; remote parser installs require git')

  local tree_sitter_required_names = active_tree_sitter_required_names(active)
  local tree_sitter_missing_message =
    'tree-sitter CLI not found; parser generation and primary builds are unavailable'
  if #tree_sitter_required_names > 0 then
    tree_sitter_missing_message = tree_sitter_missing_message
      .. ('; required by active parser specs: %s'):format(
        table.concat(tree_sitter_required_names, ', ')
      )
  end
  report_command(
    'tree-sitter',
    'tree-sitter',
    tree_sitter_missing_message,
    #tree_sitter_required_names > 0 and 'error' or 'warn'
  )

  local cc = env_or('CC', 'cc')
  report_command(
    'C compiler',
    cc,
    ('C compiler `%s` not found; parser compilation requires `CC` or `cc`'):format(cc)
  )

  local cxx = env_or('CXX', 'c++')
  local scanner_names = active_cpp_scanner_names(active)
  local cxx_missing_message = ('C++ compiler `%s` not found; parsers with `scanner.cc` require `CXX` or `c++`'):format(
    cxx
  )
  if #scanner_names > 0 then
    cxx_missing_message = cxx_missing_message
      .. ('; required by active parser specs: %s'):format(table.concat(scanner_names, ', '))
  end
  report_command('C++ compiler', cxx, cxx_missing_message, #scanner_names > 0 and 'error' or 'warn')
end

local function read_lock()
  local lockfile = path.lockfile()
  if not exists(lockfile) then
    return nil, nil
  end

  local lines = vim.fn.readfile(lockfile)
  local ok, lock = pcall(vim.json.decode, table.concat(lines, '\n'))
  if not ok or type(lock) ~= 'table' then
    return nil, ('Lockfile is not valid JSON: %s'):format(lockfile)
  end
  if type(lock.parsers) ~= 'table' then
    return nil, ('Lockfile does not contain a valid `parsers` table: %s'):format(lockfile)
  end
  return lock, nil
end

local function installed_parsers()
  local result = {}
  local parser_dir = path.parser_dir()
  if not exists(parser_dir) then
    return result
  end

  for name, type_ in vim.fs.dir(parser_dir) do
    if type_ == 'file' then
      local parser = name:match('^(.+)%.so$')
      if parser then
        result[parser] = true
      end
    end
  end

  return result
end

local function active_parsers()
  local result = {}
  local ok, ts_pack = pcall(require, 'ts-pack')
  if not ok then
    return result
  end

  for _, item in ipairs(ts_pack.get(nil, { info = false })) do
    if item.spec and item.spec.name then
      result[item.spec.name] = item
    end
  end

  return result
end

local function query_files_from_dir(root)
  local result = {}
  if not exists(root) then
    return result
  end

  for lang, type_ in vim.fs.dir(root) do
    if type_ == 'directory' then
      local lang_dir = path.join(root, lang)
      for file, file_type in vim.fs.dir(lang_dir) do
        local query_type = file_type == 'file' and file:match('^(.+)%.scm$') or nil
        if query_type then
          result[lang] = result[lang] or {}
          result[lang][query_type] = result[lang][query_type] or {}
          result[lang][query_type][#result[lang][query_type] + 1] = path.join(lang_dir, file)
        end
      end
    end
  end

  return result
end

local function runtime_query_files()
  local result = {}
  local files = vim.api.nvim_get_runtime_file('queries/**/*.scm', true)

  for _, file in ipairs(files) do
    local lang, query_type = file:match('/queries/([^/]+)/([^/]+)%.scm$')
    if lang and query_type then
      result[lang] = result[lang] or {}
      result[lang][query_type] = result[lang][query_type] or {}
      result[lang][query_type][#result[lang][query_type] + 1] = file
    end
  end

  return result
end

local function unique_dirs(files)
  local seen = {}
  local result = {}

  for _, file in ipairs(files) do
    local dir = vim.fs.dirname(file)
    if not seen[dir] then
      seen[dir] = true
      result[#result + 1] = dir
    end
  end

  table.sort(result)
  return result
end

local function has_query_files(queries)
  for _, groups in pairs(queries) do
    for _, files in pairs(groups) do
      if #files > 0 then
        return true
      end
    end
  end
  return false
end

local function report_query_group(title, queries)
  local h = health()
  h.start(title)

  local langs = sorted_keys(queries)
  if #langs == 0 then
    h.info('No queries found')
    return
  end

  for _, lang in ipairs(langs) do
    local types = sorted_keys(queries[lang])
    local parts = {}
    for _, query_type in ipairs(types) do
      local dirs = unique_dirs(queries[lang][query_type])
      parts[#parts + 1] = ('%s (%s)'):format(query_type, table.concat(dirs, ', '))
    end
    h.ok(('%s: %s'):format(lang, table.concat(parts, ', ')))
  end
end

local function nearest_existing_path(target)
  local current = target
  while current and current ~= '' do
    if exists(current) then
      return current
    end

    local parent = vim.fs.dirname(current)
    if not parent or parent == current then
      return nil
    end
    current = parent
  end
  return nil
end

local function writable_target(target, is_file)
  local check = target
  local stat = uv.fs_stat(target)
  if is_file or not stat or stat.type ~= 'directory' then
    check = vim.fs.dirname(target)
  end

  local existing = nearest_existing_path(check)
  if not existing then
    return false, check
  end
  return uv.fs_access(existing, 'W') == true, existing
end

local function report_writable_path(label, target, opts)
  opts = opts or {}

  local h = health()
  h.info(('%s: %s'):format(label, target))

  local ok, checked = writable_target(target, opts.file)
  local message = ('%s is writable or creatable (checked %s)'):format(label, checked)
  if ok then
    h.ok(message)
  else
    h.error(message:gsub(' is writable or creatable ', ' is not writable or creatable '))
  end
end

local function normalize_path(target)
  local ok, normalized = pcall(vim.fs.normalize, target)
  if ok then
    return normalized
  end
  return target
end

local function site_dir_in_runtimepath()
  local site_dir = normalize_path(path.default_site_dir())
  for _, runtime_path in ipairs(vim.api.nvim_list_runtime_paths()) do
    if normalize_path(runtime_path) == site_dir then
      return true
    end
  end
  return false
end

local function check_paths()
  local h = health()
  h.start('ts-pack: paths')
  h.info('Default site directory: ' .. path.default_site_dir())
  if site_dir_in_runtimepath() then
    h.ok('Default site directory is in runtimepath')
  else
    h.warn(
      'Default site directory is not in runtimepath; installed parsers and queries may not load'
    )
  end

  report_writable_path('Parser directory', path.parser_dir())
  report_writable_path('Parser info directory', path.parser_info_dir())
  report_writable_path('Query directory', path.queries_dir())
  report_writable_path('Lockfile', path.lockfile(), { file = true })
  report_writable_path('Cache directory', path.cache_dir())
end

local function check_parsers(lock, lock_error, active)
  local h = health()
  h.start('ts-pack: parsers')

  if lock_error then
    h.error(lock_error)
  elseif not lock then
    h.info('Lockfile is absent')
  end

  local installed = installed_parsers()
  local names = {}

  for name in pairs(installed) do
    names[name] = true
  end
  for name in pairs(active) do
    names[name] = true
  end
  if lock and lock.parsers then
    for name in pairs(lock.parsers) do
      names[name] = true
    end
  end

  local sorted = sorted_keys(names)
  if #sorted == 0 then
    h.info('No parsers found')
    return
  end

  for _, name in ipairs(sorted) do
    local parser_path = path.parser_path(name)
    local revision_path = path.parser_revision_path(name)
    local local_rev = read_first_line(revision_path)
    local lock_entry = lock and lock.parsers[name] or nil
    local lock_rev = lock_entry and lock_entry.rev or nil
    local is_installed = installed[name] == true
    local is_active = active[name] ~= nil
    local status = {
      is_installed and 'installed' or 'missing',
      is_active and 'active' or 'inactive',
    }
    local message = ('%s: %s, path: %s, local rev: %s, lockfile rev: %s'):format(
      name,
      table.concat(status, ', '),
      parser_path,
      local_rev or '<none>',
      lock_rev or '<none>'
    )

    if lock_entry and not is_installed then
      h.warn(message .. ' (present in lockfile but missing on disk)')
    elseif is_installed and not local_rev then
      h.warn(message .. ' (missing parser-info revision)')
    elseif is_installed and not lock_entry then
      h.warn(message .. ' (installed but missing from lockfile)')
    elseif local_rev and lock_rev and local_rev ~= lock_rev then
      h.warn(message .. ' (local revision differs from lockfile)')
    else
      h.ok(message)
    end
  end
end

local function check_query_parse(queries)
  local h = health()
  h.start('ts-pack: query parse')

  if not has_query_files(queries) then
    h.info('No managed queries to parse')
    return
  end

  local ok, query_module = pcall(require, 'ts-pack.queries')
  if ok then
    query_module.register_predicates()
  end

  local parsed_count = 0
  local error_count = 0

  for _, lang in ipairs(sorted_keys(queries)) do
    local loaded_ok, loaded = pcall(vim.treesitter.language.add, lang)
    if not loaded_ok or not loaded then
      h.info(('Skipping `%s` query parse: parser not loadable'):format(lang))
    else
      for _, query_type in ipairs(sorted_keys(queries[lang])) do
        local files = vim.deepcopy(queries[lang][query_type])
        table.sort(files)
        for _, file in ipairs(files) do
          local read_ok, lines = pcall(vim.fn.readfile, file)
          if not read_ok then
            error_count = error_count + 1
            h.error(('%s/%s (%s): %s'):format(lang, query_type, file, lines))
          else
            local source = table.concat(lines, '\n')
            local parse_ok, err = pcall(vim.treesitter.query.parse, lang, source)
            if parse_ok then
              parsed_count = parsed_count + 1
            else
              error_count = error_count + 1
              h.error(('%s/%s (%s): %s'):format(lang, query_type, file, err))
            end
          end
        end
      end
    end
  end

  if parsed_count > 0 and error_count == 0 then
    local suffix = parsed_count == 1 and '' or 's'
    h.ok(('Parsed %d managed query file%s'):format(parsed_count, suffix))
  end
end

local function check_query_coverage(queries, lock)
  local h = health()
  local names = {}

  for name in pairs(installed_parsers()) do
    names[name] = true
  end
  if lock and lock.parsers then
    for name in pairs(lock.parsers) do
      names[name] = true
    end
  end

  for _, name in ipairs(sorted_keys(names)) do
    if not queries[name] then
      h.info(('No ts-pack-managed queries for parser `%s`'):format(name))
    end
  end
end

function M.check()
  local lock, lock_error = read_lock()
  local active = active_parsers()

  check_requirements(active)
  check_paths()
  check_parsers(lock, lock_error, active)

  local managed_queries = query_files_from_dir(path.queries_dir())
  report_query_group('ts-pack: queries', managed_queries)
  check_query_coverage(managed_queries, lock)
  check_query_parse(managed_queries)

  report_query_group('ts-pack: runtime queries', runtime_query_files())
end

return M
