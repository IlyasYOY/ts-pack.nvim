local indentexpr = "v:lua.require'ts-pack.indent'.expr()"
local foldexpr = 'v:lua.vim.treesitter.foldexpr()'

describe('ts-pack.features', function()
  local features
  local buffers
  local original_foldexpr
  local original_foldmethod
  local original_start
  local start_calls

  local function scratch(filetype)
    vim.cmd('enew')
    local bufnr = vim.api.nvim_get_current_buf()
    buffers[#buffers + 1] = bufnr
    vim.bo[bufnr].buftype = 'nofile'
    vim.bo[bufnr].bufhidden = 'wipe'
    vim.bo[bufnr].indentexpr = ''
    vim.wo.foldmethod = 'manual'
    vim.wo.foldexpr = '0'
    if filetype then
      vim.bo[bufnr].filetype = filetype
    end
    return bufnr
  end

  before_each(function()
    package.loaded['ts-pack.hooks'] = nil
    package.loaded['ts-pack.features'] = nil
    features = require('ts-pack.features')
    features._reset()
    buffers = {}
    start_calls = {}
    original_foldexpr = vim.wo.foldexpr
    original_foldmethod = vim.wo.foldmethod
    original_start = vim.treesitter.start
    vim.treesitter.start = function(bufnr, lang)
      start_calls[#start_calls + 1] = { bufnr = bufnr, lang = lang }
    end
  end)

  after_each(function()
    vim.treesitter.start = original_start
    vim.wo.foldexpr = original_foldexpr
    vim.wo.foldmethod = original_foldmethod
    features._reset()
    for _, bufnr in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end
  end)

  it('does not enable features when metadata is absent or false', function()
    local bufnr = scratch('fixture_features_default')

    features.register({ name = 'fixture_features_default', data = {} })
    features.register({ name = 'fixture_features_false', data = { features = false } })
    features.apply_buffer(bufnr)

    assert.equals(0, #start_calls)
    assert.equals('', vim.bo[bufnr].indentexpr)
    assert.equals('manual', vim.wo.foldmethod)
    assert.equals('0', vim.wo.foldexpr)
  end)

  it('enables highlights, indent, and folds when features is true', function()
    local bufnr = scratch('fixture_features_all')

    features.register({ name = 'fixture_features_all', data = { features = true } })

    assert.same({ { bufnr = bufnr, lang = 'fixture_features_all' } }, start_calls)
    assert.equals(indentexpr, vim.bo[bufnr].indentexpr)
    assert.equals('expr', vim.wo.foldmethod)
    assert.equals(foldexpr, vim.wo.foldexpr)
  end)

  it('enables only explicitly selected table features', function()
    local bufnr = scratch('fixture_features_partial')

    features.register({
      name = 'fixture_features_partial',
      data = { features = { folds = false, highlights = false, indent = true } },
    })

    assert.equals(0, #start_calls)
    assert.equals(indentexpr, vim.bo[bufnr].indentexpr)
    assert.equals('manual', vim.wo.foldmethod)
    assert.equals('0', vim.wo.foldexpr)
  end)

  it('rejects unknown feature keys and non-boolean values', function()
    local ok, err = pcall(function()
      features.register({
        name = 'fixture_features_unknown',
        data = { features = { highlight = true } },
      })
    end)

    assert.falsy(ok)
    assert.truthy(err:match('spec%.data%.features'))

    ok, err = pcall(function()
      features.register({
        name = 'fixture_features_invalid',
        data = { features = { indent = 'yes' } },
      })
    end)

    assert.falsy(ok)
    assert.truthy(err:match('spec%.data%.features%.indent'))
  end)

  it('uses filetype aliases registered by hooks before applying features', function()
    local hooks = require('ts-pack.hooks')
    local bufnr = scratch('fixture-features-alias-ft')

    hooks.apply({
      name = 'fixture_features_alias',
      data = {
        filetype = 'fixture-features-alias-ft',
        features = { indent = true },
      },
    })

    assert.equals(
      'fixture_features_alias',
      vim.treesitter.language.get_lang('fixture-features-alias-ft')
    )
    assert.equals(indentexpr, vim.bo[bufnr].indentexpr)
  end)

  it('configures future buffers from FileType autocmds', function()
    features.register({ name = 'fixture_features_future', data = { features = { indent = true } } })
    local bufnr = scratch()

    vim.bo[bufnr].filetype = 'fixture_features_future'
    vim.bo[bufnr].indentexpr = ''
    vim.api.nvim_exec_autocmds('FileType', { buffer = bufnr })

    assert.equals(indentexpr, vim.bo[bufnr].indentexpr)
  end)

  it('reapplies window-local folds on BufWinEnter', function()
    local bufnr = scratch('fixture_features_bufwin')

    features.register({ name = 'fixture_features_bufwin', data = { features = { folds = true } } })
    vim.wo.foldmethod = 'manual'
    vim.wo.foldexpr = '0'
    vim.api.nvim_exec_autocmds('BufWinEnter', { buffer = bufnr })

    assert.equals('expr', vim.wo.foldmethod)
    assert.equals(foldexpr, vim.wo.foldexpr)
  end)
end)
