local function run(argv, cwd)
  local result = vim.system(argv, { cwd = cwd, text = true }):wait()
  if result.code ~= 0 then
    error((result.stderr or '') .. (result.stdout or ''))
  end
  return vim.trim(result.stdout or '')
end

local function write(path, text)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  vim.fn.writefile({ text }, path)
end

local function temp_root(name)
  local root = vim.fn.stdpath('cache') .. '/' .. name
  vim.fn.delete(root, 'rf')
  vim.fn.mkdir(root, 'p')
  return root
end

local function make_repo(root)
  local repo = root .. '/repo'
  vim.fn.mkdir(repo, 'p')
  run({ 'git', 'init', '--quiet' }, repo)
  run({ 'git', 'config', 'user.email', 'ts-pack@example.invalid' }, repo)
  run({ 'git', 'config', 'user.name', 'ts-pack tests' }, repo)
  write(repo .. '/tracked.txt', 'one')
  run({ 'git', 'add', '.' }, repo)
  run({ 'git', 'commit', '--quiet', '-m', 'one' }, repo)
  local first = run({ 'git', 'rev-parse', 'HEAD' }, repo)
  local branch = run({ 'git', 'branch', '--show-current' }, repo)

  write(repo .. '/tracked.txt', 'two')
  run({ 'git', 'add', '.' }, repo)
  run({ 'git', 'commit', '--quiet', '-m', 'two' }, repo)
  run({ 'git', 'tag', 'v2' }, repo)
  local second = run({ 'git', 'rev-parse', 'HEAD' }, repo)

  return {
    path = repo,
    branch = branch,
    first = first,
    second = second,
  }
end

describe('ts-pack.git', function()
  it('clones a source and checks out a fixed commit', function()
    local git = require('ts-pack.git')
    local root = temp_root('git-fixed-commit')
    local repo = make_repo(root)
    local checkout = root .. '/checkout'

    git.ensure_checkout(checkout, repo.path, repo.first)

    assert.equals(true, git.is_checkout(checkout))
    assert.equals(repo.first, git.current_rev(checkout))
  end)

  it('checks out tags and returns the current revision', function()
    local git = require('ts-pack.git')
    local root = temp_root('git-tag')
    local repo = make_repo(root)
    local checkout = root .. '/checkout'

    git.ensure_checkout(checkout, repo.path, 'v2')

    assert.equals(repo.second, git.current_rev(checkout))
  end)

  it('updates to the remote default branch when version is nil', function()
    local git = require('ts-pack.git')
    local root = temp_root('git-default-branch')
    local repo = make_repo(root)
    local checkout = root .. '/checkout'

    git.ensure_checkout(checkout, repo.path, repo.first)
    assert.equals(repo.first, git.current_rev(checkout))

    git.update_checkout(checkout, nil)

    assert.equals('origin/' .. repo.branch, git.remote_default_ref(checkout))
    assert.equals(repo.second, git.current_rev(checkout))
  end)

  it('requires a src when the checkout is missing', function()
    local git = require('ts-pack.git')
    local root = temp_root('git-missing-src')

    assert.error_matches('missing git src', function()
      git.ensure_checkout(root .. '/checkout', nil, nil)
    end)
  end)
end)
