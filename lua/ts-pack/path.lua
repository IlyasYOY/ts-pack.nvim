local M = {}

function M.join(...)
  return vim.fs.joinpath(...)
end

function M.default_site_dir()
  return M.join(vim.fn.stdpath('data'), 'site')
end

function M.cache_dir()
  return M.join(vim.fn.stdpath('cache'), 'ts-pack')
end

function M.lockfile()
  return M.join(vim.fn.stdpath('config'), 'ts-pack-lock.json')
end

function M.parser_dir(opts)
  return M.join((opts and opts.dir) or M.default_site_dir(), 'parser')
end

function M.parser_info_dir(opts)
  return M.join((opts and opts.dir) or M.default_site_dir(), 'parser-info')
end

function M.queries_dir(opts)
  return M.join((opts and opts.dir) or M.default_site_dir(), 'queries')
end

function M.parser_path(name, opts)
  return M.join(M.parser_dir(opts), name .. '.so')
end

function M.parser_revision_path(name, opts)
  return M.join(M.parser_info_dir(opts), name .. '.revision')
end

function M.query_path(name, opts)
  return M.join(M.queries_dir(opts), name)
end

return M
