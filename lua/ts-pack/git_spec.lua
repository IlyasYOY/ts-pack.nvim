describe('ts-pack.git', function()
  it('resolves refs from version target, lockfile entry, then spec version', function()
    local git = require('ts-pack.git')
    local spec = { version = 'main' }

    assert.equals('main', git.resolve_ref(spec, { rev = 'locked' }, { target = 'version' }))
    assert.equals('locked', git.resolve_ref(spec, { rev = 'locked' }))
    assert.equals('main', git.resolve_ref(spec))
    assert.equals('origin/next', git.resolve_ref({ branch = 'next' }))
  end)

  it('returns local paths without taking checkout locks', function()
    local git = require('ts-pack.git')

    assert.equals(
      '/tmp/tree-sitter-fixture',
      git.ensure_checkout({ name = 'fixture', path = '/tmp/tree-sitter-fixture' }, 'HEAD')
    )
  end)

  it('clones a parser branch when one is configured', function()
    local git = require('ts-pack.git')
    local parser = {
      name = 'branch-fixture',
      src = 'https://example.test/tree-sitter-fixture',
      branch = 'gh-pages',
    }
    local target = git.checkout_path(parser)
    local calls = {}
    local original = git.git
    vim.fn.delete(target, 'rf')

    git.git = function(args, cwd)
      calls[#calls + 1] = { args = vim.deepcopy(args), cwd = cwd }
      return { stdout = '' }
    end

    local ok, err = pcall(function()
      git.ensure_checkout(parser, git.resolve_ref(parser))
    end)
    git.git = original
    vim.fn.delete(target, 'rf')

    assert.truthy(ok, err)
    assert.same({
      'clone',
      '--filter=blob:none',
      '--branch',
      'gh-pages',
      'https://example.test/tree-sitter-fixture',
      target,
    }, calls[1].args)
    assert.same({ 'checkout', '--detach', 'origin/gh-pages' }, calls[2].args)
  end)

  it('fetches a configured parser branch', function()
    local git = require('ts-pack.git')
    local parser = {
      name = 'branch-fixture',
      src = 'https://example.test/tree-sitter-fixture',
      branch = 'gh-pages',
    }
    local target = git.checkout_path(parser)
    local calls = {}
    local original = git.git
    vim.fn.mkdir(target, 'p')

    git.git = function(args, cwd)
      calls[#calls + 1] = { args = vim.deepcopy(args), cwd = cwd }
      return { stdout = '' }
    end

    local ok, err = pcall(function()
      git.ensure_checkout(parser, git.resolve_ref(parser))
    end)
    git.git = original
    vim.fn.delete(target, 'rf')

    assert.truthy(ok, err)
    assert.same({
      'fetch',
      '--tags',
      '--force',
      'origin',
      '+refs/heads/gh-pages:refs/remotes/origin/gh-pages',
    }, calls[1].args)
    assert.same({ 'checkout', '--detach', 'origin/gh-pages' }, calls[2].args)
  end)
end)
