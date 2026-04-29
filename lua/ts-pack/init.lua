local M = {}

local git = require('ts-pack.git')
local uv = vim.uv or vim.loop

---@class ParserSpec
---@field id string
---@field src string?
---@field version string?
---@field location string?
---@field queries string?
---@field generate boolean?

local state = {
  config = nil,
  lock = nil,
  loaded = false,
  active = {},
  did_sync = false,
}

local function join(...)
  local path = table.concat({ ... }, '/'):gsub('/+', '/')
  return path
end

local function exists(path)
  return uv.fs_stat(path) ~= nil
end

local function is_dir(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == 'directory'
end

local function mkdir(path)
  vim.fn.mkdir(path, 'p')
end

local function rm(path)
  if exists(path) then
    vim.fn.delete(path, 'rf')
  end
end

local function write_file(path, contents)
  mkdir(vim.fn.fnamemodify(path, ':h'))
  vim.fn.writefile(vim.split(contents, '\n', { plain = true }), path)
end

local function read_file(path)
  return table.concat(vim.fn.readfile(path), '\n')
end

local function run(argv, opts)
  opts = opts or {}
  local result = vim
    .system(argv, {
      cwd = opts.cwd,
      text = true,
    })
    :wait()

  if result.code ~= 0 then
    local output = vim.trim((result.stderr or '') .. '\n' .. (result.stdout or ''))
    error(('ts-pack: command failed: %s\n%s'):format(table.concat(argv, ' '), output))
  end

  return vim.trim(result.stdout or '')
end

local function parser_ext()
  if vim.fn.has('win32') == 1 then
    return 'dll'
  end
  return 'so'
end

local function copy_tree(src, dst)
  rm(dst)
  if src and is_dir(src) then
    mkdir(vim.fn.fnamemodify(dst, ':h'))
    vim.fn.system({ 'cp', '-R', src, dst })
    if vim.v.shell_error ~= 0 then
      error(('ts-pack: failed to copy %s to %s'):format(src, dst))
    end
  end
end

local function default_config(opts)
  opts = opts or {}
  local root = opts.root or join(vim.fn.stdpath('data'), 'ts-pack')
  return {
    lockfile = opts.lockfile or join(vim.fn.stdpath('config'), 'ts-pack-lock.json'),
    root = root,
    runtime = opts.runtime or join(root, 'runtime'),
    checkouts = opts.checkouts or join(root, 'checkouts'),
  }
end

local function ensure_runtimepath()
  local runtime = state.config.runtime
  mkdir(join(runtime, 'parser'))
  if not vim.tbl_contains(vim.opt.runtimepath:get(), runtime) then
    vim.opt.runtimepath:prepend(runtime)
  end
end

local function lock_defaults(lock)
  if type(lock) ~= 'table' then
    lock = {}
  end
  lock.parsers = type(lock.parsers) == 'table' and lock.parsers or {}
  return lock
end

local function load_lock()
  if state.loaded then
    return
  end

  state.lock = { parsers = {} }
  if exists(state.config.lockfile) then
    local ok, decoded = pcall(vim.json.decode, read_file(state.config.lockfile))
    if ok then
      state.lock = lock_defaults(decoded)
    else
      error(('ts-pack: failed to decode lockfile %s'):format(state.config.lockfile))
    end
  end

  state.loaded = true
end

local function save_lock()
  mkdir(vim.fn.fnamemodify(state.config.lockfile, ':h'))
  local encoded = vim.json.encode(state.lock)
  write_file(state.config.lockfile, encoded)
end

local function normalize_spec(spec)
  if type(spec) ~= 'table' then
    error('ts-pack: parser spec must be a table')
  end
  if type(spec.id) ~= 'string' or spec.id == '' then
    error('ts-pack: parser spec id must be a non-empty string')
  end
  if spec.src ~= nil and type(spec.src) ~= 'string' then
    error(('ts-pack: spec %s src must be a string'):format(spec.id))
  end
  if spec.version ~= nil and type(spec.version) ~= 'string' then
    error(('ts-pack: spec %s version must be a string'):format(spec.id))
  end
  if spec.location ~= nil and type(spec.location) ~= 'string' then
    error(('ts-pack: spec %s location must be a string'):format(spec.id))
  end
  if spec.queries ~= nil and type(spec.queries) ~= 'string' then
    error(('ts-pack: spec %s queries must be a string'):format(spec.id))
  end

  return {
    id = spec.id,
    src = spec.src,
    version = spec.version,
    location = spec.location,
    queries = spec.queries,
    generate = spec.generate == true,
  }
end

local function normalize_names(names)
  if names == nil then
    return nil
  end
  if type(names) == 'string' then
    return { names }
  end
  if type(names) ~= 'table' then
    error('ts-pack: names must be nil, a string, or a string[]')
  end
  local normalized = {}
  for _, name in ipairs(names) do
    if type(name) ~= 'string' or name == '' then
      error('ts-pack: names must contain only non-empty strings')
    end
    table.insert(normalized, name)
  end
  return normalized
end

local function checkout_path(id)
  return join(state.config.checkouts, id)
end

local function parser_path(id)
  return join(state.config.runtime, 'parser', id .. '.' .. parser_ext())
end

local function queries_path(id)
  return join(state.config.runtime, 'queries', id)
end

local function source_root(id, entry)
  local root = checkout_path(id)
  if entry.location and entry.location ~= '' then
    return join(root, entry.location)
  end
  return root
end

local function ensure_checkout(id, entry)
  local path = checkout_path(id)
  local ok, err = pcall(git.ensure_checkout, path, entry.src, entry.rev or entry.version)
  if not ok then
    error(('ts-pack: parser %s checkout failed: %s'):format(id, err))
  end
end

local function parser_sources(root)
  local src = join(root, 'src')
  local files = { join(src, 'parser.c') }
  for _, name in ipairs({ 'scanner.c', 'scanner.cc', 'scanner.cpp' }) do
    local candidate = join(src, name)
    if exists(candidate) then
      table.insert(files, candidate)
    end
  end
  if not exists(files[1]) then
    error(('ts-pack: missing parser source %s'):format(files[1]))
  end
  return files
end

local function maybe_generate(root, entry)
  if not entry.generate then
    return
  end
  if not exists(join(root, 'grammar.js')) then
    return
  end
  if vim.fn.executable('tree-sitter') ~= 1 then
    error('ts-pack: generate=true requires the tree-sitter CLI')
  end
  run({ 'tree-sitter', 'generate' }, { cwd = root })
end

local function build_parser(id, entry)
  local root = source_root(id, entry)
  maybe_generate(root, entry)

  local out = parser_path(id) .. '.tmp'
  local args = {
    vim.env.CC or 'cc',
    '-O2',
    '-fPIC',
    '-shared',
    '-I',
    join(root, 'src'),
  }
  vim.list_extend(args, parser_sources(root))
  vim.list_extend(args, { '-o', out })

  rm(out)
  mkdir(vim.fn.fnamemodify(out, ':h'))
  run(args)

  local final = parser_path(id)
  rm(final)
  assert(uv.fs_rename(out, final))
  return final
end

local function materialize_queries(id, entry)
  local dst = queries_path(id)
  if not entry.queries then
    rm(dst)
    return
  end
  local src = join(source_root(id, entry), entry.queries)
  if not is_dir(src) then
    error(('ts-pack: missing queries directory %s'):format(src))
  end
  copy_tree(src, dst)
end

local function install_or_update(id, entry, opts)
  opts = opts or {}
  ensure_checkout(id, entry)
  if opts.fetch then
    git.update_checkout(checkout_path(id), entry.version)
  end

  local rev = git.current_rev(checkout_path(id))
  local lock_entry = {
    src = entry.src,
    version = entry.version,
    rev = rev,
    location = entry.location,
    queries = entry.queries,
    generate = entry.generate == true,
  }
  build_parser(id, lock_entry)
  materialize_queries(id, lock_entry)
  state.lock.parsers[id] = lock_entry
  return lock_entry
end

local function entry_matches_spec(entry, spec)
  return entry
    and entry.src == spec.src
    and entry.version == spec.version
    and entry.location == spec.location
    and entry.queries == spec.queries
    and (entry.generate == true) == (spec.generate == true)
end

local function needs_runtime_repair(id, entry)
  if not exists(parser_path(id)) then
    return true
  end
  if entry.queries and not is_dir(queries_path(id)) then
    return true
  end
  return false
end

local function repair_from_lock()
  if state.did_sync then
    return
  end
  state.did_sync = true

  local changed = false
  for id, entry in pairs(state.lock.parsers) do
    if
      entry.src
      and entry.rev
      and (not is_dir(join(checkout_path(id), '.git')) or needs_runtime_repair(id, entry))
    then
      install_or_update(id, entry)
      changed = true
    end
  end
  if changed then
    save_lock()
  end
end

local function ensure_state()
  if not state.config then
    state.config = default_config()
  end
  ensure_runtimepath()
  load_lock()
  repair_from_lock()
end

local function selected_ids(names)
  names = normalize_names(names)
  if names then
    return names
  end
  local ids = {}
  for id in pairs(state.lock.parsers) do
    table.insert(ids, id)
  end
  table.sort(ids)
  return ids
end

---@param opts { lockfile: string?, root: string?, runtime: string?, checkouts: string? }?
function M.setup(opts)
  opts = opts or {}
  if state.config then
    state.config = vim.tbl_deep_extend('force', state.config, opts)
  else
    state.config = default_config(opts)
  end
  ensure_state()
end

---@param specs ParserSpec[]
function M.add(specs)
  ensure_state()
  if type(specs) ~= 'table' then
    error('ts-pack: add() expects a spec[]')
  end

  local changed = false
  for _, raw in ipairs(specs) do
    local spec = normalize_spec(raw)
    local entry = state.lock.parsers[spec.id]
    local effective = {
      id = spec.id,
      src = spec.src or (entry and entry.src),
      version = spec.version,
      location = spec.location,
      queries = spec.queries,
      generate = spec.generate == true,
    }

    state.active[spec.id] = effective

    if
      not entry_matches_spec(entry, effective) or needs_runtime_repair(spec.id, entry or effective)
    then
      install_or_update(spec.id, effective)
      changed = true
    end
  end

  if changed then
    save_lock()
  end
end

---@param names string[]?
function M.get(names)
  ensure_state()
  local result = {}
  for _, id in ipairs(selected_ids(names)) do
    local entry = state.lock.parsers[id]
    if entry then
      table.insert(result, {
        id = id,
        active = state.active[id] ~= nil,
        installed = exists(parser_path(id)),
        path = parser_path(id),
        queries_path = entry.queries and queries_path(id) or nil,
        src = entry.src,
        version = entry.version,
        rev = entry.rev,
        location = entry.location,
        queries = entry.queries,
        generate = entry.generate == true,
      })
    end
  end
  return result
end

---@param names string[]?
function M.del(names)
  ensure_state()
  local ids = selected_ids(names)
  local changed = false
  for _, id in ipairs(ids) do
    if state.active[id] then
      error(
        ('ts-pack: refusing to delete active parser %s; remove it from add() and restart first'):format(
          id
        )
      )
    end
    if state.lock.parsers[id] then
      rm(checkout_path(id))
      rm(parser_path(id))
      rm(queries_path(id))
      state.lock.parsers[id] = nil
      changed = true
    end
  end
  if changed then
    save_lock()
  end
end

---@param names string[]?
function M.update(names)
  ensure_state()
  local changed = false
  for _, id in ipairs(selected_ids(names)) do
    local entry = state.active[id] or state.lock.parsers[id]
    if not entry then
      error(('ts-pack: unknown parser %s'):format(id))
    end
    install_or_update(id, entry, { fetch = true })
    changed = true
  end
  if changed then
    save_lock()
  end
end

return M
