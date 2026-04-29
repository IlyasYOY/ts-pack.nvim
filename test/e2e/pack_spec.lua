local function write(path, lines)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  vim.fn.writefile(lines, path)
end

local function run(argv, cwd)
  local result = vim.system(argv, { cwd = cwd, text = true }):wait()
  if result.code ~= 0 then
    error((result.stderr or '') .. (result.stdout or ''))
  end
  return vim.trim(result.stdout or '')
end

local function reset_ts_pack(root)
  package.loaded['ts-pack'] = nil
  local ts_pack = require('ts-pack')
  ts_pack.setup({
    root = root .. '/data/ts-pack',
    lockfile = root .. '/config/ts-pack-lock.json',
  })
  return ts_pack
end

local function grammar(name, word)
  return {
    'module.exports = grammar({',
    ("  name: '%s',"):format(name),
    '  rules: {',
    ("    source_file: $ => '%s',"):format(word),
    '  }',
    '});',
  }
end

local function make_repo(root, id, opts)
  opts = opts or {}
  local repo = root .. '/repos/' .. id
  local base = opts.location and repo .. '/' .. opts.location or repo
  write(base .. '/grammar.js', grammar(id, opts.word or id))
  run({ 'tree-sitter', 'generate' }, base)
  if opts.queries then
    write(base .. '/' .. opts.queries .. '/highlights.scm', { '("x" @string)' })
  end
  run({ 'git', 'init', '--quiet' }, repo)
  run({ 'git', 'config', 'user.email', 'ts-pack@example.invalid' }, repo)
  run({ 'git', 'config', 'user.name', 'ts-pack tests' }, repo)
  run({ 'git', 'add', '.' }, repo)
  run({ 'git', 'commit', '--quiet', '-m', 'initial' }, repo)
  return repo, run({ 'git', 'rev-parse', 'HEAD' }, repo)
end

local function commit_word(repo, location, id, word, tag)
  local base = location and repo .. '/' .. location or repo
  write(base .. '/grammar.js', grammar(id, word))
  run({ 'tree-sitter', 'generate' }, base)
  run({ 'git', 'add', '.' }, repo)
  run({ 'git', 'commit', '--quiet', '-m', 'update ' .. word }, repo)
  if tag then
    run({ 'git', 'tag', tag }, repo)
  end
  return run({ 'git', 'rev-parse', 'HEAD' }, repo)
end

local function fresh_root(name)
  local root = vim.fn.stdpath('cache') .. '/' .. name
  vim.fn.delete(root, 'rf')
  vim.fn.mkdir(root, 'p')
  return root
end

describe('ts-pack e2e', function()
  it('installs a parser and explicit queries from a local git repo', function()
    local root = fresh_root('e2e-install')
    local repo = make_repo(root, 'toy', { queries = 'queries' })
    local ts_pack = reset_ts_pack(root)

    ts_pack.add({
      {
        id = 'toy',
        src = repo,
        queries = 'queries',
      },
    })

    local info = ts_pack.get({ 'toy' })[1]
    assert.truthy(info.installed)
    assert.truthy(vim.uv.fs_stat(info.path))
    assert.truthy(vim.uv.fs_stat(root .. '/data/ts-pack/runtime/queries/toy/highlights.scm'))
    assert.equals(true, info.active)

    vim.treesitter.language.add('toy', { path = info.path })
  end)

  it('updates to declared fixed refs and installs lockfile entries in a fresh state', function()
    local root = fresh_root('e2e-update')
    local repo, first = make_repo(root, 'pin')
    local second = commit_word(repo, nil, 'pin', 'next', 'v2')

    local ts_pack = reset_ts_pack(root)
    ts_pack.add({ { id = 'pin', src = repo, version = first } })
    assert.equals(first, ts_pack.get({ 'pin' })[1].rev)

    ts_pack.add({ { id = 'pin', src = repo, version = 'v2' } })
    ts_pack.update({ 'pin' })
    assert.equals(second, ts_pack.get({ 'pin' })[1].rev)

    ts_pack.add({ { id = 'pin', src = repo } })
    ts_pack.update({ 'pin' })
    local default_branch = ts_pack.get({ 'pin' })[1]
    assert.equals(second, default_branch.rev)
    assert.falsy(default_branch.version)

    vim.fn.delete(root .. '/data/ts-pack', 'rf')
    local fresh = reset_ts_pack(root)
    local repaired = fresh.get({ 'pin' })[1]
    assert.equals(second, repaired.rev)
    assert.truthy(vim.uv.fs_stat(repaired.path))
  end)

  it('supports monorepo locations and protects active parsers from delete', function()
    local root = fresh_root('e2e-monorepo')
    local repo = make_repo(root, 'inside', { location = 'grammars/inside' })
    local ts_pack = reset_ts_pack(root)

    ts_pack.add({ { id = 'inside', src = repo, location = 'grammars/inside' } })
    local info = ts_pack.get({ 'inside' })[1]
    assert.truthy(vim.uv.fs_stat(info.path))

    assert.error_matches('refusing to delete active parser', function()
      ts_pack.del({ 'inside' })
    end)
  end)

  it('deletes inactive checkout, runtime artifacts, queries, and lockfile state', function()
    local root = fresh_root('e2e-delete')
    local repo = make_repo(root, 'gone', { queries = 'queries' })
    local ts_pack = reset_ts_pack(root)

    ts_pack.add({ { id = 'gone', src = repo, queries = 'queries' } })
    package.loaded['ts-pack'] = nil
    ts_pack = reset_ts_pack(root)
    ts_pack.del({ 'gone' })

    assert.same({}, ts_pack.get({ 'gone' }))
    assert.falsy(vim.uv.fs_stat(root .. '/data/ts-pack/checkouts/gone'))
    assert.falsy(vim.uv.fs_stat(root .. '/data/ts-pack/runtime/parser/gone.so'))
    assert.falsy(vim.uv.fs_stat(root .. '/data/ts-pack/runtime/queries/gone'))
  end)
end)
