describe('ts-pack.git', function()
  it('resolves refs from version target, lockfile entry, then spec version', function()
    local git = require('ts-pack.git')
    local spec = { version = 'main' }

    assert.equals('main', git.resolve_ref(spec, { rev = 'locked' }, { target = 'version' }))
    assert.equals('locked', git.resolve_ref(spec, { rev = 'locked' }))
    assert.equals('main', git.resolve_ref(spec))
  end)

  it('returns local paths without taking checkout locks', function()
    local git = require('ts-pack.git')

    assert.equals(
      '/tmp/tree-sitter-fixture',
      git.ensure_checkout({ name = 'fixture', path = '/tmp/tree-sitter-fixture' }, 'HEAD')
    )
  end)
end)
