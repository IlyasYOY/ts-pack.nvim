local function test_home()
  return vim.env.TS_PACK_TEST_HOME or vim.fs.joinpath(vim.fn.getcwd(), '.test-home')
end

describe('ts-pack.path', function()
  it('resolves default runtime and lockfile paths from stdpath', function()
    local path = require('ts-pack.path')

    assert.equals(vim.fs.joinpath(vim.fn.stdpath('data'), 'site'), path.default_site_dir())
    assert.equals(vim.fs.joinpath(vim.fn.stdpath('cache'), 'ts-pack'), path.cache_dir())
    assert.equals(vim.fs.joinpath(vim.fn.stdpath('config'), 'ts-pack-lock.json'), path.lockfile())
    assert.equals(
      vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'parser', 'lua.so'),
      path.parser_path('lua')
    )
    assert.equals(
      vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'parser-info', 'lua.revision'),
      path.parser_revision_path('lua')
    )
    assert.equals(
      vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'queries', 'lua'),
      path.query_path('lua')
    )
  end)

  it('uses opts.dir as the parser artifact root', function()
    local path = require('ts-pack.path')
    local root = vim.fs.joinpath(test_home(), 'custom-site')

    assert.equals(vim.fs.joinpath(root, 'parser'), path.parser_dir({ dir = root }))
    assert.equals(vim.fs.joinpath(root, 'parser-info'), path.parser_info_dir({ dir = root }))
    assert.equals(vim.fs.joinpath(root, 'queries'), path.queries_dir({ dir = root }))
    assert.equals(
      vim.fs.joinpath(root, 'parser', 'lua.so'),
      path.parser_path('lua', { dir = root })
    )
  end)
end)
