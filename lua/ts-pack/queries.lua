local M = {}

local fs = require('ts-pack.fs')
local path = require('ts-pack.path')

local registered_predicates = false
local bundled

local function module_dir()
  local source = debug.getinfo(1, 'S').source:gsub('^@', '')
  return vim.fs.dirname(source)
end

local function bundled_root()
  return path.join(module_dir(), 'bundled_queries')
end

local function bundled_dirs()
  if bundled then
    return bundled
  end

  bundled = {}
  for name, type_ in vim.fs.dir(bundled_root()) do
    if type_ == 'directory' then
      bundled[name] = true
    end
  end
  return bundled
end

function M.has_bundled(name)
  return bundled_dirs()[name] == true
end

function M.bundled_path(name)
  if not M.has_bundled(name) then
    return nil
  end
  return path.join(bundled_root(), name)
end

local function kind_eq(match, pred, any)
  local nodes = match[pred[2]]
  if not nodes or #nodes == 0 then
    return true
  end

  local types = { unpack(pred, 3) }
  for _, node in ipairs(nodes) do
    local res = vim.list_contains(types, node:type())
    if any and res then
      return true
    elseif not any and not res then
      return false
    end
  end
  return not any
end

function M.register_predicates()
  if registered_predicates then
    return
  end

  local query = vim.treesitter.query
  query.add_predicate('kind-eq?', function(match, _, _, pred)
    return kind_eq(match, pred, false)
  end, { force = true })

  query.add_predicate('any-kind-eq?', function(match, _, _, pred)
    return kind_eq(match, pred, true)
  end, { force = true })

  registered_predicates = true
end

local function selected_query_files(src, filter)
  if not fs.exists(src) then
    error(('query source does not exist: %s'):format(src), 0)
  end

  local files = {}

  for name, type_ in vim.fs.dir(src) do
    local query_type = type_ == 'file' and name:match('^(.+)%.scm$')
    if query_type and (filter == true or filter[query_type] == true) then
      files[#files + 1] = {
        name = name,
        path = path.join(src, name),
      }
    end
  end

  table.sort(files, function(a, b)
    return a.name < b.name
  end)

  return files
end

local function copy_query_files(files, dst)
  vim.fn.delete(dst, 'rf')
  if #files == 0 then
    return
  end

  fs.ensure_dir(dst)
  for _, file in ipairs(files) do
    fs.copy_file(file.path, path.join(dst, file.name))
  end
end

local function inherited_languages(file)
  local first = vim.fn.readfile(file, '', 1)[1]
  local inherited = first and first:match('^;%s*inherits:%s*(.+)$')
  if not inherited then
    return {}
  end

  local result = {}
  for lang in inherited:gmatch('[^,%s]+') do
    result[#result + 1] = lang
  end
  return result
end

function M.materialize(spec, source_root, opts)
  if not spec.queries then
    return
  end

  local src = spec.queries
  local filter
  if type(spec.queries) == 'table' then
    src = spec.queries.path
    filter = spec.queries.filter
  end

  if not vim.startswith(src, '/') then
    src = path.join(source_root, src)
  end

  local dst = path.query_path(spec.name, opts)
  if filter then
    copy_query_files(selected_query_files(src, filter), dst)
  else
    fs.copy_tree(src, dst)
  end
end

function M.materialize_bundled(spec, opts)
  if not spec.bundled_queries then
    return
  end

  local filter = spec.bundled_queries
  local seen = {}

  local function materialize(name)
    if seen[name] then
      return
    end
    seen[name] = true

    local src = M.bundled_path(name)
    if not src then
      return
    end

    local files = selected_query_files(src, filter)

    if filter == true then
      M.register_predicates()
      fs.copy_tree(src, path.query_path(name, opts))
    else
      if #files > 0 then
        M.register_predicates()
      end
      copy_query_files(files, path.query_path(name, opts))
    end

    for _, file in ipairs(files) do
      for _, lang in ipairs(inherited_languages(file.path)) do
        materialize(lang)
      end
    end
  end

  materialize(spec.name)
end

return M
