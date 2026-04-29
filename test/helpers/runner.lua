local M = {}

local Suite = {}
Suite.__index = Suite

function Suite.new(name, parent)
  return setmetatable({
    name = name,
    parent = parent,
    children = {},
    before_all = {},
    after_all = {},
    before_each = {},
    after_each = {},
  }, Suite)
end

local state = {
  root = Suite.new('<root>', nil),
  current = nil,
  tests = 0,
  failures = {},
}

state.current = state.root

local function full_name(node)
  local names = {}
  while node and node.name ~= '<root>' do
    table.insert(names, 1, node.name)
    node = node.parent
  end
  return table.concat(names, ' ')
end

local function push_failure(name, err)
  table.insert(state.failures, {
    name = name,
    err = err,
  })
end

local function run_fn(name, fn)
  local ok, err = xpcall(fn, debug.traceback)
  if not ok then
    push_failure(name, err)
  end
  return ok
end

function M.describe(name, fn)
  local parent = state.current
  local suite = Suite.new(name, parent)
  table.insert(parent.children, {
    type = 'suite',
    suite = suite,
  })

  state.current = suite
  fn()
  state.current = parent
end

function M.it(name, fn)
  table.insert(state.current.children, {
    type = 'test',
    name = name,
    fn = fn,
  })
end

function M.before_all(fn)
  table.insert(state.current.before_all, fn)
end

function M.after_all(fn)
  table.insert(state.current.after_all, fn)
end

function M.before_each(fn)
  table.insert(state.current.before_each, fn)
end

function M.after_each(fn)
  table.insert(state.current.after_each, fn)
end

local function collect_before_each(suite)
  local hooks = {}
  local chain = {}
  while suite and suite.name ~= '<root>' do
    table.insert(chain, 1, suite)
    suite = suite.parent
  end
  for _, item in ipairs(chain) do
    vim.list_extend(hooks, item.before_each)
  end
  return hooks
end

local function collect_after_each(suite)
  local hooks = {}
  while suite and suite.name ~= '<root>' do
    vim.list_extend(hooks, suite.after_each)
    suite = suite.parent
  end
  return hooks
end

local function run_test(suite, test)
  state.tests = state.tests + 1

  local name = full_name(suite) .. ' ' .. test.name
  local ok = true

  for _, hook in ipairs(collect_before_each(suite)) do
    ok = run_fn(name .. ' before_each', hook) and ok
  end

  if ok then
    ok = run_fn(name, test.fn)
  end

  for _, hook in ipairs(collect_after_each(suite)) do
    ok = run_fn(name .. ' after_each', hook) and ok
  end

  if ok then
    io.write('.')
  else
    io.write('F')
  end
end

local function run_suite(suite)
  local suite_name = full_name(suite)
  local ok = true

  for _, hook in ipairs(suite.before_all) do
    ok = run_fn(suite_name .. ' before_all', hook) and ok
  end

  if ok then
    for _, child in ipairs(suite.children) do
      if child.type == 'suite' then
        run_suite(child.suite)
      else
        run_test(suite, child)
      end
    end
  end

  for _, hook in ipairs(suite.after_all) do
    run_fn(suite_name .. ' after_all', hook)
  end
end

function M.install_globals()
  _G.assert = require('test.helpers.assert')
  _G.describe = M.describe
  _G.it = M.it
  _G.before_all = M.before_all
  _G.after_all = M.after_all
  _G.before_each = M.before_each
  _G.after_each = M.after_each
end

function M.run(specs)
  M.install_globals()

  for _, spec in ipairs(specs) do
    dofile(spec)
  end

  run_suite(state.root)
  io.write('\n')

  if #state.failures > 0 then
    for index, failure in ipairs(state.failures) do
      io.stderr:write(('\n%d) %s\n%s\n'):format(index, failure.name, failure.err))
    end
  end

  io.write(('\n%d tests, %d failures\n'):format(state.tests, #state.failures))

  return #state.failures == 0
end

return M
