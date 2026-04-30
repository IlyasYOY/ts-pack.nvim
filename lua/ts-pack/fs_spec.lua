local function test_home()
  return vim.env.TS_PACK_TEST_HOME or vim.fs.joinpath(vim.fn.getcwd(), '.test-home')
end

local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(lines, path)
end

describe('ts-pack.fs', function()
  it('roundtrips json and returns fallbacks for absent or invalid files', function()
    local fs = require('ts-pack.fs')
    local target = vim.fs.joinpath(test_home(), 'fs', 'value.json')

    assert.same({ missing = true }, fs.read_json(target, { missing = true }))

    write(target, { '{' })
    assert.same({ invalid = true }, fs.read_json(target, { invalid = true }))

    fs.write_json(target, { parsers = { lua = { rev = 'abc' } } })
    assert.same({ parsers = { lua = { rev = 'abc' } } }, fs.read_json(target, {}))
  end)

  it('writes indented sorted json like nvim pack lockfiles', function()
    local fs = require('ts-pack.fs')
    local target = vim.fs.joinpath(test_home(), 'fs', 'formatted.json')

    fs.write_json(target, {
      parsers = {
        lua = {
          version = 'main',
          rev = 'abc',
          src = 'https://example.invalid/tree-sitter-lua',
        },
      },
    })

    assert.same({
      '{',
      '  "parsers": {',
      '    "lua": {',
      '      "rev": "abc",',
      '      "src": "https://example.invalid/tree-sitter-lua",',
      '      "version": "main"',
      '    }',
      '  }',
      '}',
    }, vim.fn.readfile(target))
  end)

  it('loads malformed lockfiles with an empty parsers table', function()
    local fs = require('ts-pack.fs')
    local path = require('ts-pack.path')

    write(path.lockfile(), { '{"parsers": "bad"}' })

    assert.same({ parsers = {} }, fs.load_lock())
  end)

  it('copies files and directory trees', function()
    local fs = require('ts-pack.fs')
    local root = vim.fs.joinpath(test_home(), 'fs-copy')
    local src = vim.fs.joinpath(root, 'src')
    local dst = vim.fs.joinpath(root, 'dst')

    write(vim.fs.joinpath(src, 'highlights.scm'), { '; root' })
    write(vim.fs.joinpath(src, 'nested', 'locals.scm'), { '; nested' })

    fs.copy_tree(src, dst)

    assert.same({ '; root' }, vim.fn.readfile(vim.fs.joinpath(dst, 'highlights.scm')))
    assert.same({ '; nested' }, vim.fn.readfile(vim.fs.joinpath(dst, 'nested', 'locals.scm')))
  end)

  it('errors when copying a missing tree', function()
    local fs = require('ts-pack.fs')

    local ok, err = pcall(function()
      fs.copy_tree(vim.fs.joinpath(test_home(), 'missing'), vim.fs.joinpath(test_home(), 'dst'))
    end)

    assert.falsy(ok)
    assert.truthy(err:match('query source does not exist'))
  end)
end)
