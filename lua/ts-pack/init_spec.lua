local function fresh(root)
  package.loaded['ts-pack'] = nil
  local ts_pack = require('ts-pack')
  ts_pack.setup({
    root = root .. '/data/ts-pack',
    lockfile = root .. '/config/ts-pack-lock.json',
  })
  return ts_pack
end

local function temp_root(name)
  local root = vim.fn.stdpath('cache') .. '/' .. name
  vim.fn.delete(root, 'rf')
  vim.fn.mkdir(root, 'p')
  return root
end

describe('ts-pack', function()
  it('loads the public module', function()
    local ts_pack = require('ts-pack')

    assert.equals('table', type(ts_pack))
    assert.equals('function', type(ts_pack.setup))
    assert.equals('function', type(ts_pack.add))
    assert.equals('function', type(ts_pack.get))
    assert.equals('function', type(ts_pack.update))
    assert.equals('function', type(ts_pack.del))
  end)

  it('normalizes specs and rejects invalid input', function()
    local ts_pack = fresh(temp_root('unit-normalize'))

    assert.error_matches('id must be', function()
      ts_pack.add({ { src = '/tmp/parser' } })
    end)

    assert.error_matches('src must be', function()
      ts_pack.add({ { id = 'bad', src = 1 } })
    end)
  end)

  it('reads an absent lockfile as empty state', function()
    local root = temp_root('unit-empty-lock')
    local ts_pack = fresh(root)

    assert.same({}, ts_pack.get())
    assert.falsy(vim.uv.fs_stat(root .. '/config/ts-pack-lock.json'))
  end)
end)
