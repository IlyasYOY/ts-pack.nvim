vim.opt.runtimepath:prepend(vim.fn.getcwd())

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

local helpers = require('tests.query_helpers')
local library = require('ts-pack.library')
local path = require('ts-pack.path')
local queries = require('ts-pack.queries')
local ts_pack = require('ts-pack')

local function parser_loads(name)
  local parser = path.parser_path(name)
  if vim.fn.filereadable(parser) ~= 1 then
    return false
  end

  local ok, loaded = pcall(vim.treesitter.language.add, name, { path = parser })
  return ok and loaded
end

local names = helpers.required_parsers()
local specs = library.select(names)
local pending = {}

for _, spec in ipairs(specs) do
  require('ts-pack.queries').materialize_bundled(spec)
  if not parser_loads(spec.name) then
    pending[#pending + 1] = spec
  end
end

if #pending > 0 then
  print(('installing %d parser(s): %s'):format(
    #pending,
    table.concat(
      vim.tbl_map(function(spec)
        return spec.name
      end, pending),
      ', '
    )
  ))
  ts_pack.add(pending, { quiet = true })
else
  print(('all %d parser(s) already installed'):format(#specs))
end

for _, spec in ipairs(specs) do
  queries.materialize_bundled(spec)
end
