local M = {}

local function noop_resume(_, _) end

M.resume_async = noop_resume

function M.set_async_resumer(fn)
  M.resume_async = fn or noop_resume
end

function M.shell_error(cmd, cwd, result)
  local where = cwd and (' in ' .. cwd) or ''
  local stderr = result.stderr and vim.trim(result.stderr) or ''
  local stdout = result.stdout and vim.trim(result.stdout) or ''
  local detail = stderr ~= '' and stderr or stdout
  if detail ~= '' then
    detail = ': ' .. detail
  end
  return ('command failed%s: %s%s'):format(where, table.concat(cmd, ' '), detail)
end

function M.system(cmd, opts)
  opts = opts or {}
  local result = vim.system(cmd, { cwd = opts.cwd, text = true, env = opts.env }):wait()
  if result.code ~= 0 then
    error(M.shell_error(cmd, opts.cwd, result), 0)
  end
  return result
end

function M.system_result(cmd, opts)
  opts = opts or {}
  return vim.system(cmd, { cwd = opts.cwd, text = true, env = opts.env }):wait()
end

function M.async_system_result(cmd, opts)
  opts = opts or {}
  local thread = coroutine.running()
  if not thread then
    error('async_system_result must run inside a coroutine', 2)
  end

  local ok, err = pcall(vim.system, cmd, {
    cwd = opts.cwd,
    text = true,
    env = opts.env,
  }, function(result)
    M.resume_async(thread, result)
  end)

  if not ok then
    error(err, 0)
  end

  return coroutine.yield()
end

function M.async_system(cmd, opts)
  local result = M.async_system_result(cmd, opts)
  if result.code ~= 0 then
    error(M.shell_error(cmd, opts and opts.cwd or nil, result), 0)
  end
  return result
end

return M
