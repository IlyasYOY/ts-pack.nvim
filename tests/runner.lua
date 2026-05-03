local M = {}

local tests = {}
local stack = {}
local hook_stack = {}

local function reset_hooks()
  hook_stack = {
    {
      before_each = {},
      after_each = {},
    },
  }
end

reset_hooks()

local function collect_hooks(kind)
  local result = {}
  for _, hooks in ipairs(hook_stack) do
    for _, fn in ipairs(hooks[kind]) do
      result[#result + 1] = fn
    end
  end
  return result
end

local function fullname(name)
  local parts = vim.deepcopy(stack)
  parts[#parts + 1] = name
  return table.concat(parts, ' ')
end

function _G.describe(name, fn)
  stack[#stack + 1] = name
  hook_stack[#hook_stack + 1] = {
    before_each = {},
    after_each = {},
  }
  fn()
  hook_stack[#hook_stack] = nil
  stack[#stack] = nil
end

function _G.it(name, fn)
  tests[#tests + 1] = {
    name = fullname(name),
    fn = fn,
    before_each = collect_hooks('before_each'),
    after_each = collect_hooks('after_each'),
  }
end

function _G.before_each(fn)
  local hooks = hook_stack[#hook_stack]
  hooks.before_each[#hooks.before_each + 1] = fn
end

function _G.after_each(fn)
  local hooks = hook_stack[#hook_stack]
  hooks.after_each[#hooks.after_each + 1] = fn
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

_G.assert.truthy = function(value, message)
  if not value then
    error(message or ('expected truthy value, got %s'):format(vim.inspect(value)), 2)
  end
end

_G.assert.falsy = function(value, message)
  if value then
    error(message or ('expected falsy value, got %s'):format(vim.inspect(value)), 2)
  end
end

_G.assert.are = _G.assert
_G.assert.is = _G.assert
_G.assert.True = _G.assert.truthy
_G.assert.False = _G.assert.falsy
_G.assert.Falsy = _G.assert.falsy

_G.assert.number = function(value)
  if type(value) ~= 'number' then
    error(('expected number, got %s'):format(vim.inspect(value)), 2)
  end
end

local function switch_to_fixture_home()
  local base = vim.env.TS_PACK_PARSER_TEST_HOME or vim.fs.joinpath(vim.fn.getcwd(), '.test-parsers')

  vim.env.XDG_CONFIG_HOME = vim.fs.joinpath(base, 'config')
  vim.env.XDG_DATA_HOME = vim.fs.joinpath(base, 'data')
  vim.env.XDG_CACHE_HOME = vim.fs.joinpath(base, 'cache')
  vim.env.XDG_STATE_HOME = vim.fs.joinpath(base, 'state')

  for _, dir in ipairs({
    vim.env.XDG_CONFIG_HOME,
    vim.env.XDG_DATA_HOME,
    vim.env.XDG_CACHE_HOME,
    vim.env.XDG_STATE_HOME,
  }) do
    vim.fn.mkdir(dir, 'p')
  end

  local site = require('ts-pack.path').default_site_dir()
  vim.opt.runtimepath:prepend(site)
  vim.opt.packpath:prepend(site)
end

local function run_registered_tests(opts)
  local failures = {}
  for _, test in ipairs(tests) do
    for _, fn in ipairs(test.before_each) do
      fn()
    end

    local ok, err = pcall(test.fn)

    for _, fn in ipairs(test.after_each) do
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
  return failures, #tests
end

local function load_unit_specs()
  for _, file in ipairs(vim.fn.globpath(vim.fn.getcwd(), 'lua/**/*_spec.lua', true, true)) do
    reset_hooks()
    dofile(file)
  end
end

local function load_fixture_specs()
  switch_to_fixture_home()
  for _, pattern in ipairs({ 'tests/query/*_spec.lua', 'tests/indent/*_spec.lua' }) do
    for _, file in ipairs(vim.fn.globpath(vim.fn.getcwd(), pattern, true, true)) do
      reset_hooks()
      dofile(file)
    end
  end
end

function M.run(opts)
  opts = opts or {}

  reset_hooks()
  tests = {}
  load_unit_specs()
  local failures, count = run_registered_tests(opts)

  tests = {}
  load_fixture_specs()
  local fixture_failures, fixture_count = run_registered_tests(opts)
  for _, failure in ipairs(fixture_failures) do
    failures[#failures + 1] = failure
  end
  count = count + fixture_count

  if #failures > 0 then
    print(('%d test(s) run'):format(count))
    print(('%d test(s) failed'):format(#failures))
    vim.cmd('cquit 1')
  end

  print(('%d test(s) run'):format(count))
end

return M
