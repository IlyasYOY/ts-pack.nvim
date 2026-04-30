local M = {}

local uv = vim.uv or vim.loop

local active = {}
local active_order = {}

local function joinpath(...)
  return vim.fs.joinpath(...)
end

local function is_list(value)
  return type(value) == 'table' and vim.islist(value)
end

local function assert_list(name, value)
  if not is_list(value) then
    error(('`%s` must be a list'):format(name), 3)
  end
end

local function default_site_dir()
  return joinpath(vim.fn.stdpath('data'), 'site')
end

local function cache_dir()
  return joinpath(vim.fn.stdpath('cache'), 'ts-pack')
end

local function lockfile_path()
  return joinpath(vim.fn.stdpath('config'), 'ts-pack-lock.json')
end

local function parser_dir(opts)
  return joinpath((opts and opts.dir) or default_site_dir(), 'parser')
end

local function parser_info_dir(opts)
  return joinpath((opts and opts.dir) or default_site_dir(), 'parser-info')
end

local function queries_dir(opts)
  return joinpath((opts and opts.dir) or default_site_dir(), 'queries')
end

local function ensure_dir(path)
  vim.fn.mkdir(path, 'p')
end

local function path_exists(path)
  return uv.fs_stat(path) ~= nil
end

local function basename(src)
  local name = src:gsub('%.git$', '')
  name = name:match('[^/]+$') or name
  return name:gsub('^tree%-sitter%-', '')
end

local function shell_error(cmd, cwd, result)
  local where = cwd and (' in ' .. cwd) or ''
  local stderr = result.stderr and vim.trim(result.stderr) or ''
  local stdout = result.stdout and vim.trim(result.stdout) or ''
  local detail = stderr ~= '' and stderr or stdout
  if detail ~= '' then
    detail = ': ' .. detail
  end
  return ('command failed%s: %s%s'):format(where, table.concat(cmd, ' '), detail)
end

local function system(cmd, opts)
  opts = opts or {}
  local result = vim.system(cmd, { cwd = opts.cwd, text = true, env = opts.env }):wait()
  if result.code ~= 0 then
    error(shell_error(cmd, opts.cwd, result), 0)
  end
  return result
end

local function system_result(cmd, opts)
  opts = opts or {}
  return vim.system(cmd, { cwd = opts.cwd, text = true, env = opts.env }):wait()
end

local function git(args, cwd)
  local cmd = { 'git' }
  vim.list_extend(cmd, args)
  return system(cmd, { cwd = cwd })
end

local function read_json(path, fallback)
  if not path_exists(path) then
    return fallback
  end

  local data = vim.fn.readfile(path)
  if #data == 0 then
    return fallback
  end

  local ok, parsed = pcall(vim.json.decode, table.concat(data, '\n'))
  if not ok or type(parsed) ~= 'table' then
    return fallback
  end

  return parsed
end

local function write_json(path, value)
  ensure_dir(vim.fs.dirname(path))
  local encoded = vim.json.encode(value)
  vim.fn.writefile(vim.split(encoded, '\n'), path)
end

local function load_lock()
  local lock = read_json(lockfile_path(), { parsers = {} })
  if type(lock.parsers) ~= 'table' then
    lock.parsers = {}
  end
  return lock
end

local function save_lock(lock)
  write_json(lockfile_path(), lock)
end

local function normalize_spec(spec)
  if type(spec) == 'string' then
    spec = { src = spec }
  end

  vim.validate('spec', spec, 'table')
  vim.validate('spec.src', spec.src, 'string')

  local name = spec.name or basename(spec.src)
  vim.validate('spec.name', name, 'string')
  if name == '' then
    error('`spec.name` must be a non-empty string', 3)
  end

  return {
    src = spec.src,
    name = name,
    version = spec.version,
    data = spec.data,
    location = spec.location,
    path = spec.path,
    queries = spec.queries,
    generate = spec.generate,
    generate_from_json = spec.generate_from_json,
  }
end

local function normalize_specs(specs)
  assert_list('specs', specs)

  local normalized = {}
  local seen = {}
  for _, spec in ipairs(specs) do
    local parser = normalize_spec(spec)
    local existing = seen[parser.name]
    if existing then
      if existing.src ~= parser.src then
        error(('conflicting `src` for parser `%s`'):format(parser.name), 2)
      end
      if existing.version ~= parser.version then
        error(('conflicting `version` for parser `%s`'):format(parser.name), 2)
      end
    else
      seen[parser.name] = parser
      normalized[#normalized + 1] = parser
    end
  end

  return normalized
end

local function normalize_names(names)
  if names == nil then
    local result = vim.deepcopy(active_order)
    table.sort(result)
    return result
  end

  assert_list('names', names)

  local result = {}
  for _, name in ipairs(names) do
    vim.validate('name', name, 'string')
    result[#result + 1] = name
  end
  return result
end

local function remember_spec(spec)
  if not active[spec.name] then
    active_order[#active_order + 1] = spec.name
  end
  active[spec.name] = vim.deepcopy(spec)
end

local function checkout_path(spec)
  return joinpath(cache_dir(), spec.name)
end

local function current_rev(path)
  return vim.trim(git({ 'rev-parse', 'HEAD' }, path).stdout or '')
end

local function resolve_ref(spec, lock_entry, opts)
  if opts and opts.target == 'version' then
    return spec.version
  end

  if lock_entry and lock_entry.rev then
    return lock_entry.rev
  end

  return spec.version
end

local function ensure_checkout(spec, ref, opts)
  if spec.path then
    return spec.path
  end

  local path = checkout_path(spec)
  ensure_dir(cache_dir())

  if not path_exists(path) then
    if opts and opts.offline then
      error(('parser `%s` is not checked out and `offline` is set'):format(spec.name), 0)
    end
    git({ 'clone', '--filter=blob:none', spec.src, path })
  elseif not (opts and opts.offline) then
    git({ 'fetch', '--tags', '--force' }, path)
  end

  if ref and ref ~= '' then
    git({ 'checkout', '--detach', ref }, path)
  end

  return path
end

local function generate_parser(spec, root)
  if not spec.generate then
    return
  end

  local source = spec.generate_from_json == false and 'src/grammar.js' or 'src/grammar.json'
  system({
    'tree-sitter',
    'generate',
    '--abi',
    tostring(vim.treesitter.language_version),
    source,
  }, { cwd = root, env = { TREE_SITTER_JS_RUNTIME = 'native' } })
end

local function compile_parser(root)
  local result = system_result({ 'tree-sitter', 'build', '-o', 'parser.so' }, { cwd = root })
  if result.code == 0 then
    return
  end

  local parser_c = joinpath(root, 'src', 'parser.c')
  if not path_exists(parser_c) then
    error(shell_error({ 'tree-sitter', 'build', '-o', 'parser.so' }, root, result), 0)
  end

  local cmd = { 'cc', '-fPIC', '-I', 'src', '-o', 'parser.so' }
  if vim.fn.has('mac') == 1 then
    cmd[#cmd + 1] = '-dynamiclib'
  else
    cmd[#cmd + 1] = '-shared'
  end

  cmd[#cmd + 1] = 'src/parser.c'
  if path_exists(joinpath(root, 'src', 'scanner.c')) then
    cmd[#cmd + 1] = 'src/scanner.c'
  end
  if path_exists(joinpath(root, 'src', 'scanner.cc')) then
    cmd[#cmd + 1] = 'src/scanner.cc'
  end

  system(cmd, { cwd = root })
end

local function copy_file(src, dst)
  ensure_dir(vim.fs.dirname(dst))
  local tmp = dst .. '.tmp'
  vim.fn.delete(tmp)
  local ok, err = uv.fs_copyfile(src, tmp)
  if not ok then
    error(('failed to copy `%s` to `%s`: %s'):format(src, dst, err or 'unknown error'), 0)
  end
  vim.fn.rename(tmp, dst)
end

local function copy_tree(src, dst)
  if not path_exists(src) then
    error(('query source does not exist: %s'):format(src), 0)
  end

  vim.fn.delete(dst, 'rf')
  ensure_dir(dst)
  for name, type_ in vim.fs.dir(src) do
    local from = joinpath(src, name)
    local to = joinpath(dst, name)
    if type_ == 'directory' then
      copy_tree(from, to)
    elseif type_ == 'file' then
      copy_file(from, to)
    end
  end
end

local function materialize_queries(spec, source_root, opts)
  if not spec.queries then
    return
  end

  local src = spec.queries
  if not vim.startswith(src, '/') then
    src = joinpath(source_root, src)
  end

  copy_tree(src, joinpath(queries_dir(opts), spec.name))
end

local function install_parser(spec, opts)
  opts = opts or {}

  local lock = load_lock()
  local lock_entry = lock.parsers[spec.name]
  local ref = opts.target == 'lockfile' and lock_entry and lock_entry.rev
    or resolve_ref(spec, lock_entry, opts)

  local source_root = ensure_checkout(spec, ref, opts)
  local build_root = source_root
  if spec.location then
    build_root = joinpath(build_root, spec.location)
  end

  generate_parser(spec, build_root)
  compile_parser(build_root)

  local rev = spec.path and (ref or spec.version or 'local') or current_rev(source_root)
  local parser_path = joinpath(parser_dir(opts), spec.name .. '.so')
  copy_file(joinpath(build_root, 'parser.so'), parser_path)
  materialize_queries(spec, source_root, opts)

  ensure_dir(parser_info_dir(opts))
  vim.fn.writefile({ rev }, joinpath(parser_info_dir(opts), spec.name .. '.revision'))

  lock.parsers[spec.name] = {
    src = spec.src,
    rev = rev,
    version = spec.version,
    data = spec.data,
  }
  save_lock(lock)

  return {
    active = true,
    path = parser_path,
    rev = rev,
    spec = vim.deepcopy(spec),
  }
end

local function installed_rev(name, opts)
  local path = joinpath(parser_info_dir(opts), name .. '.revision')
  if not path_exists(path) then
    return nil
  end
  local lines = vim.fn.readfile(path)
  return lines[1]
end

local function info_for(name, opts)
  local spec = active[name]
  local parser_path = joinpath(parser_dir(opts), name .. '.so')
  local rev = installed_rev(name, opts)

  return {
    active = spec ~= nil,
    path = parser_path,
    rev = rev,
    spec = spec and vim.deepcopy(spec) or nil,
  }
end

local function add_info(result, name)
  local lock = load_lock()
  local entry = lock.parsers[name]
  if entry then
    result.src = entry.src
    result.version = entry.version
    result.data = entry.data
  end
  result.installed = path_exists(result.path)
  return result
end

function M.add(specs, opts)
  opts = opts or {}
  local result = {}

  for _, spec in ipairs(normalize_specs(specs)) do
    remember_spec(spec)
    local lock_entry = load_lock().parsers[spec.name]
    local installed = path_exists(joinpath(parser_dir(opts), spec.name .. '.so'))
    if installed and lock_entry and not opts.force and not opts.target then
      local item = info_for(spec.name, opts)
      item.spec = vim.deepcopy(spec)
      result[#result + 1] = add_info(item, spec.name)
    else
      result[#result + 1] = install_parser(spec, opts)
    end
  end

  return result
end

function M.del(names, opts)
  opts = opts or {}
  local result = {}
  local lock = load_lock()

  for _, name in ipairs(normalize_names(names)) do
    vim.fn.delete(joinpath(parser_dir(opts), name .. '.so'))
    vim.fn.delete(joinpath(parser_info_dir(opts), name .. '.revision'))
    vim.fn.delete(joinpath(queries_dir(opts), name), 'rf')
    lock.parsers[name] = nil
    active[name] = nil
    result[#result + 1] = { name = name, deleted = true }
  end

  local remaining = {}
  for _, name in ipairs(active_order) do
    if active[name] then
      remaining[#remaining + 1] = name
    end
  end
  active_order = remaining

  save_lock(lock)
  return result
end

function M.get(names, opts)
  opts = opts or {}
  local result = {}

  for _, name in ipairs(normalize_names(names)) do
    local item = info_for(name, opts)
    if opts.info ~= false then
      add_info(item, name)
    end
    result[#result + 1] = item
  end

  return result
end

function M.update(names, opts)
  opts = opts or {}
  local result = {}

  for _, name in ipairs(normalize_names(names)) do
    local spec = active[name]
    if not spec then
      error(('parser `%s` is not active; call add() with a full spec first'):format(name), 2)
    end
    result[#result + 1] = install_parser(spec, opts)
  end

  return result
end

return M
