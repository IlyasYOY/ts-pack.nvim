local M = {}

local uv = vim.uv or vim.loop
local path = require('ts-pack.path')

function M.ensure_dir(target)
  vim.fn.mkdir(target, 'p')
end

function M.exists(target)
  return uv.fs_stat(target) ~= nil
end

function M.read_json(target, fallback)
  if not M.exists(target) then
    return fallback
  end

  local data = vim.fn.readfile(target)
  if #data == 0 then
    return fallback
  end

  local ok, parsed = pcall(vim.json.decode, table.concat(data, '\n'))
  if not ok or type(parsed) ~= 'table' then
    return fallback
  end

  return parsed
end

local function sorted_keys(value)
  local keys = vim.tbl_keys(value)
  table.sort(keys, function(a, b)
    return tostring(a) < tostring(b)
  end)
  return keys
end

local function is_array(value)
  local count = 0
  for key in pairs(value) do
    if type(key) ~= 'number' or key < 1 or key % 1 ~= 0 then
      return false
    end
    count = count + 1
  end
  return count == #value
end

local function encode_json(value, level)
  if type(value) ~= 'table' then
    return vim.json.encode(value)
  end

  local keys = (is_array(value) and #value > 0) and nil or sorted_keys(value)
  local count = keys and #keys or #value
  if count == 0 then
    return keys and '{}' or '[]'
  end

  local indent = string.rep('  ', level)
  local child_indent = indent .. '  '
  local lines = { keys and '{' or '[' }

  for index = 1, count do
    local key = keys and keys[index] or index
    local item = child_indent
    if keys then
      item = item .. vim.json.encode(tostring(key)) .. ': '
    end
    item = item .. encode_json(value[key], level + 1)
    if index < count then
      item = item .. ','
    end
    lines[#lines + 1] = item
  end

  lines[#lines + 1] = indent .. (keys and '}' or ']')
  return table.concat(lines, '\n')
end

function M.write_json(target, value)
  M.ensure_dir(vim.fs.dirname(target))
  local encoded = encode_json(value, 0)
  vim.fn.writefile(vim.split(encoded, '\n'), target)
end

function M.load_lock()
  local lock = M.read_json(path.lockfile(), { parsers = {} })
  if type(lock.parsers) ~= 'table' then
    lock.parsers = {}
  end
  return lock
end

function M.save_lock(lock)
  M.write_json(path.lockfile(), lock)
end

function M.copy_file(src, dst)
  M.ensure_dir(vim.fs.dirname(dst))
  local tmp = dst .. '.tmp'
  vim.fn.delete(tmp)
  local ok, err = uv.fs_copyfile(src, tmp)
  if not ok then
    error(('failed to copy `%s` to `%s`: %s'):format(src, dst, err or 'unknown error'), 0)
  end
  vim.fn.rename(tmp, dst)
end

function M.copy_tree(src, dst)
  if not M.exists(src) then
    error(('query source does not exist: %s'):format(src), 0)
  end

  vim.fn.delete(dst, 'rf')
  M.ensure_dir(dst)
  for name, type_ in vim.fs.dir(src) do
    local from = path.join(src, name)
    local to = path.join(dst, name)
    if type_ == 'directory' then
      M.copy_tree(from, to)
    elseif type_ == 'file' then
      M.copy_file(from, to)
    end
  end
end

return M
