local M = {}

local function is_list(value)
  return type(value) == 'table' and vim.islist(value)
end

function M.assert_list(name, value)
  if not is_list(value) then
    error(('`%s` must be a list'):format(name), 3)
  end
end

function M.basename(src)
  local name = src:gsub('%.git$', '')
  name = name:match('[^/]+$') or name
  return name:gsub('^tree%-sitter%-', '')
end

local function validate_query_filter(name, value)
  if type(value) ~= 'table' then
    error(('`%s` must be a table<string, boolean>'):format(name), 3)
  end

  for key, enabled in pairs(value) do
    if type(key) ~= 'string' then
      error(('`%s` must be a table<string, boolean>'):format(name), 3)
    end
    if type(enabled) ~= 'boolean' then
      error(('`%s` values must be booleans'):format(name), 3)
    end
  end

  return value
end

local function validate_queries(value)
  if value == nil or type(value) == 'string' then
    return value
  end

  if type(value) ~= 'table' then
    error('`spec.queries` must be a string or a table with `path` and `filter`', 3)
  end

  if type(value.path) ~= 'string' or value.path == '' then
    error('`spec.queries.path` must be a non-empty string', 3)
  end

  return {
    path = value.path,
    filter = validate_query_filter('spec.queries.filter', value.filter),
  }
end

local function validate_bundled_queries(value)
  if value == nil or type(value) == 'boolean' then
    return value
  end

  if type(value) ~= 'table' then
    error('`spec.bundled_queries` must be a boolean or a table<string, boolean>', 3)
  end

  return validate_query_filter('spec.bundled_queries', value)
end

function M.normalize_spec(spec)
  if type(spec) == 'string' then
    spec = { src = spec }
  end

  vim.validate('spec', spec, 'table')
  vim.validate('spec.src', spec.src, 'string')

  local name = spec.name or M.basename(spec.src)
  vim.validate('spec.name', name, 'string')
  if name == '' then
    error('`spec.name` must be a non-empty string', 3)
  end

  return {
    src = spec.src,
    name = name,
    version = spec.version,
    data = spec.data,
    branch = spec.branch,
    location = spec.location,
    path = spec.path,
    queries = validate_queries(spec.queries),
    bundled_queries = validate_bundled_queries(spec.bundled_queries),
    generate = spec.generate,
    generate_from_json = spec.generate_from_json,
  }
end

function M.normalize_specs(specs)
  M.assert_list('specs', specs)

  local normalized = {}
  local seen = {}
  for _, item in ipairs(specs) do
    local parser = M.normalize_spec(item)
    local existing = seen[parser.name]
    if existing then
      if existing.src ~= parser.src then
        error(('conflicting `src` for parser `%s`'):format(parser.name), 2)
      end
      if existing.version ~= parser.version then
        error(('conflicting `version` for parser `%s`'):format(parser.name), 2)
      end
      if existing.branch ~= parser.branch then
        error(('conflicting `branch` for parser `%s`'):format(parser.name), 2)
      end
    else
      seen[parser.name] = parser
      normalized[#normalized + 1] = parser
    end
  end

  return normalized
end

return M
