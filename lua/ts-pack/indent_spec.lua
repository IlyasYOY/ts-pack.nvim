local function load_indent_query(lang)
  local queries = require('ts-pack.queries')
  local file = vim.fs.joinpath(queries.bundled_path(lang), 'indents.scm')
  vim.treesitter.query.set(lang, 'indents', table.concat(vim.fn.readfile(file), '\n'))
end

local function available(lang)
  local ok, loaded = pcall(vim.treesitter.language.add, lang)
  return ok and loaded
end

local function new_lua_buffer(lines)
  vim.cmd('enew!')
  vim.bo.filetype = 'lua'
  vim.bo.tabstop = 2
  vim.bo.shiftwidth = 2
  vim.bo.softtabstop = 0
  vim.bo.expandtab = true
  vim.bo.indentexpr = "v:lua.require'ts-pack.indent'.expr()"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

describe('ts-pack.indent', function()
  before_each(function()
    package.loaded['ts-pack.indent'] = nil
    load_indent_query('lua')
  end)

  after_each(function()
    vim.bo.modified = false
  end)

  it('exposes the documented indentexpr entrypoint', function()
    new_lua_buffer({ 'local value = 1' })
    local indent = require('ts-pack.indent')

    assert.equals('function', type(indent.expr))
    assert.equals("v:lua.require'ts-pack.indent'.expr()", vim.bo.indentexpr)
  end)

  it('indents Lua blocks with bundled indent queries', function()
    if not available('lua') then
      return
    end

    new_lua_buffer({
      'local function example()',
      'local value = {',
      'one = 1,',
      '}',
      'return value',
      'end',
    })

    vim.cmd('silent normal! gg=G')

    assert.same({
      'local function example()',
      '  local value = {',
      '    one = 1,',
      '  }',
      '  return value',
      'end',
    }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  end)

  it('dedents Lua branches and closing keywords', function()
    if not available('lua') then
      return
    end

    new_lua_buffer({
      'if ok then',
      'return 1',
      'else',
      'return 2',
      'end',
    })

    vim.cmd('silent normal! gg=G')

    assert.same({
      'if ok then',
      '  return 1',
      'else',
      '  return 2',
      'end',
    }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  end)

  it('falls back when no parser is available', function()
    vim.cmd('enew!')
    vim.bo.filetype = ''
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'plain text' })

    assert.equals(-1, require('ts-pack.indent').get_indent(1))
  end)
end)
