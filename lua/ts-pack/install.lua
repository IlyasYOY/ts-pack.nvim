local M = {}

local build = require('ts-pack.build')
local fs = require('ts-pack.fs')
local git = require('ts-pack.git')
local path = require('ts-pack.path')
local queries = require('ts-pack.queries')

local function materialize_queries(spec, source_root, opts)
  if not spec.queries then
    return
  end

  local src = spec.queries
  if not vim.startswith(src, '/') then
    src = path.join(source_root, src)
  end

  fs.copy_tree(src, path.query_path(spec.name, opts))
end

local function install_with(spec, opts, ensure_checkout, generate, compile, current_rev)
  opts = opts or {}

  local lock = fs.load_lock()
  local lock_entry = lock.parsers[spec.name]
  local ref = opts.target == 'lockfile' and lock_entry and lock_entry.rev
    or git.resolve_ref(spec, lock_entry, opts)

  local source_root = ensure_checkout(spec, ref, opts)
  local build_root = source_root
  if spec.location then
    build_root = path.join(build_root, spec.location)
  end

  generate(spec, build_root)
  compile(build_root)

  local rev = spec.path and (ref or spec.version or 'local') or current_rev(source_root)
  local parser_path = path.parser_path(spec.name, opts)
  fs.copy_file(path.join(build_root, 'parser.so'), parser_path)
  materialize_queries(spec, source_root, opts)
  queries.materialize_bundled(spec, opts)

  fs.ensure_dir(path.parser_info_dir(opts))
  vim.fn.writefile({ rev }, path.parser_revision_path(spec.name, opts))

  lock = fs.load_lock()
  lock.parsers[spec.name] = {
    src = spec.src,
    rev = rev,
    version = spec.version,
    data = spec.data,
  }
  fs.save_lock(lock)

  return {
    active = true,
    path = parser_path,
    rev = rev,
    spec = vim.deepcopy(spec),
  }
end

function M.install(spec, opts)
  return install_with(
    spec,
    opts,
    git.ensure_checkout,
    build.generate,
    build.compile,
    git.current_rev
  )
end

function M.install_async(spec, opts)
  return install_with(
    spec,
    opts,
    git.ensure_checkout_async,
    build.generate_async,
    build.compile_async,
    git.current_rev_async
  )
end

return M
