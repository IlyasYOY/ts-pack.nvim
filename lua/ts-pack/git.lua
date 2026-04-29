local M = {}

local uv = vim.uv or vim.loop

local function run(argv, opts)
  opts = opts or {}
  local result = vim
    .system(argv, {
      cwd = opts.cwd,
      text = true,
    })
    :wait()

  if result.code ~= 0 then
    local output = vim.trim((result.stderr or '') .. '\n' .. (result.stdout or ''))
    error(('ts-pack: command failed: %s\n%s'):format(table.concat(argv, ' '), output))
  end

  return vim.trim(result.stdout or '')
end

local function is_dir(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == 'directory'
end

local function mkdir_parent(path)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
end

local function rm(path)
  if uv.fs_stat(path) then
    vim.fn.delete(path, 'rf')
  end
end

local function ref_exists(path, ref)
  return pcall(run, { 'git', 'rev-parse', '--verify', '--quiet', ref }, { cwd = path })
end

function M.is_checkout(path)
  return is_dir(path .. '/.git')
end

function M.current_rev(path)
  return run({ 'git', 'rev-parse', 'HEAD' }, { cwd = path })
end

function M.fetch(path)
  run({ 'git', 'fetch', '--quiet', '--all', '--tags' }, { cwd = path })
end

function M.remote_default_ref(path)
  local ok, ref = pcall(
    run,
    { 'git', 'symbolic-ref', '--quiet', '--short', 'refs/remotes/origin/HEAD' },
    {
      cwd = path,
    }
  )
  if ok and ref ~= '' then
    return ref
  end
  if ref_exists(path, 'origin/main') then
    return 'origin/main'
  end
  if ref_exists(path, 'origin/master') then
    return 'origin/master'
  end
  error('ts-pack: could not resolve remote default branch')
end

function M.checkout_target(path, version)
  if version and version ~= '' then
    run({ 'git', 'checkout', '--quiet', version }, { cwd = path })
  else
    run({ 'git', 'checkout', '--quiet', M.remote_default_ref(path) }, { cwd = path })
  end
end

function M.clone(src, path)
  local tmp = path .. '.tmp'
  rm(tmp)
  mkdir_parent(tmp)
  run({ 'git', 'clone', '--quiet', src, tmp })
  rm(path)
  assert(uv.fs_rename(tmp, path))
end

function M.ensure_checkout(path, src, version)
  if not M.is_checkout(path) then
    if not src or src == '' then
      error('ts-pack: missing git src for checkout')
    end
    M.clone(src, path)
  else
    M.fetch(path)
  end
  M.checkout_target(path, version)
end

function M.update_checkout(path, version)
  M.fetch(path)
  M.checkout_target(path, version)
end

return M
