describe('ts-pack.hooks', function()
  it('registers a string filetype for a parser', function()
    local hooks = require('ts-pack.hooks')

    hooks.apply({ name = 'fixture_string', data = { filetype = 'fixture-string-ft' } })

    assert.equals('fixture_string', vim.treesitter.language.get_lang('fixture-string-ft'))
  end)

  it('registers a list of filetypes for a parser', function()
    local hooks = require('ts-pack.hooks')

    hooks.apply({
      name = 'fixture_list',
      data = { filetype = { 'fixture-list-one', 'fixture-list-two' } },
    })

    assert.equals('fixture_list', vim.treesitter.language.get_lang('fixture-list-one'))
    assert.equals('fixture_list', vim.treesitter.language.get_lang('fixture-list-two'))
  end)

  it('ignores specs without filetype metadata', function()
    local hooks = require('ts-pack.hooks')

    hooks.apply({ name = 'fixture_missing', data = { enabled = true } })

    assert.equals('fixture-missing-ft', vim.treesitter.language.get_lang('fixture-missing-ft'))
  end)

  it('rejects invalid filetype metadata', function()
    local hooks = require('ts-pack.hooks')

    local ok, err = pcall(function()
      hooks.apply({ name = 'fixture_invalid', data = { filetype = { 1 } } })
    end)

    assert.falsy(ok)
    assert.truthy(err:match('spec%.data%.filetype%[1%]'))
  end)
end)
