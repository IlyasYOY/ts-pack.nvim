local M = {}

local tests = {}
local before_each_fns = {}
local after_each_fns = {}
local stack = {}

local function fullname(name)
  local parts = vim.deepcopy(stack)
  parts[#parts + 1] = name
  return table.concat(parts, ' ')
end

function _G.describe(name, fn)
  stack[#stack + 1] = name
  fn()
  stack[#stack] = nil
end

function _G.it(name, fn)
  tests[#tests + 1] = { name = fullname(name), fn = fn }
end

function _G.before_each(fn)
  before_each_fns[#before_each_fns + 1] = fn
end

function _G.after_each(fn)
  after_each_fns[#after_each_fns + 1] = fn
end

local native_assert = _G.assert

_G.assert = setmetatable({}, {
  __call = function(_, value, message)
    return native_assert(value, message)
  end,
})

_G.assert.equals = function(expected, actual)
  if expected ~= actual then
    error(('expected %s, got %s'):format(vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

_G.assert.same = function(expected, actual)
  if not vim.deep_equal(expected, actual) then
    error(('expected %s, got %s'):format(vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

_G.assert.truthy = function(value)
  if not value then
    error(('expected truthy value, got %s'):format(vim.inspect(value)), 2)
  end
end

_G.assert.falsy = function(value)
  if value then
    error(('expected falsy value, got %s'):format(vim.inspect(value)), 2)
  end
end

local function load_specs()
  for _, file in ipairs(vim.fn.globpath(vim.fn.getcwd(), 'lua/**/*_spec.lua', true, true)) do
    dofile(file)
  end
end

function M.run(opts)
  opts = opts or {}
  load_specs()

  local failures = {}
  for _, test in ipairs(tests) do
    for _, fn in ipairs(before_each_fns) do
      fn()
    end

    local ok, err = pcall(test.fn)

    for _, fn in ipairs(after_each_fns) do
      fn()
    end

    if ok then
      if opts.verbose then
        print('ok - ' .. test.name)
      end
    else
      failures[#failures + 1] = { name = test.name, err = err }
      print('not ok - ' .. test.name)
      print(err)
    end
  end

  if #failures > 0 then
    print(('%d test(s) run'):format(#tests))
    print(('%d test(s) failed'):format(#failures))
    vim.cmd('cquit 1')
  end

  print(('%d test(s) run'):format(#tests))
end

return M
