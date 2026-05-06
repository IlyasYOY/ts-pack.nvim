describe('ts-pack.spec', function()
  it('normalizes string specs and strips tree-sitter prefixes', function()
    local spec = require('ts-pack.spec')

    local parser = spec.normalize_spec('https://github.com/tree-sitter/tree-sitter-lua.git')

    assert.equals('https://github.com/tree-sitter/tree-sitter-lua.git', parser.src)
    assert.equals('lua', parser.name)
  end)

  it('keeps supported parser build fields', function()
    local spec = require('ts-pack.spec')

    local bundled_queries = { highlights = true, indents = true }
    local parser = spec.normalize_spec({
      src = '/tmp/tree-sitter-fixture',
      name = 'fixture',
      version = 'HEAD',
      data = { enabled = true },
      branch = 'main',
      location = 'grammar',
      path = '/tmp/tree-sitter-fixture',
      queries = 'queries/fixture',
      bundled_queries = bundled_queries,
      generate = true,
      generate_from_json = false,
    })

    assert.same({
      src = '/tmp/tree-sitter-fixture',
      name = 'fixture',
      version = 'HEAD',
      data = { enabled = true },
      branch = 'main',
      location = 'grammar',
      path = '/tmp/tree-sitter-fixture',
      queries = 'queries/fixture',
      bundled_queries = bundled_queries,
      generate = true,
      generate_from_json = false,
    }, parser)
  end)

  it('keeps boolean and empty bundled query filters', function()
    local spec = require('ts-pack.spec')

    assert.equals(
      true,
      spec.normalize_spec({
        src = '/tmp/tree-sitter-fixture',
        bundled_queries = true,
      }).bundled_queries
    )

    assert.equals(
      false,
      spec.normalize_spec({
        src = '/tmp/tree-sitter-fixture',
        bundled_queries = false,
      }).bundled_queries
    )

    assert.same(
      {},
      spec.normalize_spec({
        src = '/tmp/tree-sitter-fixture',
        bundled_queries = {},
      }).bundled_queries
    )
  end)

  it('keeps string and filtered parser queries', function()
    local spec = require('ts-pack.spec')

    assert.equals(
      'queries/fixture',
      spec.normalize_spec({
        src = '/tmp/tree-sitter-fixture',
        queries = 'queries/fixture',
      }).queries
    )

    assert.same(
      {
        path = 'queries/fixture',
        filter = { highlights = true, indents = false },
      },
      spec.normalize_spec({
        src = '/tmp/tree-sitter-fixture',
        queries = {
          path = 'queries/fixture',
          filter = { highlights = true, indents = false },
        },
      }).queries
    )

    assert.same(
      {
        path = 'queries/fixture',
        filter = {},
      },
      spec.normalize_spec({
        src = '/tmp/tree-sitter-fixture',
        queries = {
          path = 'queries/fixture',
          filter = {},
        },
      }).queries
    )
  end)

  it('rejects invalid parser query filters', function()
    local spec = require('ts-pack.spec')

    for _, queries in ipairs({
      true,
      1,
      {},
      { path = '', filter = {} },
      { path = 'queries/fixture' },
      { path = 'queries/fixture', filter = true },
      { path = 'queries/fixture', filter = { true } },
      { path = 'queries/fixture', filter = { highlights = 'yes' } },
    }) do
      local ok, err = pcall(function()
        spec.normalize_spec({
          src = '/tmp/tree-sitter-fixture',
          queries = queries,
        })
      end)

      assert.falsy(ok)
      assert.truthy(err:match('`spec.queries'))
    end
  end)

  it('rejects invalid bundled query filters', function()
    local spec = require('ts-pack.spec')

    for _, bundled_queries in ipairs({
      'highlights',
      1,
      { true },
      { [1] = true, highlights = true },
      { highlights = 'yes' },
    }) do
      local ok, err = pcall(function()
        spec.normalize_spec({
          src = '/tmp/tree-sitter-fixture',
          bundled_queries = bundled_queries,
        })
      end)

      assert.falsy(ok)
      assert.truthy(err:match('`spec.bundled_queries`'))
    end
  end)

  it('deduplicates matching specs and rejects conflicting specs', function()
    local spec = require('ts-pack.spec')

    local normalized = spec.normalize_specs({
      { src = '/tmp/tree-sitter-fixture', name = 'fixture', version = 'HEAD' },
      { src = '/tmp/tree-sitter-fixture', name = 'fixture', version = 'HEAD' },
    })
    assert.equals(1, #normalized)

    local ok, err = pcall(function()
      spec.normalize_specs({
        { src = '/tmp/one', name = 'fixture' },
        { src = '/tmp/two', name = 'fixture' },
      })
    end)
    assert.falsy(ok)
    assert.truthy(err:match('conflicting `src` for parser `fixture`'))

    ok, err = pcall(function()
      spec.normalize_specs({
        { src = '/tmp/tree-sitter-fixture', name = 'fixture', version = 'one' },
        { src = '/tmp/tree-sitter-fixture', name = 'fixture', version = 'two' },
      })
    end)
    assert.falsy(ok)
    assert.truthy(err:match('conflicting `version` for parser `fixture`'))

    ok, err = pcall(function()
      spec.normalize_specs({
        { src = '/tmp/tree-sitter-fixture', name = 'fixture', branch = 'one' },
        { src = '/tmp/tree-sitter-fixture', name = 'fixture', branch = 'two' },
      })
    end)
    assert.falsy(ok)
    assert.truthy(err:match('conflicting `branch` for parser `fixture`'))
  end)

  it('requires list inputs for spec lists', function()
    local spec = require('ts-pack.spec')

    local ok, err = pcall(function()
      spec.normalize_specs({ src = '/tmp/tree-sitter-fixture' })
    end)

    assert.falsy(ok)
    assert.truthy(err:match('`specs` must be a list'))
  end)
end)
