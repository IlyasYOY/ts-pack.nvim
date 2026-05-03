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

function M.materialize_bundled(spec, opts)
  if not spec.bundled_queries then
    return
  end

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

    M.register_predicates()
    fs.copy_tree(src, path.query_path(name, opts))

    for _, file in ipairs(vim.fn.globpath(src, '*.scm', false, true)) do
      local first = vim.fn.readfile(file, '', 1)[1]
      local inherited = first and first:match('^;%s*inherits:%s*(.+)$')
      if inherited then
        for lang in inherited:gmatch('[^,%s]+') do
          materialize(lang)
        end
      end
    end
  end

  materialize(spec.name)
end

return M
