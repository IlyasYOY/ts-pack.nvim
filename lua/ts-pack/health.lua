local M = {}

local path = require('ts-pack.path')

local uv = vim.uv or vim.loop

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
          result[lang][query_type][#result[lang][query_type] + 1] = lang_dir
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
      result[lang][query_type][#result[lang][query_type] + 1] = vim.fs.dirname(file)
    end
  end

  return result
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
      local dirs = queries[lang][query_type]
      table.sort(dirs)
      parts[#parts + 1] = ('%s (%s)'):format(query_type, table.concat(dirs, ', '))
    end
    h.ok(('%s: %s'):format(lang, table.concat(parts, ', ')))
  end
end

local function check_paths()
  local h = health()
  h.start('ts-pack: paths')
  h.info('Parser directory: ' .. path.parser_dir())
  h.info('Parser info directory: ' .. path.parser_info_dir())
  h.info('Query directory: ' .. path.queries_dir())
  h.info('Lockfile: ' .. path.lockfile())
  h.info('Cache directory: ' .. path.cache_dir())
end

local function check_parsers(lock, lock_error)
  local h = health()
  h.start('ts-pack: parsers')

  if lock_error then
    h.error(lock_error)
  elseif not lock then
    h.info('Lockfile is absent')
  end

  local installed = installed_parsers()
  local active = active_parsers()
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

  check_paths()
  check_parsers(lock, lock_error)

  local managed_queries = query_files_from_dir(path.queries_dir())
  report_query_group('ts-pack: queries', managed_queries)
  check_query_coverage(managed_queries, lock)

  report_query_group('ts-pack: runtime queries', runtime_query_files())
end

return M
