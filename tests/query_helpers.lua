local M = {}

local path = require('ts-pack.path')

local FT_OVERRIDES = {
  bzl = 'starlark',
  cmm = 't32',
  conf = 'hocon',
  cu = 'cuda',
  dockerfile = 'dockerfile',
  gd = 'gdscript',
  hcl = 'terraform',
  http = 'http',
  jsx = 'javascript',
  ncl = 'nickel',
  ql = 'ql',
  res = 'rescript',
  sh = 'bash',
  smk = 'snakemake',
  sw = 'sway',
  tig = 'tiger',
  tf = 'terraform',
  tex = 'latex',
  typ = 'typst',
  usd = 'usd',
  vue = 'vue',
  w = 'wing',
  wgsl = 'wgsl',
  yuck = 'yuck',
}

local DIR_LANG_OVERRIDES = {
  algorithm = 'html',
  ecma = 'javascript',
}

local LANG_OVERRIDES = {
  bzl = 'starlark',
  conf = 'hocon',
  cweb = 'wing',
  htmlangular = 'angular',
  javascriptreact = 'javascript',
  sh = 'bash',
  trace32 = 't32',
}

local INJECTION_LANG_OVERRIDES = {}

local function normalize_lang(lang)
  if not lang or lang == '' then
    return nil
  end
  lang = LANG_OVERRIDES[lang] or lang
  return vim.treesitter.language.get_lang(lang) or lang
end

local function file_ext(file)
  return vim.fn.fnamemodify(file, ':e')
end

function M.fixture_dir_lang(file, root)
  local rel = vim.fs.relpath(root, file)
  if not rel then
    return nil
  end

  local dir = rel:match('^([^/]+)/')
  return dir and (DIR_LANG_OVERRIDES[dir] or dir) or nil
end

function M.lang_for_path(file)
  local ext = file_ext(file)
  local ft = FT_OVERRIDES[ext]
  if not ft then
    ft = vim.filetype.match({ filename = file })
  end
  return normalize_lang(ft or ext)
end

function M.lang_for_file(file)
  local buf = vim.fn.bufadd(file)
  vim.fn.bufload(buf)
  local ft = vim.bo[buf].filetype
  if ft == '' then
    ft = M.lang_for_path(file)
    vim.bo[buf].filetype = ft
  end
  return buf, normalize_lang(ft)
end

function M.parser_path(lang)
  local parser = path.parser_path(lang)
  if vim.fn.filereadable(parser) == 1 then
    return parser
  end
  return nil
end

function M.load_parser(lang)
  local parser = M.parser_path(lang)
  assert(parser, ('parser for %s is not installed'):format(lang))
  return vim.treesitter.language.add(lang, { path = parser })
end

function M.fixture_context(file)
  local buf, lang = M.lang_for_file(file)
  M.load_parser(lang)
  return {
    buf = buf,
    lang = lang,
    parser = M.parser_path(lang),
  }
end

local function extract_assertion(comment)
  local position = {
    row = comment.start_row,
    column = comment.start_col,
  }
  local has_left_caret = false
  local has_arrow = false
  local arrow_end = 0

  for i = 1, #comment.text do
    local char = comment.text:sub(i, i)
    arrow_end = i
    if char == '-' and has_left_caret then
      has_arrow = true
      break
    end
    if char == '^' then
      has_arrow = true
      position.column = position.column + i - 1
      break
    end
    has_left_caret = char == '<'
  end

  local capture = comment.text:sub(arrow_end + 1):match('[!%w_%.%-]+')
  if not has_arrow or not capture then
    return nil
  end

  return {
    position = position,
    expected_capture_name = capture,
  }
end

function M.parse_assertion_comments(comments, comment_node)
  comment_node = comment_node or 'comment'
  local assertions = {}
  local ranges = {}

  for _, comment in ipairs(comments) do
    if comment.type:find(comment_node, 1, true) and comment.start_row > 0 then
      local assertion = extract_assertion(comment)
      if assertion then
        ranges[#ranges + 1] = comment
        assertions[#assertions + 1] = assertion
      end
    end
  end

  local range_index = 1
  for _, assertion in ipairs(assertions) do
    while true do
      local on_assertion_line = false
      for i = range_index, #ranges do
        if ranges[i].start_row == assertion.position.row then
          on_assertion_line = true
          break
        end
      end

      if on_assertion_line then
        assertion.position.row = assertion.position.row - 1
      else
        while range_index <= #ranges and ranges[range_index].start_row < assertion.position.row do
          range_index = range_index + 1
        end
        break
      end
    end
  end

  table.sort(assertions, function(a, b)
    if a.position.row ~= b.position.row then
      return a.position.row < b.position.row
    end
    if a.position.column ~= b.position.column then
      return a.position.column < b.position.column
    end
    return a.expected_capture_name < b.expected_capture_name
  end)

  return assertions
end

local function collect_comments(ctx, comment_node)
  local comments = {}
  local parser = vim.treesitter.get_parser(ctx.buf, ctx.lang)
  local tree = parser:parse(true)[1]

  local function visit(node)
    for child in node:iter_children() do
      visit(child)
    end

    local node_type = node:type()
    if node_type:find(comment_node, 1, true) then
      local start_row, start_col, end_row, end_col = node:range()
      comments[#comments + 1] = {
        type = node_type,
        text = vim.treesitter.get_node_text(node, ctx.buf),
        start_row = start_row,
        start_col = start_col,
        end_row = end_row,
        end_col = end_col,
      }
    end
  end

  visit(tree:root())
  return comments
end

function M.highlight_assertions(ctx, _file, comment_node)
  comment_node = comment_node or 'comment'
  return M.parse_assertion_comments(collect_comments(ctx, comment_node), comment_node)
end

function M.injection_assertions(ctx, _file)
  return M.parse_assertion_comments(collect_comments(ctx, 'comment'), 'comment')
end

local function add_lang(result, lang)
  lang = INJECTION_LANG_OVERRIDES[lang] or normalize_lang(lang)
  if lang and lang ~= '' then
    result[lang] = true
  end
end

local function add_fixture_lang(result, file, root)
  add_lang(result, M.lang_for_path(file))
  add_lang(result, M.fixture_dir_lang(file, root))
end

function M.required_parsers()
  local result = {}

  for _, root in ipairs({
    'tests/query/highlights',
    'tests/query/injections',
    'tests/indent',
  }) do
    for _, file in ipairs(vim.fn.globpath(vim.fn.getcwd(), root .. '/**/*.*', true, true)) do
      if not file:match('_spec%.lua$') and not file:match('/common%.lua$') then
        add_fixture_lang(result, file, root)
      end
    end
  end

  for _, file in
    ipairs(vim.fn.globpath(vim.fn.getcwd(), 'tests/query/injections/**/*.*', true, true))
  do
    for _, line in ipairs(vim.fn.readfile(file)) do
      if line:match('^%s*[#/%-;<]') and line:match('%^.*@') then
        for lang in line:gmatch('@!?([%w_]+)') do
          add_lang(result, lang)
        end
      end
    end
  end

  local names = vim.tbl_keys(result)
  table.sort(names)
  return names
end

return M
