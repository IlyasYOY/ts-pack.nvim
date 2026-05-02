local function set_query(lang, name)
  local queries = require('ts-pack.queries')
  local file = vim.fs.joinpath(queries.bundled_path(lang), name .. '.scm')
  if vim.uv.fs_stat(file) then
    vim.treesitter.query.set(lang, name, table.concat(vim.fn.readfile(file), '\n'))
  end
end

local function load_bundled_queries(lang)
  for _, name in ipairs({ 'highlights', 'injections', 'locals', 'folds', 'indents' }) do
    set_query(lang, name)
  end
end

local function available(lang)
  local ok, loaded = pcall(vim.treesitter.language.add, lang)
  return ok and loaded
end

local function parse_assertions(file)
  local assertions = {}
  local lines = vim.fn.readfile(file)

  local function is_assertion_line(line)
    return line:match('^%s*%-%-%s*[%^<]')
      or line:match('^%s*//%s*[%^<]')
      or line:match('^%s*<!%-%-')
  end

  local function target_row(index)
    local row = index - 1
    while row > 0 and is_assertion_line(lines[row]) do
      row = row - 1
    end
    return row - 1
  end

  for index, line in ipairs(lines) do
    if is_assertion_line(line) then
      local search_at = 1
      while true do
        local marker_start, marker_end = line:find('%^', search_at)
        if not marker_start then
          break
        end

        local capture = line:match('!?[%w%.%_]+', marker_end + 1)
        if capture then
          assertions[#assertions + 1] = {
            row = target_row(index),
            col = marker_start - 1,
            capture = capture,
          }
        end
        search_at = marker_end + 1
      end

      local arrow_start = line:find('<%-')
      if arrow_start then
        local capture = line:match('@[%w%.%_]+', arrow_start)
        if capture then
          assertions[#assertions + 1] = {
            row = target_row(index),
            col = 0,
            capture = capture:sub(2),
          }
        end
      end
    end
  end

  return assertions
end

local function captures_at(parser, buf, row, col)
  local found = {}

  parser:for_each_tree(function(tstree, tree)
    if not tstree then
      return
    end

    local root = tstree:root()
    local root_start_row, _, root_end_row, _ = root:range()
    if root_start_row > row or root_end_row < row then
      return
    end

    local query = vim.treesitter.query.get(tree:lang(), 'highlights')
    if not query then
      return
    end

    for id, node in query:iter_captures(root, buf, row, row + 1) do
      if vim.treesitter.is_in_node_range(node, row, col) then
        local capture = query.captures[id]
        if capture ~= nil and capture ~= 'conceal' and capture ~= 'spell' then
          found[capture] = true
        end
      end
    end
  end)

  return found
end

local function check_file(lang, file)
  local buf = vim.fn.bufadd(file)
  vim.fn.bufload(file)

  local parser = vim.treesitter.get_parser(buf, lang)
  parser:parse(true)

  for _, assertion in ipairs(parse_assertions(file)) do
    local found = captures_at(parser, buf, assertion.row, assertion.col)
    if assertion.capture:sub(1, 1) == '!' then
      assert.falsy(found[assertion.capture:sub(2)])
    else
      assert(
        found[assertion.capture],
        ('expected %s at %s:%d:%d, got %s'):format(
          assertion.capture,
          file,
          assertion.row + 1,
          assertion.col + 1,
          vim.inspect(vim.tbl_keys(found))
        )
      )
    end
  end
end

describe('ts-pack.query_highlights', function()
  before_each(function()
    require('ts-pack.queries').register_predicates()
  end)

  it('passes copied C highlight assertions', function()
    if not available('c') then
      return
    end

    load_bundled_queries('c')
    check_file('c', 'test/query/highlights/c/enums-as-constants.c')
  end)

  it('passes copied Lua highlight assertions', function()
    if not available('lua') then
      return
    end

    load_bundled_queries('lua')
    check_file('lua', 'test/query/highlights/lua/test.lua')
  end)

  it('passes copied Markdown highlight assertions', function()
    if not available('markdown') or not available('markdown_inline') then
      return
    end

    load_bundled_queries('markdown')
    load_bundled_queries('markdown_inline')
    check_file('markdown', 'test/query/highlights/markdown/test.md')
  end)
end)
