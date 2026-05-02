local M = {}

local uv = vim.uv or vim.loop
local fs = require('ts-pack.fs')
local path = require('ts-pack.path')
local process = require('ts-pack.process')

function M.git(args, cwd)
  local cmd = { 'git' }
  vim.list_extend(cmd, args)
  return process.system(cmd, { cwd = cwd })
end

function M.git_async(args, cwd)
  local cmd = { 'git' }
  vim.list_extend(cmd, args)
  return process.async_system(cmd, { cwd = cwd })
end

function M.checkout_path(spec)
  return path.join(path.cache_dir(), spec.name)
end

function M.checkout_lock_path(spec)
  return path.join(path.cache_dir(), '.locks', spec.name .. '.lock')
end

local function checkout_lock_owner_path(lock)
  return path.join(lock, 'owner.json')
end

function M.git_index_lock_path(target)
  return path.join(target, '.git', 'index.lock')
end

function M.assert_git_unlocked(spec, target)
  local lock = M.git_index_lock_path(target)
  if fs.exists(lock) then
    error(
      ('parser `%s` checkout is locked: %s; remove it only after confirming no git process is running'):format(
        spec.name,
        lock
      ),
      0
    )
  end
end

local function is_exists_error(err)
  return type(err) == 'string' and err:match('^EEXIST') ~= nil
end

local function write_checkout_lock_owner(spec, lock)
  local owner = {
    parser = spec.name,
    lock = lock,
    checkout = M.checkout_path(spec),
    cwd = vim.fn.getcwd(),
    created_at = os.date('!%Y-%m-%dT%H:%M:%SZ'),
  }

  if uv and type(uv.os_getpid) == 'function' then
    local ok, pid = pcall(uv.os_getpid)
    if ok then
      owner.pid = pid
    end
  end

  pcall(fs.write_json, checkout_lock_owner_path(lock), owner)
end

local function read_checkout_lock_owner(lock)
  return fs.read_json(checkout_lock_owner_path(lock), nil)
end

local function checkout_lock_message(spec, lock, err)
  local lines = {
    ('parser `%s` checkout lock already exists: %s'):format(spec.name, lock),
  }

  local owner = read_checkout_lock_owner(lock)
  if owner then
    local details = {}
    if owner.pid then
      details[#details + 1] = ('pid=%s'):format(owner.pid)
    end
    if owner.created_at then
      details[#details + 1] = ('created_at=%s'):format(owner.created_at)
    end
    if owner.cwd then
      details[#details + 1] = ('cwd=%s'):format(owner.cwd)
    end
    if owner.checkout then
      details[#details + 1] = ('checkout=%s'):format(owner.checkout)
    end
    if #details > 0 then
      lines[#lines + 1] = 'lock owner: ' .. table.concat(details, ', ')
    end
  elseif err then
    lines[#lines + 1] = ('lock error: %s'):format(err)
  end

  lines[#lines + 1] =
    'check for active nvim, git, or tree-sitter processes before removing this lock directory'
  lines[#lines + 1] = ('manual recovery: rm -rf %s'):format(lock)

  return table.concat(lines, '\n')
end

function M.acquire_checkout_lock(spec)
  local locks = path.join(path.cache_dir(), '.locks')
  fs.ensure_dir(locks)

  local lock = M.checkout_lock_path(spec)
  local ok, err = uv.fs_mkdir(lock, 448)
  if not ok then
    if is_exists_error(err) then
      error(checkout_lock_message(spec, lock, err), 0)
    end
    error(
      ('failed to lock parser `%s` checkout at %s: %s'):format(
        spec.name,
        lock,
        err or 'unknown error'
      ),
      0
    )
  end

  write_checkout_lock_owner(spec, lock)
  return lock
end

function M.release_checkout_lock(lock)
  if lock then
    vim.fn.delete(lock, 'rf')
  end
end

function M.with_checkout_lock(spec, fn)
  local lock = M.acquire_checkout_lock(spec)
  local ok, result = pcall(fn)
  M.release_checkout_lock(lock)
  if not ok then
    error(result, 0)
  end
  return result
end

function M.current_rev(target)
  return vim.trim(M.git({ 'rev-parse', 'HEAD' }, target).stdout or '')
end

function M.current_rev_async(target)
  return vim.trim(M.git_async({ 'rev-parse', 'HEAD' }, target).stdout or '')
end

function M.resolve_ref(spec, lock_entry, opts)
  if opts and opts.target == 'version' then
    return spec.version or (spec.branch and ('origin/' .. spec.branch))
  end

  if lock_entry and lock_entry.rev then
    return lock_entry.rev
  end

  return spec.version or (spec.branch and ('origin/' .. spec.branch))
end

local function clone_args(spec, target)
  local args = { 'clone', '--filter=blob:none' }
  if spec.branch then
    vim.list_extend(args, { '--branch', spec.branch })
  end
  vim.list_extend(args, { spec.src, target })
  return args
end

local function fetch_args(spec)
  local args = { 'fetch', '--tags', '--force' }
  if spec.branch then
    vim.list_extend(args, {
      'origin',
      ('+refs/heads/%s:refs/remotes/origin/%s'):format(spec.branch, spec.branch),
    })
  end
  return args
end

function M.ensure_checkout(spec, ref, opts)
  if spec.path then
    return spec.path
  end

  return M.with_checkout_lock(spec, function()
    local target = M.checkout_path(spec)
    fs.ensure_dir(path.cache_dir())

    if not fs.exists(target) then
      if opts and opts.offline then
        error(('parser `%s` is not checked out and `offline` is set'):format(spec.name), 0)
      end
      M.git(clone_args(spec, target))
    elseif not (opts and opts.offline) then
      M.assert_git_unlocked(spec, target)
      M.git(fetch_args(spec), target)
    end

    if ref and ref ~= '' then
      M.assert_git_unlocked(spec, target)
      M.git({ 'checkout', '--detach', ref }, target)
    end

    return target
  end)
end

function M.ensure_checkout_async(spec, ref, opts)
  if spec.path then
    return spec.path
  end

  return M.with_checkout_lock(spec, function()
    local target = M.checkout_path(spec)
    fs.ensure_dir(path.cache_dir())

    if not fs.exists(target) then
      if opts and opts.offline then
        error(('parser `%s` is not checked out and `offline` is set'):format(spec.name), 0)
      end
      M.git_async(clone_args(spec, target))
    elseif not (opts and opts.offline) then
      M.assert_git_unlocked(spec, target)
      M.git_async(fetch_args(spec), target)
    end

    if ref and ref ~= '' then
      M.assert_git_unlocked(spec, target)
      M.git_async({ 'checkout', '--detach', ref }, target)
    end

    return target
  end)
end

return M
