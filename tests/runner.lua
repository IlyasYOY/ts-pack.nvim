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
  local ok, err = xpcall(fn, debug.traceback)
  hook_stack[#hook_stack] = nil
  stack[#stack] = nil

  if not ok then
    error(err, 0)
  end
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

local function fail(message, level)
  error(message, (level or 1) + 1)
end

local function inspect(value)
  return vim.inspect(value)
end

local function equal(expected, actual, message)
  if expected ~= actual then
    fail(message or ('expected %s, got %s'):format(inspect(expected), inspect(actual)), 2)
  end
end

local function not_equal(expected, actual, message)
  if expected == actual then
    fail(message or ('expected value not to equal ' .. inspect(expected)), 2)
  end
end

local function same(expected, actual, message)
  if not vim.deep_equal(expected, actual) then
    fail(message or ('expected %s, got %s'):format(inspect(expected), inspect(actual)), 2)
  end
end

local function truthy(value, message)
  if not value then
    fail(message or ('expected truthy value, got ' .. inspect(value)), 2)
  end
end

local function falsy(value, message)
  if value then
    fail(message or ('expected falsy value, got ' .. inspect(value)), 2)
  end
end

local function is_true(value, message)
  if value ~= true then
    fail(message or ('expected true, got ' .. inspect(value)), 2)
  end
end

local function is_false(value, message)
  if value ~= false then
    fail(message or ('expected false, got ' .. inspect(value)), 2)
  end
end

local function is_nil(value, message)
  if value ~= nil then
    fail(message or ('expected nil, got ' .. inspect(value)), 2)
  end
end

local function is_not_nil(value, message)
  if value == nil then
    fail(message or 'expected non-nil value, got nil', 2)
  end
end

local function has_error(fn, expected)
  local ok, err = pcall(fn)
  if ok then
    fail('expected function to error', 2)
  end

  if expected ~= nil and not tostring(err):find(expected, 1, true) then
    fail(('expected error containing %s, got %s'):format(inspect(expected), inspect(err)), 2)
  end

  return err
end

local assert_table = setmetatable({}, {
  __call = function(_, value, message)
    return native_assert(value, message)
  end,
})

assert_table.equal = equal
assert_table.equals = equal
assert_table.same = same
assert_table.not_equal = not_equal
assert_table.truthy = truthy
assert_table.falsy = falsy
assert_table.True = is_true
assert_table.False = is_false
assert_table.Falsy = falsy
assert_table.is_true = is_true
assert_table.is_false = is_false
assert_table.is_nil = is_nil
assert_table.is_not_nil = is_not_nil
assert_table.has_error = has_error
assert_table.number = function(value, message)
  if type(value) ~= 'number' then
    fail(message or ('expected number, got ' .. inspect(value)), 2)
  end
end

assert_table.are = assert_table
assert_table.is = assert_table
assert_table.are_not = {
  equal = not_equal,
  equals = not_equal,
  same = function(expected, actual, message)
    if vim.deep_equal(expected, actual) then
      fail(message or ('expected value not to equal ' .. inspect(expected)), 2)
    end
  end,
}

_G.assert = assert_table

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

local function run_test(test)
  local ok = true
  local errors = {}

  for _, fn in ipairs(test.before_each) do
    local hook_ok, err = xpcall(fn, debug.traceback)
    if not hook_ok then
      ok = false
      errors[#errors + 1] = err
      break
    end
  end

  if ok then
    local test_ok, err = xpcall(test.fn, debug.traceback)
    ok = test_ok
    if not test_ok then
      errors[#errors + 1] = err
    end
  end

  for index = #test.after_each, 1, -1 do
    local hook_ok, err = xpcall(test.after_each[index], debug.traceback)
    if not hook_ok then
      ok = false
      errors[#errors + 1] = err
    end
  end

  return ok, table.concat(errors, '\n')
end

local function run_registered_tests(opts)
  local failures = {}
  for _, test in ipairs(tests) do
    local ok, err = run_test(test)
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

local function sorted_glob(patterns)
  local files = {}
  for _, pattern in ipairs(patterns) do
    for _, file in ipairs(vim.fn.globpath(vim.fn.getcwd(), pattern, true, true)) do
      files[#files + 1] = file
    end
  end
  table.sort(files)
  return files
end

local function normalize_files(files)
  local result = {}
  for _, file in ipairs(files) do
    result[#result + 1] = vim.fn.fnamemodify(file, ':p')
  end
  table.sort(result)
  return result
end

local function load_files(files)
  local failures = {}
  for _, file in ipairs(files) do
    reset_hooks()
    local ok, err = xpcall(function()
      dofile(file)
    end, debug.traceback)
    if not ok then
      failures[#failures + 1] = { name = 'load ' .. file, err = err }
    end
  end
  return failures
end

local function run_phase(files, opts)
  tests = {}
  reset_hooks()
  local failures = load_files(files)
  for _, failure in ipairs(failures) do
    print('not ok - ' .. failure.name)
    print(failure.err)
  end
  local test_failures, count = run_registered_tests(opts)
  vim.list_extend(failures, test_failures)
  return failures, count
end

function M.run(opts)
  opts = opts or {}
  local failures
  local count

  if opts.files then
    local files = normalize_files(opts.files)
    for _, file in ipairs(files) do
      if file:find('/tests/query/', 1, true) or file:find('/tests/indent/', 1, true) then
        switch_to_fixture_home()
        break
      end
    end
    failures, count = run_phase(files, opts)
  else
    local unit_files = sorted_glob({ 'lua/**/*_spec.lua', 'tests/query_helpers_spec.lua' })
    failures, count = run_phase(unit_files, opts)

    switch_to_fixture_home()
    local fixture_files = sorted_glob({ 'tests/query/*_spec.lua', 'tests/indent/*_spec.lua' })
    local fixture_failures, fixture_count = run_phase(fixture_files, opts)
    vim.list_extend(failures, fixture_failures)
    count = count + fixture_count
  end

  if #failures > 0 then
    print(('%d test(s) run'):format(count))
    print(('%d test(s) failed'):format(#failures))
    vim.cmd('cquit 1')
  end

  print(('%d test(s) run'):format(count))
end

return M
