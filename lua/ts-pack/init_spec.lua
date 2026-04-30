local function run(cmd, opts)
  local result = vim
    .system(cmd, {
      cwd = opts and opts.cwd or nil,
      text = true,
    })
    :wait()
  if result.code ~= 0 then
    error(table.concat(cmd, ' ') .. '\n' .. (result.stderr or result.stdout or ''), 2)
  end
  return result
end

local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(lines, path)
end

local function test_home()
  return vim.env.TS_PACK_TEST_HOME or vim.fs.joinpath(vim.fn.getcwd(), '.test-home')
end

local function reset()
  vim.fn.delete(test_home(), 'rf')
  vim.fn.mkdir(vim.env.XDG_CONFIG_HOME, 'p')
  vim.fn.mkdir(vim.env.XDG_DATA_HOME, 'p')
  vim.fn.mkdir(vim.env.XDG_CACHE_HOME, 'p')
  vim.fn.mkdir(vim.env.XDG_STATE_HOME, 'p')
  package.loaded['ts-pack'] = nil
end

local function make_parser_repo(lang)
  local root = vim.fs.joinpath(test_home(), 'fixtures', 'tree-sitter-' .. lang)
  vim.fn.mkdir(vim.fs.joinpath(root, 'src'), 'p')
  write(vim.fs.joinpath(root, 'src', 'parser.c'), {
    'void *tree_sitter_' .. lang .. '(void) {',
    '  return 0;',
    '}',
  })
  write(vim.fs.joinpath(root, 'queries', lang, 'highlights.scm'), {
    '; fixture query',
  })
  run({ 'git', 'init' }, { cwd = root })
  run({ 'git', 'config', 'user.name', 'ts-pack tests' }, { cwd = root })
  run({ 'git', 'config', 'user.email', 'ts-pack@example.invalid' }, { cwd = root })
  run({ 'git', 'add', '.' }, { cwd = root })
  run({ 'git', 'commit', '-m', 'initial parser' }, { cwd = root })
  local rev = vim.trim(run({ 'git', 'rev-parse', 'HEAD' }, { cwd = root }).stdout)
  return root, rev
end

local function commit_second_revision(root)
  write(vim.fs.joinpath(root, 'README.md'), { 'second revision' })
  run({ 'git', 'add', '.' }, { cwd = root })
  run({ 'git', 'commit', '-m', 'second revision' }, { cwd = root })
  return vim.trim(run({ 'git', 'rev-parse', 'HEAD' }, { cwd = root }).stdout)
end

local function lockfile()
  return vim.fs.joinpath(vim.fn.stdpath('config'), 'ts-pack-lock.json')
end

local function read_lock()
  return vim.json.decode(table.concat(vim.fn.readfile(lockfile()), '\n'))
end

before_each(reset)

describe('ts-pack', function()
  it('loads only the Lua parser management API', function()
    local ts_pack = require('ts-pack')
    assert.equals('function', type(ts_pack.add))
    assert.equals('function', type(ts_pack.del))
    assert.equals('function', type(ts_pack.get))
    assert.equals('function', type(ts_pack.update))
    assert.falsy(ts_pack.setup)
  end)

  it('does not create user commands', function()
    local before = vim.api.nvim_get_commands({})
    require('ts-pack')
    local after = vim.api.nvim_get_commands({})
    assert.same(before.TSInstall, after.TSInstall)
    assert.same(before.TSUpdate, after.TSUpdate)
    assert.same(before.TSUninstall, after.TSUninstall)
  end)

  it('normalizes parser specs from vim.pack-style fields and parser build fields', function()
    local repo = make_parser_repo('fixture')
    local ts_pack = require('ts-pack')

    ts_pack.add({
      {
        src = repo,
        version = 'HEAD',
        queries = 'queries/fixture',
        generate = false,
        generate_from_json = true,
      },
    })

    local info = ts_pack.get({ 'fixture' }, { info = false })[1]
    assert.truthy(info.active)
    assert.equals(repo, info.spec.src)
    assert.equals('fixture', info.spec.name)
    assert.equals('queries/fixture', info.spec.queries)
    assert.equals(false, info.spec.generate)
    assert.equals(true, info.spec.generate_from_json)
  end)

  it('installs only user-provided unknown parser specs', function()
    local ts_pack = require('ts-pack')
    local ok, err = pcall(function()
      ts_pack.update({ 'not-provided' })
    end)
    assert.falsy(ok)
    assert.truthy(err:match('not active'))
  end)

  it('uses stdpath config for the lockfile and writes add results', function()
    local repo, rev = make_parser_repo('fixture')
    local ts_pack = require('ts-pack')

    ts_pack.add({
      { src = repo, name = 'fixture', version = 'HEAD', queries = 'queries/fixture' },
    })

    local lock = read_lock()
    assert.equals(lockfile(), vim.fs.joinpath(vim.fn.stdpath('config'), 'ts-pack-lock.json'))
    assert.equals(repo, lock.parsers.fixture.src)
    assert.equals(rev, lock.parsers.fixture.rev)
    assert.equals('HEAD', lock.parsers.fixture.version)
    assert.truthy(
      vim.uv.fs_stat(vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'parser', 'fixture.so'))
    )
    assert.truthy(
      vim.uv.fs_stat(
        vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'queries', 'fixture', 'highlights.scm')
      )
    )
  end)

  it('updates to the lockfile revision when target is lockfile', function()
    local repo, rev = make_parser_repo('fixture')
    local ts_pack = require('ts-pack')

    ts_pack.add({
      { src = repo, name = 'fixture', version = rev },
    })
    commit_second_revision(repo)
    ts_pack.update({ 'fixture' }, { target = 'lockfile' })

    local lock = read_lock()
    assert.equals(rev, lock.parsers.fixture.rev)
  end)

  it('respects offline mode for missing checkouts', function()
    local repo = make_parser_repo('fixture')
    local ts_pack = require('ts-pack')

    local ok, err = pcall(function()
      ts_pack.add({
        { src = repo, name = 'fixture' },
      }, { offline = true })
    end)

    assert.falsy(ok)
    assert.truthy(err:match('offline'))
  end)

  it('reports active and installed parsers from get', function()
    local repo = make_parser_repo('fixture')
    local ts_pack = require('ts-pack')

    ts_pack.add({
      { src = repo, name = 'fixture', data = { enabled = true } },
    })

    local info = ts_pack.get({ 'fixture' })[1]
    assert.truthy(info.active)
    assert.truthy(info.installed)
    assert.equals(repo, info.src)
    assert.same({ enabled = true }, info.data)
    assert.truthy(info.rev)
  end)

  it('deletes parser, query, and lockfile artifacts', function()
    local repo = make_parser_repo('fixture')
    local ts_pack = require('ts-pack')

    ts_pack.add({
      { src = repo, name = 'fixture', queries = 'queries/fixture' },
    })
    ts_pack.del({ 'fixture' })

    assert.falsy(
      vim.uv.fs_stat(vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'parser', 'fixture.so'))
    )
    assert.falsy(
      vim.uv.fs_stat(vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'queries', 'fixture'))
    )
    assert.falsy(read_lock().parsers.fixture)
    assert.falsy(ts_pack.get({ 'fixture' }, { info = false })[1].active)
  end)

  it('registers parsers and starts coroutine async add without installing inline', function()
    local original_system = vim.system
    local calls = {}
    vim.system = function(cmd, opts, _)
      calls[#calls + 1] = { cmd = cmd, opts = opts }
      return {}
    end

    local ok, result = pcall(function()
      local ts_pack = require('ts-pack')
      return ts_pack.add({
        { src = '/tmp/tree-sitter-fixture', name = 'fixture', version = 'HEAD' },
      }, { async = true, info = false })
    end)
    vim.system = original_system

    assert.truthy(ok)
    assert.equals(1, #calls)
    assert.equals('git', calls[1].cmd[1])
    assert.equals('clone', calls[1].cmd[2])
    assert.truthy(result[1].active)
    assert.truthy(result[1].pending)
    assert.falsy(
      vim.uv.fs_stat(vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'parser', 'fixture.so'))
    )
  end)

  it('logs only successfully installed parsers during async add', function()
    local repo = make_parser_repo('fixture')
    local original_notify = vim.notify
    local messages = {}
    vim.notify = function(message, level)
      messages[#messages + 1] = { message = message, level = level }
    end

    local ts_pack = require('ts-pack')
    ts_pack.add({
      { src = repo, name = 'fixture', version = 'HEAD' },
    }, { async = true })

    local done = vim.wait(10000, function()
      return vim.uv.fs_stat(vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'parser', 'fixture.so'))
        ~= nil
    end)
    vim.notify = original_notify

    assert.truthy(done)
    assert.equals(1, #messages)
    assert.equals('ts-pack installed parser `fixture`', messages[1].message)
    assert.equals(vim.log.levels.INFO, messages[1].level)
  end)
end)
