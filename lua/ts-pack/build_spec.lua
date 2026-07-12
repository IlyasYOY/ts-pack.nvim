describe('ts-pack.build', function()
  local fixture_count = 0

  local function write(target, lines)
    vim.fn.mkdir(vim.fs.dirname(target), 'p')
    vim.fn.writefile(lines, target)
  end

  local function make_parser_root(extra_sources)
    local work = vim.env.TS_PACK_TEST_WORK
      or vim.fs.joinpath(vim.fn.getcwd(), '.test-work', 'fixtures')
    fixture_count = fixture_count + 1
    local fixture_name = ('build-parser-%d-%d'):format(vim.fn.getpid(), fixture_count)
    local root = vim.fs.joinpath(work, fixture_name)
    vim.fn.delete(root, 'rf')
    write(vim.fs.joinpath(root, 'src', 'parser.c'), {
      'void *tree_sitter_fixture(void) {',
      '  return 0;',
      '}',
    })
    for name, lines in pairs(extra_sources or {}) do
      write(vim.fs.joinpath(root, 'src', name), lines)
    end
    return root
  end

  it('generates from grammar json by default and grammar js when requested', function()
    local build = require('ts-pack.build')
    local process = require('ts-pack.process')
    local original_system = process.system
    local calls = {}

    process.system = function(cmd, opts)
      calls[#calls + 1] = { cmd = cmd, opts = opts }
      return { code = 0 }
    end

    build.generate({ generate = true }, '/tmp/parser')
    build.generate({ generate = true, generate_from_json = false }, '/tmp/parser')
    build.generate({ generate = false }, '/tmp/parser')
    process.system = original_system

    assert.equals(2, #calls)
    assert.equals('src/grammar.json', calls[1].cmd[#calls[1].cmd])
    assert.equals('src/grammar.js', calls[2].cmd[#calls[2].cmd])
    assert.equals('/tmp/parser', calls[1].opts.cwd)
    assert.equals('native', calls[1].opts.env.TREE_SITTER_JS_RUNTIME)
  end)

  it('falls back to generated C sources when tree-sitter build cannot spawn', function()
    local build = require('ts-pack.build')
    local process = require('ts-pack.process')
    local root = make_parser_root()
    local original_system_result = process.system_result
    local original_system = process.system
    local original_cc = vim.env.CC
    local calls = {}

    vim.env.CC = 'test-cc'
    process.system_result = function(cmd, opts)
      assert.equals('tree-sitter', cmd[1])
      assert.equals(root, opts.cwd)
      return { code = 1, stderr = 'ENOENT: tree-sitter' }
    end
    process.system = function(cmd, opts)
      calls[#calls + 1] = { cmd = cmd, opts = opts }
      return { code = 0 }
    end

    local ok, err = pcall(function()
      build.compile(root)
    end)

    process.system_result = original_system_result
    process.system = original_system
    vim.env.CC = original_cc
    vim.fn.delete(root, 'rf')

    assert.truthy(ok)
    assert.falsy(err)
    assert.equals(2, #calls)
    assert.equals('test-cc', calls[1].cmd[1])
    assert.equals('src/parser.c', calls[1].cmd[6])
    assert.equals('test-cc', calls[2].cmd[1])
  end)

  it('links fallback builds with CXX when a C++ scanner is present', function()
    local build = require('ts-pack.build')
    local process = require('ts-pack.process')
    local root = make_parser_root({
      ['scanner.cc'] = {
        '#include <string>',
        'void tree_sitter_fixture_external_scanner_create(void) { std::string value; }',
      },
    })
    local original_system_result = process.system_result
    local original_system = process.system
    local original_cc = vim.env.CC
    local original_cxx = vim.env.CXX
    local calls = {}

    vim.env.CC = 'test-cc'
    vim.env.CXX = 'test-cxx'
    process.system_result = function()
      return { code = 1, stderr = 'tree-sitter build failed' }
    end
    process.system = function(cmd, opts)
      calls[#calls + 1] = { cmd = cmd, opts = opts }
      return { code = 0 }
    end

    local ok, err = pcall(function()
      build.compile(root)
    end)

    process.system_result = original_system_result
    process.system = original_system
    vim.env.CC = original_cc
    vim.env.CXX = original_cxx
    vim.fn.delete(root, 'rf')

    assert.truthy(ok)
    assert.falsy(err)
    assert.equals(3, #calls)
    assert.equals('test-cc', calls[1].cmd[1])
    assert.equals('test-cxx', calls[2].cmd[1])
    assert.equals('src/scanner.cc', calls[2].cmd[6])
    assert.equals('test-cxx', calls[3].cmd[1])
    assert.equals('scanner.cc.o', calls[3].cmd[#calls[3].cmd])
  end)
end)
