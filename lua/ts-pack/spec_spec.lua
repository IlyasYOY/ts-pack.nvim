describe('ts-pack.spec', function()
  it('normalizes string specs and strips tree-sitter prefixes', function()
    local spec = require('ts-pack.spec')

    local parser = spec.normalize_spec('https://github.com/tree-sitter/tree-sitter-lua.git')

    assert.equals('https://github.com/tree-sitter/tree-sitter-lua.git', parser.src)
    assert.equals('lua', parser.name)
  end)

  it('keeps supported parser build fields', function()
    local spec = require('ts-pack.spec')

    local parser = spec.normalize_spec({
      src = '/tmp/tree-sitter-fixture',
      name = 'fixture',
      version = 'HEAD',
      data = { enabled = true },
      location = 'grammar',
      path = '/tmp/tree-sitter-fixture',
      queries = 'queries/fixture',
      generate = true,
      generate_from_json = false,
    })

    assert.same({
      src = '/tmp/tree-sitter-fixture',
      name = 'fixture',
      version = 'HEAD',
      data = { enabled = true },
      location = 'grammar',
      path = '/tmp/tree-sitter-fixture',
      queries = 'queries/fixture',
      generate = true,
      generate_from_json = false,
    }, parser)
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
