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

local function make_built_parser_root(lang)
  local root = vim.fs.joinpath(test_home(), 'fixtures', 'built-' .. lang)
  vim.fn.mkdir(root, 'p')
  write(vim.fs.joinpath(root, 'parser.so'), { 'parser for ' .. lang })
  return root
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

  it('fails before git checkout when a cached parser has an index lock', function()
    local repo = make_parser_repo('fixture')
    local cache = vim.fs.joinpath(vim.fn.stdpath('cache'), 'ts-pack', 'fixture')
    local index_lock = vim.fs.joinpath(cache, '.git', 'index.lock')
    write(index_lock, { 'locked' })

    local ts_pack = require('ts-pack')
    local ok, err = pcall(function()
      ts_pack.add({
        { src = repo, name = 'fixture', version = 'HEAD' },
      })
    end)

    assert.falsy(ok)
    assert.truthy(err:match('parser `fixture` checkout is locked'))
    assert.truthy(err:match(vim.pesc(index_lock)))
    assert.falsy(
      vim.uv.fs_stat(vim.fs.joinpath(vim.fn.stdpath('cache'), 'ts-pack', '.locks', 'fixture.lock'))
    )
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

  it('registers filetype metadata for skipped installed parsers', function()
    local repo = make_parser_repo('fixture_skip')
    local ts_pack = require('ts-pack')

    ts_pack.add({
      { src = repo, name = 'fixture_skip' },
    }, { info = false })
    ts_pack.add({
      {
        src = repo,
        name = 'fixture_skip',
        data = { filetype = 'fixture-skip-ft' },
      },
    }, { info = false })

    assert.equals('fixture_skip', vim.treesitter.language.get_lang('fixture-skip-ft'))
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

  it('registers filetype metadata immediately during async add', function()
    local original_system = vim.system
    vim.system = function()
      return {}
    end

    local ts_pack = require('ts-pack')
    ts_pack.add({
      {
        src = '/tmp/tree-sitter-fixture-async-ft',
        name = 'fixture_async_ft',
        data = { filetype = { 'fixture-async-one', 'fixture-async-two' } },
      },
    }, { async = true, info = false })
    vim.system = original_system

    assert.equals('fixture_async_ft', vim.treesitter.language.get_lang('fixture-async-one'))
    assert.equals('fixture_async_ft', vim.treesitter.language.get_lang('fixture-async-two'))
  end)

  it('starts async parser installs in parallel', function()
    local original_system = vim.system
    local original_notify = vim.notify
    local original_available_parallelism = vim.uv.available_parallelism
    local calls = {}
    local callbacks = {}
    local messages = {}

    vim.uv.available_parallelism = function()
      return 2
    end
    vim.system = function(cmd, opts, callback)
      calls[#calls + 1] = { cmd = cmd, opts = opts, callback = callback }
      callbacks[#callbacks + 1] = callback
      return {}
    end
    vim.notify = function(message, level)
      messages[#messages + 1] = { message = message, level = level }
    end

    local ts_pack = require('ts-pack')
    ts_pack.add({
      { src = '/tmp/tree-sitter-first', name = 'first', version = 'HEAD' },
      { src = '/tmp/tree-sitter-second', name = 'second', version = 'HEAD' },
      { src = '/tmp/tree-sitter-third', name = 'third', version = 'HEAD' },
    }, { async = true, info = false })

    assert.equals(2, #calls)
    assert.equals('clone', calls[1].cmd[2])
    assert.equals('clone', calls[2].cmd[2])

    callbacks[1]({ code = 1, stderr = 'first failed' })
    callbacks[2]({ code = 1, stderr = 'second failed' })
    local failed = vim.wait(1000, function()
      return #messages == 1
    end)

    vim.uv.available_parallelism = original_available_parallelism
    vim.system = original_system
    vim.notify = original_notify

    assert.truthy(failed)
    assert.equals(vim.log.levels.ERROR, messages[1].level)
    assert.truthy(messages[1].message:match('ts%-pack async add failed'))
  end)

  it('caps async workers to pending parser count', function()
    local original_system = vim.system
    local original_notify = vim.notify
    local original_available_parallelism = vim.uv.available_parallelism
    local calls = {}
    local callbacks = {}
    local messages = {}

    vim.uv.available_parallelism = function()
      return 8
    end
    vim.system = function(cmd, opts, callback)
      calls[#calls + 1] = { cmd = cmd, opts = opts, callback = callback }
      callbacks[#callbacks + 1] = callback
      return {}
    end
    vim.notify = function(message, level)
      messages[#messages + 1] = { message = message, level = level }
    end

    local ts_pack = require('ts-pack')
    ts_pack.add({
      { src = '/tmp/tree-sitter-first', name = 'first', version = 'HEAD' },
      { src = '/tmp/tree-sitter-second', name = 'second', version = 'HEAD' },
    }, { async = true, info = false })

    assert.equals(2, #calls)

    callbacks[1]({ code = 1, stderr = 'first failed' })
    callbacks[2]({ code = 1, stderr = 'second failed' })
    local failed = vim.wait(1000, function()
      return #messages == 1
    end)

    vim.uv.available_parallelism = original_available_parallelism
    vim.system = original_system
    vim.notify = original_notify

    assert.truthy(failed)
    assert.equals(vim.log.levels.ERROR, messages[1].level)
    assert.truthy(messages[1].message:match('ts%-pack async add failed'))
  end)

  it('logs installed parsers once during async add', function()
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
    assert.equals('ts-pack installed parser: `fixture`', messages[1].message)
    assert.equals(vim.log.levels.INFO, messages[1].level)
  end)

  it('logs all installed parsers in one async summary', function()
    local first = make_parser_repo('first')
    local second = make_parser_repo('second')
    local original_notify = vim.notify
    local messages = {}
    vim.notify = function(message, level)
      messages[#messages + 1] = { message = message, level = level }
    end

    local ts_pack = require('ts-pack')
    ts_pack.add({
      { src = first, name = 'first', version = 'HEAD' },
      { src = second, name = 'second', version = 'HEAD' },
    }, { async = true })

    local done = vim.wait(10000, function()
      return vim.uv.fs_stat(vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'parser', 'first.so'))
          ~= nil
        and vim.uv.fs_stat(vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'parser', 'second.so'))
          ~= nil
    end)
    vim.notify = original_notify

    assert.truthy(done)
    assert.equals(1, #messages)
    assert.equals('ts-pack installed parsers: `first`, `second`', messages[1].message)
    assert.equals(vim.log.levels.INFO, messages[1].level)
  end)

  it('keeps all async parser entries in the lockfile', function()
    local first = make_parser_repo('first')
    local second = make_parser_repo('second')
    local original_available_parallelism = vim.uv.available_parallelism

    vim.uv.available_parallelism = function()
      return 2
    end

    local ts_pack = require('ts-pack')
    ts_pack.add({
      { src = first, name = 'first', version = 'HEAD' },
      { src = second, name = 'second', version = 'HEAD' },
    }, { async = true })

    local done = vim.wait(10000, function()
      local parser_dir = vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'parser')
      return vim.uv.fs_stat(vim.fs.joinpath(parser_dir, 'first.so')) ~= nil
        and vim.uv.fs_stat(vim.fs.joinpath(parser_dir, 'second.so')) ~= nil
    end)

    vim.uv.available_parallelism = original_available_parallelism

    assert.truthy(done)
    local lock = read_lock()
    assert.equals(first, lock.parsers.first.src)
    assert.equals(second, lock.parsers.second.src)
  end)

  it('logs partial async installs before an async failure', function()
    local repo = make_parser_repo('fixture')
    local original_notify = vim.notify
    local messages = {}
    vim.notify = function(message, level)
      messages[#messages + 1] = { message = message, level = level }
    end

    local ts_pack = require('ts-pack')
    ts_pack.add({
      { src = repo, name = 'fixture', version = 'HEAD' },
      { src = '/definitely/missing/tree-sitter-broken', name = 'broken', version = 'HEAD' },
    }, { async = true })

    local done = vim.wait(10000, function()
      return #messages == 2
    end)
    vim.notify = original_notify

    assert.truthy(done)
    assert.equals('ts-pack installed parser: `fixture`', messages[1].message)
    assert.equals(vim.log.levels.INFO, messages[1].level)
    assert.equals(vim.log.levels.ERROR, messages[2].level)
    assert.truthy(messages[2].message:match('ts%-pack async add failed'))
  end)

  it('does not log when add skips already installed parsers', function()
    local repo = make_parser_repo('fixture')
    local ts_pack = require('ts-pack')
    ts_pack.add({
      { src = repo, name = 'fixture', version = 'HEAD' },
    })

    local original_notify = vim.notify
    local messages = {}
    vim.notify = function(message, level)
      messages[#messages + 1] = { message = message, level = level }
    end

    ts_pack.add({
      { src = repo, name = 'fixture', version = 'HEAD' },
    })
    vim.notify = original_notify

    assert.equals(0, #messages)
  end)

  it('logs installed parsers once during sync add', function()
    local first = make_parser_repo('first')
    local second = make_parser_repo('second')
    local original_notify = vim.notify
    local messages = {}
    vim.notify = function(message, level)
      messages[#messages + 1] = { message = message, level = level }
    end

    local ts_pack = require('ts-pack')
    ts_pack.add({
      { src = first, name = 'first', version = 'HEAD' },
      { src = second, name = 'second', version = 'HEAD' },
    })
    vim.notify = original_notify

    assert.equals(1, #messages)
    assert.equals('ts-pack installed parsers: `first`, `second`', messages[1].message)
    assert.equals(vim.log.levels.INFO, messages[1].level)
  end)

  it('starts sync parser installs in parallel and waits for completion', function()
    local original_system = vim.system
    local original_available_parallelism = vim.uv.available_parallelism
    local calls = {}
    local in_flight = 0
    local max_in_flight = 0

    vim.uv.available_parallelism = function()
      return 2
    end
    vim.system = function(cmd, opts, callback)
      calls[#calls + 1] = { cmd = cmd, opts = opts, callback = callback }
      in_flight = in_flight + 1
      max_in_flight = math.max(max_in_flight, in_flight)
      vim.schedule(function()
        in_flight = in_flight - 1
        callback({ code = 0, stdout = '', stderr = '' })
      end)
      return {}
    end

    local ts_pack = require('ts-pack')
    local ok, result = pcall(function()
      return ts_pack.add({
        {
          src = 'file://first',
          path = make_built_parser_root('first'),
          name = 'first',
          generate = false,
        },
        {
          src = 'file://second',
          path = make_built_parser_root('second'),
          name = 'second',
          generate = false,
        },
        {
          src = 'file://third',
          path = make_built_parser_root('third'),
          name = 'third',
          generate = false,
        },
      }, { info = false })
    end)

    vim.uv.available_parallelism = original_available_parallelism
    vim.system = original_system

    assert.truthy(ok)
    assert.equals(3, #calls)
    assert.equals(2, max_in_flight)
    assert.equals('first', result[1].spec.name)
    assert.equals('second', result[2].spec.name)
    assert.equals('third', result[3].spec.name)
    assert.truthy(
      vim.uv.fs_stat(vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'parser', 'first.so'))
    )
    assert.truthy(
      vim.uv.fs_stat(vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'parser', 'second.so'))
    )
    assert.truthy(
      vim.uv.fs_stat(vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'parser', 'third.so'))
    )
  end)

  it('keeps all sync parser entries in the lockfile', function()
    local first = make_parser_repo('first')
    local second = make_parser_repo('second')
    local original_available_parallelism = vim.uv.available_parallelism

    vim.uv.available_parallelism = function()
      return 2
    end

    local ts_pack = require('ts-pack')
    ts_pack.add({
      { src = first, name = 'first', version = 'HEAD' },
      { src = second, name = 'second', version = 'HEAD' },
    })

    vim.uv.available_parallelism = original_available_parallelism

    local lock = read_lock()
    assert.equals(first, lock.parsers.first.src)
    assert.equals(second, lock.parsers.second.src)
  end)

  it('logs installed parsers once during update', function()
    local repo = make_parser_repo('fixture')
    local ts_pack = require('ts-pack')
    ts_pack.add({
      { src = repo, name = 'fixture', version = 'HEAD' },
    })

    local original_notify = vim.notify
    local messages = {}
    vim.notify = function(message, level)
      messages[#messages + 1] = { message = message, level = level }
    end

    ts_pack.update({ 'fixture' })
    vim.notify = original_notify

    assert.equals(1, #messages)
    assert.equals('ts-pack installed parser: `fixture`', messages[1].message)
    assert.equals(vim.log.levels.INFO, messages[1].level)
  end)

  it('starts coroutine async update without installing inline', function()
    local repo = make_parser_repo('fixture')
    local ts_pack = require('ts-pack')
    ts_pack.add({
      { src = repo, name = 'fixture', version = 'HEAD' },
    })

    local original_system = vim.system
    local calls = {}
    vim.system = function(cmd, opts, callback)
      calls[#calls + 1] = { cmd = cmd, opts = opts, callback = callback }
      return {}
    end

    local result = ts_pack.update({ 'fixture' }, { async = true, target = 'version' })
    vim.system = original_system

    assert.equals(1, #calls)
    assert.equals('git', calls[1].cmd[1])
    assert.equals('fetch', calls[1].cmd[2])
    assert.truthy(result[1].active)
    assert.truthy(result[1].pending)
  end)

  it('restores parser artifacts in the background with async update', function()
    local repo = make_parser_repo('fixture')
    local ts_pack = require('ts-pack')
    ts_pack.add({
      { src = repo, name = 'fixture', version = 'HEAD' },
    })
    local parser_path = vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'parser', 'fixture.so')
    vim.fn.delete(parser_path)

    ts_pack.update({ 'fixture' }, { async = true, target = 'lockfile' })

    local done = vim.wait(10000, function()
      return vim.uv.fs_stat(parser_path) ~= nil
    end)

    assert.truthy(done)
  end)

  it('notifies async update failures and allows a later async update to start', function()
    local repo = make_parser_repo('fixture')
    local ts_pack = require('ts-pack')
    ts_pack.add({
      { src = repo, name = 'fixture', version = 'HEAD' },
    })

    local original_system = vim.system
    local original_notify = vim.notify
    local calls = {}
    local callbacks = {}
    local messages = {}

    vim.system = function(cmd, opts, callback)
      calls[#calls + 1] = { cmd = cmd, opts = opts }
      callbacks[#callbacks + 1] = callback
      return {}
    end
    vim.notify = function(message, level)
      messages[#messages + 1] = { message = message, level = level }
    end

    ts_pack.update({ 'fixture' }, { async = true, target = 'version' })

    callbacks[1]({ code = 1, stderr = 'fetch failed' })
    local failed = vim.wait(1000, function()
      return #messages == 1
    end)

    ts_pack.update({ 'fixture' }, { async = true, target = 'version' })

    vim.system = original_system
    vim.notify = original_notify

    assert.truthy(failed)
    assert.equals(vim.log.levels.ERROR, messages[1].level)
    assert.truthy(messages[1].message:match('ts%-pack async update failed'))
    assert.truthy(messages[1].message:match('fetch failed'))
    assert.equals(2, #calls)
  end)

  it('emits native progress when available', function()
    if vim.fn.has('nvim-0.12') ~= 1 then
      return
    end

    local repo = make_parser_repo('fixture')
    local original_echo = vim.api.nvim_echo
    local echoes = {}
    vim.api.nvim_echo = function(chunks, history, opts)
      echoes[#echoes + 1] = { chunks = chunks, history = history, opts = opts }
      return 42
    end

    local ts_pack = require('ts-pack')
    ts_pack.add({
      { src = repo, name = 'fixture', version = 'HEAD' },
    })
    vim.api.nvim_echo = original_echo

    local progress = {}
    for _, echo in ipairs(echoes) do
      if echo.opts and echo.opts.kind == 'progress' then
        progress[#progress + 1] = echo
      end
    end

    assert.truthy(#progress >= 3)
    assert.equals('running', progress[1].opts.status)
    assert.equals('success', progress[#progress].opts.status)
    assert.equals(100, progress[#progress].opts.percent)
  end)

  it('notifies async failures and allows a later async add to start', function()
    local original_system = vim.system
    local original_notify = vim.notify
    local calls = {}
    local callbacks = {}
    local messages = {}

    vim.system = function(cmd, opts, callback)
      calls[#calls + 1] = { cmd = cmd, opts = opts }
      callbacks[#callbacks + 1] = callback
      return {}
    end
    vim.notify = function(message, level)
      messages[#messages + 1] = { message = message, level = level }
    end

    local ts_pack = require('ts-pack')
    ts_pack.add({
      { src = '/tmp/tree-sitter-fixture', name = 'fixture', version = 'HEAD' },
    }, { async = true, info = false })

    callbacks[1]({ code = 1, stderr = 'clone failed' })
    local failed = vim.wait(1000, function()
      return #messages == 1
    end)

    ts_pack.add({
      { src = '/tmp/tree-sitter-other', name = 'other', version = 'HEAD' },
    }, { async = true, info = false })

    vim.system = original_system
    vim.notify = original_notify

    assert.truthy(failed)
    assert.equals(vim.log.levels.ERROR, messages[1].level)
    assert.truthy(messages[1].message:match('ts%-pack async add failed'))
    assert.truthy(messages[1].message:match('clone failed'))
    assert.equals(2, #calls)
    assert.equals('other', calls[2].cmd[5]:match('[^/]+$'))
  end)

  it('reports overlapping async add calls instead of dropping them silently', function()
    local original_system = vim.system
    local original_notify = vim.notify
    local calls = {}
    local messages = {}

    vim.system = function(cmd, opts, callback)
      calls[#calls + 1] = { cmd = cmd, opts = opts, callback = callback }
      return {}
    end
    vim.notify = function(message, level)
      messages[#messages + 1] = { message = message, level = level }
    end

    local ts_pack = require('ts-pack')
    ts_pack.add({
      { src = '/tmp/tree-sitter-fixture', name = 'fixture', version = 'HEAD' },
    }, { async = true, info = false })
    ts_pack.add({
      { src = '/tmp/tree-sitter-other', name = 'other', version = 'HEAD' },
    }, { async = true, info = false })

    vim.system = original_system
    vim.notify = original_notify

    assert.equals(1, #calls)
    assert.equals(1, #messages)
    assert.equals(vim.log.levels.WARN, messages[1].level)
    assert.truthy(messages[1].message:match('already running'))
  end)
end)
