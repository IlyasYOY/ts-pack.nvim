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

  it('writes owner metadata for checkout locks', function()
    local git = require('ts-pack.git')
    local parser = { name = 'fixture' }
    local lock = git.acquire_checkout_lock(parser)
    local owner_path = vim.fs.joinpath(lock, 'owner.json')
    local owner = vim.json.decode(table.concat(vim.fn.readfile(owner_path), '\n'))

    git.release_checkout_lock(lock)

    assert.equals('fixture', owner.parser)
    assert.equals(lock, owner.lock)
    assert.equals(git.checkout_path(parser), owner.checkout)
    assert.equals(vim.fn.getcwd(), owner.cwd)
    assert.equals('number', type(owner.pid))
    assert.equals('string', type(owner.created_at))
  end)

  it('reports existing checkout locks with owner metadata and recovery guidance', function()
    local git = require('ts-pack.git')
    local parser = { name = 'fixture' }
    local lock = git.acquire_checkout_lock(parser)

    local ok, err = pcall(function()
      git.acquire_checkout_lock(parser)
    end)
    git.release_checkout_lock(lock)

    assert.falsy(ok)
    assert.truthy(err:match('parser `fixture` checkout lock already exists'))
    assert.truthy(err:match(vim.pesc(lock)))
    assert.truthy(err:match('lock owner:'))
    assert.truthy(err:match('pid='))
    assert.truthy(err:match('created_at='))
    assert.truthy(err:match('manual recovery: rm %-rf'))
    assert.truthy(err:match('nvim, git, or tree%-sitter'))
  end)

  it('treats libuv EEXIST variants as existing checkout locks', function()
    local git = require('ts-pack.git')
    local original = vim.uv.fs_mkdir
    local parser = { name = 'fixture' }

    for _, mkdir_error in ipairs({
      'EEXIST',
      'EEXIST: file already exists: /tmp/fixture.lock',
    }) do
      vim.uv.fs_mkdir = function()
        return nil, mkdir_error
      end

      local ok, err = pcall(function()
        git.acquire_checkout_lock(parser)
      end)

      assert.falsy(ok)
      assert.truthy(err:match('parser `fixture` checkout lock already exists'))
      assert.truthy(err:match('manual recovery: rm %-rf'))
    end

    vim.uv.fs_mkdir = original
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
