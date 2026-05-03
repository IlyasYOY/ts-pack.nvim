local helpers = require('test.query_helpers')
local ts = vim.treesitter

local function check_assertions(file)
  local ctx = helpers.fixture_context(file)
  local assertions = helpers.injection_assertions(ctx, file)
  local parser = ts.get_parser(ctx.buf, ctx.lang)

  for _, assertion in ipairs(assertions) do
    local expected_lang = assertion.expected_capture_name:gsub('^!', '')
    if
      not assertion.expected_capture_name:match('^!') and not helpers.parser_path(expected_lang)
    then
      if helpers.is_strict() then
        error(
          ('parser for injected %s is required for strict query fixture tests'):format(
            expected_lang
          ),
          2
        )
      end

      _G.skip(('parser for injected %s is not available'):format(expected_lang))
    end
  end

  local top_level_root = parser:parse(true)[1]:root()

  for _, assertion in ipairs(assertions) do
    local row = assertion.position.row
    local col = assertion.position.column

    local neg_assert = assertion.expected_capture_name:match('^!')
    assertion.expected_capture_name = neg_assert and assertion.expected_capture_name:sub(2)
      or assertion.expected_capture_name
    local found = false
    parser:for_each_tree(function(tstree, tree)
      if not tstree then
        return
      end
      local root = tstree:root()
      --- If there are multiple tree with the smallest range possible
      --- Check all of them to see if they fit or not
      if not ts.is_in_node_range(root, row, col) or root == top_level_root then
        return
      end
      if assertion.expected_capture_name == tree:lang() then
        found = true
      end
    end)
    if neg_assert then
      assert.False(
        found,
        'Error in '
          .. file
          .. ':'
          .. (row + 1)
          .. ':'
          .. (col + 1)
          .. ': expected "'
          .. assertion.expected_capture_name
          .. '" not to be injected here!'
      )
    else
      assert.True(
        found,
        'Error in '
          .. file
          .. ':'
          .. (row + 1)
          .. ':'
          .. (col + 1)
          .. ': expected "'
          .. assertion.expected_capture_name
          .. '" to be injected here!'
      )
    end
  end
end

describe('injections', function()
  local files = vim.fn.split(vim.fn.glob('tests/query/injections/**/*.*'))
  for _, file in ipairs(files) do
    it(file, function()
      check_assertions(file)
    end)
  end
end)
