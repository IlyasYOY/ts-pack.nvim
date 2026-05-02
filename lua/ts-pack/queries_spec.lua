describe('ts-pack.queries', function()
  it('exposes bundled query paths only for imported languages', function()
    local queries = require('ts-pack.queries')

    assert.truthy(queries.bundled_path('c'):match('/lua/ts%-pack/bundled_queries/c$'))
    assert.truthy(queries.bundled_path('go'):match('/lua/ts%-pack/bundled_queries/go$'))
    assert.truthy(queries.bundled_path('lua'):match('/lua/ts%-pack/bundled_queries/lua$'))
    assert.truthy(queries.bundled_path('markdown'):match('/lua/ts%-pack/bundled_queries/markdown$'))
    assert.falsy(queries.bundled_path('bash'))
  end)

  it('ships expected query files for the imported language families', function()
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
end)
