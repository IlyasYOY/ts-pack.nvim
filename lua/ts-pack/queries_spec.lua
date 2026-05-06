local function materialized_site()
  local root = vim.env.TS_PACK_TEST_HOME or vim.fs.joinpath(vim.fn.getcwd(), '.test-home')
  return vim.fs.joinpath(root, 'query-materialize')
end

local function materialize_opts()
  return { dir = materialized_site() }
end

local function reset_materialized()
  vim.fn.delete(materialized_site(), 'rf')
end

local function materialized_files(lang)
  local dir = require('ts-pack.path').query_path(lang, materialize_opts())
  if not vim.uv.fs_stat(dir) then
    return {}
  end

  local files = {}
  for name, type_ in vim.fs.dir(dir) do
    if type_ == 'file' then
      files[#files + 1] = name
    end
  end
  table.sort(files)
  return files
end

before_each(reset_materialized)

describe('ts-pack.queries', function()
  it('exposes bundled query paths for copied bundled languages', function()
    local queries = require('ts-pack.queries')

    assert.truthy(queries.bundled_path('c'):match('/lua/ts%-pack/bundled_queries/c$'))
    assert.truthy(queries.bundled_path('go'):match('/lua/ts%-pack/bundled_queries/go$'))
    assert.truthy(queries.bundled_path('lua'):match('/lua/ts%-pack/bundled_queries/lua$'))
    assert.truthy(queries.bundled_path('markdown'):match('/lua/ts%-pack/bundled_queries/markdown$'))
    assert.truthy(queries.bundled_path('bash'):match('/lua/ts%-pack/bundled_queries/bash$'))
    assert.falsy(queries.bundled_path('missing'))
  end)

  it('ships expected query files for selected bundled language families', function()
    local queries = require('ts-pack.queries')
    local expected = {
      c = { 'highlights.scm', 'indents.scm', 'injections.scm' },
      go = { 'highlights.scm', 'indents.scm', 'injections.scm' },
      gomod = { 'highlights.scm', 'injections.scm' },
      gosum = { 'highlights.scm' },
      gowork = { 'highlights.scm', 'injections.scm' },
      lua = { 'highlights.scm', 'indents.scm', 'injections.scm' },
      luadoc = { 'highlights.scm' },
      markdown = { 'highlights.scm', 'injections.scm' },
      markdown_inline = { 'highlights.scm', 'injections.scm' },
    }

    for lang, files in pairs(expected) do
      local root = queries.bundled_path(lang)
      for _, file in ipairs(files) do
        assert.truthy(vim.uv.fs_stat(vim.fs.joinpath(root, file)))
      end
    end
  end)

  it('parses bundled queries for languages available to Neovim', function()
    local queries = require('ts-pack.queries')
    queries.register_predicates()

    for _, lang in ipairs({
      'c',
      'go',
      'gomod',
      'gosum',
      'lua',
      'luadoc',
      'markdown',
      'markdown_inline',
    }) do
      local ok, loaded = pcall(vim.treesitter.language.add, lang)
      if ok and loaded then
        for name in vim.fs.dir(queries.bundled_path(lang)) do
          local file = vim.fs.joinpath(queries.bundled_path(lang), name)
          local source = table.concat(vim.fn.readfile(file), '\n')
          local parsed, err = pcall(vim.treesitter.query.parse, lang, source)
          assert(parsed, ('failed to parse %s/%s: %s'):format(lang, name, err or 'unknown error'))
        end
      end
    end
  end)

  it('materializes all bundled query files when enabled', function()
    local queries = require('ts-pack.queries')

    queries.materialize_bundled({ name = 'c', bundled_queries = true }, materialize_opts())

    assert.same({
      'folds.scm',
      'highlights.scm',
      'indents.scm',
      'injections.scm',
      'locals.scm',
    }, materialized_files('c'))
  end)

  it('materializes only selected bundled query types', function()
    local queries = require('ts-pack.queries')

    queries.materialize_bundled({
      name = 'c',
      bundled_queries = { highlights = true },
    }, materialize_opts())

    assert.same({ 'highlights.scm' }, materialized_files('c'))
  end)

  it('ignores false and unknown bundled query filter entries', function()
    local queries = require('ts-pack.queries')

    queries.materialize_bundled({
      name = 'c',
      bundled_queries = { highlights = false, indents = true, missing = true },
    }, materialize_opts())

    assert.same({ 'indents.scm' }, materialized_files('c'))
  end)

  it('removes stale bundled query files for an empty filter', function()
    local queries = require('ts-pack.queries')

    queries.materialize_bundled({ name = 'c', bundled_queries = true }, materialize_opts())
    queries.materialize_bundled({ name = 'c', bundled_queries = {} }, materialize_opts())

    assert.same({}, materialized_files('c'))
  end)

  it('applies bundled query filters to inherited languages', function()
    local queries = require('ts-pack.queries')

    queries.materialize_bundled({
      name = 'tsx',
      bundled_queries = { highlights = true },
    }, materialize_opts())

    assert.same({ 'highlights.scm' }, materialized_files('tsx'))
    assert.same({ 'highlights.scm' }, materialized_files('typescript'))
    assert.same({ 'highlights.scm' }, materialized_files('jsx'))
    assert.same({ 'highlights.scm' }, materialized_files('ecma'))
  end)
end)
