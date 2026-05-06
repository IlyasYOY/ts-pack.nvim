local function test_home()
  return vim.env.TS_PACK_TEST_HOME or vim.fs.joinpath(vim.fn.getcwd(), '.test-home')
end

local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(lines, path)
end

local function reset()
  vim.fn.delete(test_home(), 'rf')
  vim.fn.mkdir(vim.env.XDG_CONFIG_HOME, 'p')
  vim.fn.mkdir(vim.env.XDG_DATA_HOME, 'p')
  vim.fn.mkdir(vim.env.XDG_CACHE_HOME, 'p')
  vim.fn.mkdir(vim.env.XDG_STATE_HOME, 'p')
  package.loaded['ts-pack'] = nil
  package.loaded['ts-pack.health'] = nil
end

local function capture_health(fn)
  local original = vim.health
  local records = {}

  vim.health = {}
  for _, kind in ipairs({ 'start', 'info', 'ok', 'warn', 'error' }) do
    vim.health[kind] = function(message)
      records[#records + 1] = { kind = kind, message = message }
    end
  end

  local ok, err = pcall(fn)
  vim.health = original
  if not ok then
    error(err, 2)
  end

  return records
end

local function has_record(records, kind, pattern)
  for _, record in ipairs(records) do
    if record.kind == kind and record.message:match(pattern) then
      return true
    end
  end
  return false
end

local function with_mocked_commands(commands, fn)
  local original_executable = vim.fn.executable
  local original_exepath = vim.fn.exepath
  local original_system = vim.fn.system

  vim.fn.executable = function(name)
    return commands[name] and 1 or 0
  end
  vim.fn.exepath = function(name)
    return commands[name] and commands[name].path or ''
  end
  vim.fn.system = function(cmd)
    local command = commands[cmd[1]]
    return command and command.output or ''
  end

  local ok, result = pcall(fn)

  vim.fn.executable = original_executable
  vim.fn.exepath = original_exepath
  vim.fn.system = original_system

  if not ok then
    error(result, 2)
  end
  return result
end

local function lockfile()
  return require('ts-pack.path').lockfile()
end

local function parser_path(name)
  return require('ts-pack.path').parser_path(name)
end

local function revision_path(name)
  return require('ts-pack.path').parser_revision_path(name)
end

local function query_path(name, query_type)
  return vim.fs.joinpath(require('ts-pack.path').query_path(name), query_type .. '.scm')
end

local function save_lock(lock)
  require('ts-pack.fs').save_lock(lock)
end

before_each(reset)

describe('ts-pack.health', function()
  it('reports paths and empty parser state', function()
    local records = capture_health(function()
      require('ts-pack.health').check()
    end)

    assert.truthy(has_record(records, 'start', '^ts%-pack: requirements$'))
    assert.truthy(has_record(records, 'ok', '^Neovim '))
    assert.truthy(has_record(records, 'start', '^ts%-pack: paths$'))
    assert.truthy(has_record(records, 'info', '^Default site directory: '))
    assert.truthy(has_record(records, 'info', '^Parser directory: '))
    assert.truthy(has_record(records, 'ok', '^Parser directory is writable or creatable'))
    assert.truthy(has_record(records, 'info', '^Lockfile is absent$'))
    assert.truthy(has_record(records, 'info', '^No parsers found$'))
  end)

  it('reports tool locations and versions for installer dependencies', function()
    local records = with_mocked_commands({
      git = { path = '/test/git', output = 'git version 2.44.0' },
      ['tree-sitter'] = { path = '/test/tree-sitter', output = 'tree-sitter 0.26.1' },
      cc = { path = '/test/cc', output = 'cc 1.0.0' },
      ['c++'] = { path = '/test/c++', output = 'c++ 1.0.0' },
    }, function()
      return capture_health(function()
        require('ts-pack.health').check()
      end)
    end)

    assert.truthy(has_record(records, 'ok', '^git: git version 2%.44%.0 %(/test/git'))
    assert.truthy(
      has_record(records, 'ok', '^tree%-sitter: tree%-sitter 0%.26%.1 %(/test/tree%-sitter')
    )
    assert.truthy(has_record(records, 'ok', '^C compiler: cc 1%.0%.0 %(/test/cc'))
    assert.truthy(has_record(records, 'ok', '^C%+%+ compiler: c%+%+ 1%.0%.0 %(/test/c%+%+'))
  end)

  it('errors when tree-sitter is missing for generated active parser specs', function()
    package.loaded['ts-pack'] = {
      get = function()
        return {
          {
            spec = {
              name = 'generated',
              src = '/tmp/tree-sitter-generated',
              generate = true,
            },
          },
        }
      end,
    }

    local records = with_mocked_commands({
      git = { path = '/test/git', output = 'git version 2.44.0' },
      cc = { path = '/test/cc', output = 'cc 1.0.0' },
      ['c++'] = { path = '/test/c++', output = 'c++ 1.0.0' },
    }, function()
      return capture_health(function()
        require('ts-pack.health').check()
      end)
    end)

    assert.truthy(has_record(records, 'error', '^tree%-sitter CLI not found; .*generated'))
  end)

  it('reports matching installed and locked parser revisions', function()
    write(parser_path('fixture'), { 'parser' })
    write(revision_path('fixture'), { 'abc123' })
    save_lock({
      parsers = {
        fixture = {
          src = '/tmp/tree-sitter-fixture',
          rev = 'abc123',
          version = 'HEAD',
        },
      },
    })

    local records = capture_health(function()
      require('ts-pack.health').check()
    end)

    assert.truthy(has_record(records, 'ok', '^fixture: installed, inactive, path: .-abc123'))
    assert.falsy(has_record(records, 'warn', 'fixture'))
  end)

  it('warns when local and lockfile revisions differ', function()
    write(parser_path('fixture'), { 'parser' })
    write(revision_path('fixture'), { 'local-rev' })
    save_lock({
      parsers = {
        fixture = {
          src = '/tmp/tree-sitter-fixture',
          rev = 'locked-rev',
        },
      },
    })

    local records = capture_health(function()
      require('ts-pack.health').check()
    end)

    assert.truthy(has_record(records, 'warn', 'fixture: installed, inactive'))
    assert.truthy(has_record(records, 'warn', 'local revision differs from lockfile'))
  end)

  it('reports ts-pack managed queries by parser', function()
    write(query_path('fixture', 'highlights'), { '; highlights' })
    write(query_path('fixture', 'injections'), { '; injections' })

    local records = capture_health(function()
      require('ts-pack.health').check()
    end)

    assert.truthy(has_record(records, 'start', '^ts%-pack: queries$'))
    assert.truthy(has_record(records, 'ok', '^fixture: highlights %(.+queries/fixture%)'))
    assert.truthy(has_record(records, 'ok', '^fixture: .*injections %(.+queries/fixture%)'))
  end)

  it('parses valid managed queries when the parser is loadable', function()
    write(query_path('lua', 'highlights'), { '(identifier) @variable' })

    local records = capture_health(function()
      require('ts-pack.health').check()
    end)

    assert.truthy(has_record(records, 'start', '^ts%-pack: query parse$'))
    assert.truthy(has_record(records, 'ok', '^Parsed 1 managed query file$'))
  end)

  it('errors on invalid managed queries when the parser is loadable', function()
    write(query_path('lua', 'highlights'), { '((identifier) @variable' })

    local records = capture_health(function()
      require('ts-pack.health').check()
    end)

    assert.truthy(has_record(records, 'error', '^lua/highlights %('))
  end)

  it('reports runtimepath queries separately', function()
    write(query_path('fixture', 'highlights'), { '; highlights' })
    vim.opt.runtimepath:prepend(require('ts-pack.path').default_site_dir())

    local records = capture_health(function()
      require('ts-pack.health').check()
    end)

    assert.truthy(has_record(records, 'start', '^ts%-pack: runtime queries$'))
    assert.truthy(has_record(records, 'ok', '^fixture: highlights %(.+queries/fixture%)'))
  end)

  it('errors on malformed lockfile', function()
    write(lockfile(), { '{' })

    local records = capture_health(function()
      require('ts-pack.health').check()
    end)

    assert.truthy(has_record(records, 'error', '^Lockfile is not valid JSON: '))
  end)
end)
