local helpers = require('tests.query_helpers')

local function comment(opts)
  return vim.tbl_extend('force', {
    type = 'comment',
    text = '',
    start_row = 1,
    start_col = 0,
    end_row = 1,
    end_col = 0,
  }, opts)
end

describe('tests.query_helpers', function()
  it('parses caret assertions with at-prefixed and plain capture names', function()
    assert.same(
      {
        {
          position = { row = 1, column = 4 },
          expected_capture_name = 'constant',
        },
        {
          position = { row = 3, column = 5 },
          expected_capture_name = 'variable.member',
        },
      },
      helpers.parse_assertion_comments({
        comment({ text = '//  ^ @constant', start_row = 2 }),
        comment({ text = '# ^ variable.member', start_row = 4, start_col = 3 }),
      }, 'comment')
    )
  end)

  it('parses left-arrow and negative assertions', function()
    assert.same(
      {
        {
          position = { row = 1, column = 6 },
          expected_capture_name = 'comment',
        },
        {
          position = { row = 3, column = 10 },
          expected_capture_name = '!regex',
        },
      },
      helpers.parse_assertion_comments({
        comment({ text = '# <- @comment', start_row = 2, start_col = 6 }),
        comment({ text = '#   ^ @!regex', start_row = 4, start_col = 6 }),
      }, 'comment')
    )
  end)

  it('adjusts stacked assertion comments to the source line above them', function()
    assert.same(
      {
        {
          position = { row = 0, column = 3 },
          expected_capture_name = 'variable',
        },
        {
          position = { row = 0, column = 5 },
          expected_capture_name = 'type',
        },
      },
      helpers.parse_assertion_comments({
        comment({ text = '// ^ @variable', start_row = 1 }),
        comment({ text = '//   ^ @type', start_row = 2 }),
      }, 'comment')
    )
  end)

  it('honors non-default comment node names', function()
    assert.same(
      {
        {
          position = { row = 0, column = 0 },
          expected_capture_name = 'markup.heading.1',
        },
      },
      helpers.parse_assertion_comments({
        comment({ type = 'html_block', text = '<!-- <- @markup.heading.1 -->' }),
        comment({ type = 'comment', text = '// <- @ignored' }),
      }, 'html_block')
    )

    assert.same(
      {
        {
          position = { row = 2, column = 5 },
          expected_capture_name = 'comment.documentation',
        },
      },
      helpers.parse_assertion_comments({
        comment({
          type = 'haddock',
          text = '-- | ^ @comment.documentation',
          start_row = 3,
        }),
      }, 'haddock')
    )
  end)

  it('ignores assertion-looking comments on the first line', function()
    assert.same(
      {},
      helpers.parse_assertion_comments({
        comment({ text = '// ^ @comment', start_row = 0 }),
      }, 'comment')
    )
  end)
end)
