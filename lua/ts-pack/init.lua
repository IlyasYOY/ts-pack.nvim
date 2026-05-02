local M = {}

local fs = require('ts-pack.fs')
local hooks = require('ts-pack.hooks')
local install = require('ts-pack.install')
local path = require('ts-pack.path')
local process = require('ts-pack.process')
local report = require('ts-pack.report')
local spec = require('ts-pack.spec')

local uv = vim.uv or vim.loop

local active = {}
local active_order = {}
local async_running = false
local async_operation = nil

local function normalize_names(names)
  if names == nil then
    local result = vim.deepcopy(active_order)
    table.sort(result)
    return result
  end

  spec.assert_list('names', names)

  local result = {}
  for _, name in ipairs(names) do
    vim.validate('name', name, 'string')
    result[#result + 1] = name
  end
  return result
end

local function remember_spec(parser)
  if not active[parser.name] then
    active_order[#active_order + 1] = parser.name
  end
  active[parser.name] = vim.deepcopy(parser)
end

local function apply_hooks(parser)
  hooks.apply(parser)
end

local function installed_rev(name, opts)
  local revision_path = path.parser_revision_path(name, opts)
  if not fs.exists(revision_path) then
    return nil
  end
  local lines = vim.fn.readfile(revision_path)
  return lines[1]
end

local function info_for(name, opts)
  local parser = active[name]
  local parser_path = path.parser_path(name, opts)
  local rev = installed_rev(name, opts)

  return {
    active = parser ~= nil,
    path = parser_path,
    rev = rev,
    spec = parser and vim.deepcopy(parser) or nil,
  }
end

local function add_info(result, name)
  local lock = fs.load_lock()
  local entry = lock.parsers[name]
  if entry then
    result.src = entry.src
    result.version = entry.version
    result.data = entry.data
  end
  result.installed = fs.exists(result.path)
  return result
end

local function resume_async(thread, result)
  vim.schedule(function()
    local ok, err = coroutine.resume(thread, result)
    if not ok then
      async_running = false
      local kind = async_operation or 'add'
      async_operation = nil
      vim.notify(('ts-pack async %s failed: %s'):format(kind, err), vim.log.levels.ERROR)
    end
  end)
end

process.set_async_resumer(resume_async)

local function async_worker_count(total)
  local count

  if uv and type(uv.available_parallelism) == 'function' then
    local ok, parallelism = pcall(uv.available_parallelism)
    if ok then
      count = parallelism
    end
  end

  if not count and uv and type(uv.cpu_info) == 'function' then
    local ok, cpus = pcall(uv.cpu_info)
    if ok and type(cpus) == 'table' then
      count = #cpus
    end
  end

  count = tonumber(count) or 1
  count = math.floor(count)
  if count < 1 then
    count = 1
  end
  if count > total then
    count = total
  end
  return count
end

local function run_install(kind, specs, opts, runner_opts)
  runner_opts = runner_opts or {}

  if runner_opts.background and async_running then
    vim.notify(
      ('ts-pack async %s is already running; request ignored'):format(kind),
      vim.log.levels.WARN
    )
    return
  end

  if runner_opts.background then
    async_running = true
    async_operation = kind
  end

  opts = vim.deepcopy(opts or {})
  opts.async = nil
  local install_report = report.start_install_report(#specs)
  local results = {}
  local parser_order = {}
  for index, parser in ipairs(specs) do
    parser_order[parser.name] = index
  end

  local next_index = 1
  local active_workers = 0
  local failed_error
  local done = false

  local function sort_report()
    table.sort(install_report.installed, function(left, right)
      return parser_order[left] < parser_order[right]
    end)
  end

  local function finish()
    if runner_opts.background then
      async_running = false
      async_operation = nil
    end

    sort_report()
    if failed_error then
      report.finish_install_report(install_report, true)
      if runner_opts.background then
        vim.notify(('ts-pack async %s failed: %s'):format(kind, failed_error), vim.log.levels.ERROR)
      end
      done = true
      return
    end

    report.finish_install_report(install_report)
    done = true
  end

  local function worker_loop()
    while not failed_error do
      local index = next_index
      next_index = next_index + 1
      local parser = specs[index]
      if not parser then
        break
      end

      local ok, item = pcall(install.install_async, parser, opts)
      if not ok then
        failed_error = item
        break
      end
      results[index] = item
      apply_hooks(parser)
      report.record_installed_parser(install_report, parser.name)
    end
  end

  local function worker()
    local ok, err = pcall(worker_loop)
    if not ok and not failed_error then
      failed_error = err
    end

    active_workers = active_workers - 1
    if active_workers == 0 then
      finish()
    end
  end

  active_workers = async_worker_count(#specs)
  for _ = 1, active_workers do
    local thread = coroutine.create(worker)
    local ok, err = coroutine.resume(thread)
    if not ok and not failed_error then
      failed_error = err
    end
  end

  if active_workers == 0 then
    finish()
  end

  if runner_opts.wait then
    local completed = vim.wait(3600000, function()
      return done
    end, 10)

    if not completed then
      error(('ts-pack %s timed out waiting for parser installs'):format(kind), 0)
    end
    if failed_error then
      error(failed_error, 0)
    end
    return results
  end
end

function M.add(specs, opts)
  opts = opts or {}
  local result = {}
  local normalized = spec.normalize_specs(specs)
  local lock = fs.load_lock()
  local pending = {}
  local pending_indexes = {}

  for index, parser in ipairs(normalized) do
    remember_spec(parser)
    apply_hooks(parser)
    local item = info_for(parser.name, opts)
    item.spec = vim.deepcopy(parser)
    local is_pending = not fs.exists(path.parser_path(parser.name, opts))
    if opts.async then
      item.pending = is_pending
    end
    if opts.info ~= false then
      add_info(item, parser.name)
    end
    if is_pending or not lock.parsers[parser.name] or opts.force or opts.target then
      pending[#pending + 1] = parser
      pending_indexes[#pending_indexes + 1] = index
    end
    result[#result + 1] = item
  end

  if opts.async then
    if #pending > 0 then
      run_install('add', pending, opts, { background = true })
    end
    return result
  end

  if #pending > 0 then
    local installed = run_install('add', pending, opts, { wait = true })
    for pending_index, item in ipairs(installed) do
      result[pending_indexes[pending_index]] = item
    end
  end

  return result
end

function M.del(names, opts)
  opts = opts or {}
  local result = {}
  local lock = fs.load_lock()

  for _, name in ipairs(normalize_names(names)) do
    vim.fn.delete(path.parser_path(name, opts))
    vim.fn.delete(path.parser_revision_path(name, opts))
    vim.fn.delete(path.query_path(name, opts), 'rf')
    lock.parsers[name] = nil
    active[name] = nil
    result[#result + 1] = { name = name, deleted = true }
  end

  local remaining = {}
  for _, name in ipairs(active_order) do
    if active[name] then
      remaining[#remaining + 1] = name
    end
  end
  active_order = remaining

  fs.save_lock(lock)
  return result
end

function M.get(names, opts)
  opts = opts or {}
  local result = {}

  for _, name in ipairs(normalize_names(names)) do
    local item = info_for(name, opts)
    if opts.info ~= false then
      add_info(item, name)
    end
    result[#result + 1] = item
  end

  return result
end

function M.update(names, opts)
  opts = opts or {}
  local result = {}
  local normalized = normalize_names(names)
  local pending = {}

  if opts.async then
    for _, name in ipairs(normalized) do
      local parser = active[name]
      if not parser then
        error(('parser `%s` is not active; call add() with a full spec first'):format(name), 2)
      end
      local item = info_for(name, opts)
      item.pending = true
      pending[#pending + 1] = parser
      result[#result + 1] = item
    end

    if #pending > 0 then
      run_install('update', pending, opts, { background = true })
    end
    return result
  end

  for _, name in ipairs(normalized) do
    local parser = active[name]
    if not parser then
      error(('parser `%s` is not active; call add() with a full spec first'):format(name), 2)
    end
    pending[#pending + 1] = parser
  end

  if #pending > 0 then
    result = run_install('update', pending, opts, { wait = true })
  end

  return result
end

return M
