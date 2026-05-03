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

    assert.truthy(has_record(records, 'start', '^ts%-pack: paths$'))
    assert.truthy(has_record(records, 'info', '^Parser directory: '))
    assert.truthy(has_record(records, 'info', '^Lockfile is absent$'))
    assert.truthy(has_record(records, 'info', '^No parsers found$'))
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
