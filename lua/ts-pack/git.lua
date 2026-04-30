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

function M.acquire_checkout_lock(spec)
  local locks = path.join(path.cache_dir(), '.locks')
  fs.ensure_dir(locks)

  local lock = M.checkout_lock_path(spec)
  local ok, err = uv.fs_mkdir(lock, 448)
  if not ok then
    if err == 'EEXIST' then
      error(('parser `%s` checkout is already running: %s'):format(spec.name, lock), 0)
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
    return spec.version
  end

  if lock_entry and lock_entry.rev then
    return lock_entry.rev
  end

  return spec.version
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
      M.git({ 'clone', '--filter=blob:none', spec.src, target })
    elseif not (opts and opts.offline) then
      M.assert_git_unlocked(spec, target)
      M.git({ 'fetch', '--tags', '--force' }, target)
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
      M.git_async({ 'clone', '--filter=blob:none', spec.src, target })
    elseif not (opts and opts.offline) then
      M.assert_git_unlocked(spec, target)
      M.git_async({ 'fetch', '--tags', '--force' }, target)
    end

    if ref and ref ~= '' then
      M.assert_git_unlocked(spec, target)
      M.git_async({ 'checkout', '--detach', ref }, target)
    end

    return target
  end)
end

return M
