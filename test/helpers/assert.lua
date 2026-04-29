local lua_assert = _G.assert

local M = {}

local function stringify(value, seen)
  if type(value) ~= 'table' then
    return vim.inspect(value)
  end

  seen = seen or {}
  if seen[value] then
    return '<cycle>'
  end
  seen[value] = true

  local parts = {}
  for key, item in pairs(value) do
    table.insert(parts, ('%s = %s'):format(stringify(key, seen), stringify(item, seen)))
  end
  table.sort(parts)

  seen[value] = nil
  return '{ ' .. table.concat(parts, ', ') .. ' }'
end

local function fail(message, level)
  error(message, (level or 1) + 1)
end

local function same(left, right, seen)
  if left == right then
    return true
  end

  if type(left) ~= 'table' or type(right) ~= 'table' then
    return false
  end

  seen = seen or {}
  seen[left] = seen[left] or {}
  if seen[left][right] then
    return true
  end
  seen[left][right] = true

  for key, value in pairs(left) do
    if not same(value, right[key], seen) then
      return false
    end
  end

  for key in pairs(right) do
    if left[key] == nil then
      return false
    end
  end

  return true
end

function M.equals(expected, actual, message)
  if expected ~= actual then
    fail(message or ('expected %s, got %s'):format(stringify(expected), stringify(actual)), 2)
  end
end

function M.same(expected, actual, message)
  if not same(expected, actual) then
    fail(message or ('expected %s, got %s'):format(stringify(expected), stringify(actual)), 2)
  end
end

function M.truthy(value, message)
  if not value then
    fail(message or ('expected truthy value, got %s'):format(stringify(value)), 2)
  end
end

function M.falsy(value, message)
  if value then
    fail(message or ('expected falsy value, got %s'):format(stringify(value)), 2)
  end
end

function M.matches(pattern, value, message)
  if type(value) ~= 'string' or not value:match(pattern) then
    fail(message or ('expected %s to match %s'):format(stringify(value), stringify(pattern)), 2)
  end
end

function M.error_matches(pattern, fn, message)
  local ok, err = pcall(fn)
  if ok then
    fail(message or 'expected function to error', 2)
  end

  if not tostring(err):match(pattern) then
    fail(message or ('expected error %s to match %s'):format(stringify(err), stringify(pattern)), 2)
  end
end

return setmetatable(M, {
  __call = function(_, condition, message)
    return lua_assert(condition, message)
  end,
})
