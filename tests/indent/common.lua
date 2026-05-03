local M = {}

M.XFAIL = 'xfail'
M.SOFT_XFAIL = 'soft_xfail'

local function indent_errors(before, after)
  local ok = true
  local errors = { before = {}, after = {} }
  for line = 1, math.max(#before, #after) do
    local expected = before[line] or ''
    local actual = after[line] or ''
    if #string.match(expected, '^%s*') ~= #string.match(actual, '^%s*') then
      -- store the actual indentation length for each line
      errors.before[line] = #string.match(expected, '^%s*')
      errors.after[line] = #string.match(actual, '^%s*')
      ok = false
    end
  end

  return ok, errors
end

local function format_indent(expected, actual, errors)
  if not expected or not actual then
    return
  end
  -- find minimal width if any line is longer
  local width = 40
  for _, line in ipairs(actual) do
    width = #line > width and #line or width
  end

  width = width + 3
  local header_fmt = '%8s %2s %s %s'
  local fmt = '%8s %2s |%s |%s'

  local output = { header_fmt:format('', '', 'Found:', 'Expected:') }

  for i, line in ipairs(expected) do
    if errors.before[i] then
      local indents = string.format('%d vs %d', errors.after[i], errors.before[i])
      table.insert(output, fmt:format(indents, '=>', actual[i] or '', line))
    else
      table.insert(output, fmt:format('', '', actual[i] or '', line))
    end
  end

  return table.concat(output, '\n')
end

-- Custom assertion better suited for indentation diffs
local function compare_indent(before, after, xfail)
  local ok, errors = indent_errors(before, after)
  if xfail then
    if xfail == M.SOFT_XFAIL then
      return
    end
    assert.falsy(ok, 'Expected known indentation failure to remain failing')
  else
    assert.truthy(ok, 'Incorrect indentation\n' .. format_indent(before, after, errors))
  end
end

local function set_buf_indent_opts(opts)
  local optnames =
    { 'tabstop', 'shiftwidth', 'softtabstop', 'expandtab', 'filetype', 'lispoptions' }
  for _, opt in ipairs(optnames) do
    if opts[opt] ~= nil then
      vim.bo[opt] = opts[opt]
    end
  end
end

function M.run_indent_test(file, runner, opts)
  assert.are.same(1, vim.fn.filereadable(file), string.format('File "%s" not readable', file))

  local helpers = require('test.query_helpers')
  local buf, lang = helpers.lang_for_file(file)
  vim.api.nvim_buf_delete(buf, { force = true })
  if not helpers.parser_path(lang) then
    error(('parser for %s is required for strict indent tests'):format(lang), 2)
  end
  local ok, err = pcall(helpers.load_parser, lang)
  if not ok then
    error(('failed to load parser for %s: %s'):format(lang, err), 2)
  end

  -- load reference file
  vim.cmd.edit(vim.fn.fnameescape(file))
  local before = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  set_buf_indent_opts(opts)
  vim.bo.indentexpr = "v:lua.require'ts-pack.indent'.expr()"
  assert.are.same("v:lua.require'ts-pack.indent'.expr()", vim.bo.indentexpr)

  -- perform the test
  runner()

  -- get file content after the test
  local after = vim.api.nvim_buf_get_lines(0, 0, -1, true)

  -- clear any changes to avoid 'No write since last change (add ! to override)'
  vim.cmd('edit!')

  return before, after
end

function M.indent_whole_file(file, opts, xfail)
  local before, after = M.run_indent_test(file, function()
    vim.cmd('silent normal! gg=G')
  end, opts)

  compare_indent(before, after, xfail)
end

-- Open a file, use `normal o` to insert a new line and compare results
-- @param file path to the initial file
-- @param spec a table with keys:
--   on_line: line on which `normal o` is executed
--   text: text inserted in the new line
--   indent: expected indent before the inserted text (string or int)
-- @param opts buffer options passed to set_buf_indent_opts
function M.indent_new_line(file, spec, opts, xfail)
  local before, after = M.run_indent_test(file, function()
    -- move to the line and input the new one
    vim.cmd(string.format('normal! %dG', spec.on_line))
    vim.cmd(string.format('normal! o%s', spec.text))
  end, opts)

  local indent = type(spec.indent) == 'string' and spec.indent or string.rep(' ', spec.indent)
  table.insert(before, spec.on_line + 1, indent .. spec.text)

  compare_indent(before, after, xfail)

  before, after = M.run_indent_test(file, function()
    -- move to the line and input the new one
    vim.cmd(string.format('normal! %dG$', spec.on_line))
    vim.cmd(
      string.format(vim.api.nvim_replace_termcodes('normal! a<cr>%s', true, true, true), spec.text)
    )
  end, opts)

  indent = type(spec.indent) == 'string' and spec.indent or string.rep(' ', spec.indent)
  table.insert(before, spec.on_line + 1, indent .. spec.text)

  compare_indent(before, after, xfail)
end

local Runner = {}
Runner.__index = Runner

-- Helper to avoid boilerplate when defining tests
-- @param it  the "it" function that busted defines globally in spec files
-- @param base_dir  all other paths will be resolved relative to this directory
-- @param buf_opts  buffer options passed to set_buf_indent_opts
function Runner:new(it, base_dir, buf_opts)
  local runner = {}
  runner.it = it
  runner.base_dir = base_dir
  runner.buf_opts = buf_opts
  runner.files = {}
  runner.xfail_new_line_files = {}
  return setmetatable(runner, self)
end

function Runner:file_case(file)
  local path = (vim.startswith(file, '/') or vim.startswith(file, self.base_dir .. '/'))
      and file
    or vim.fs.joinpath(self.base_dir, file)
  path = vim.fs.normalize(path)
  if not self.files[path] then
    local case = { tasks = {} }
    self.files[path] = case
    self.it(path, function()
      for _, task in ipairs(case.tasks) do
        task()
      end
    end)
  end
  return self.files[path]
end

function Runner:xfail_new_lines(files)
  files = type(files) == 'table' and files or { files }
  for _, file in ipairs(files) do
    local path = vim.fs.normalize(vim.fs.joinpath(self.base_dir, file))
    self.xfail_new_line_files[path] = M.SOFT_XFAIL
  end
end

function Runner:whole_file(dirs, opts)
  opts = opts or {}
  local expected_failures = opts.expected_failures or {}
  expected_failures = vim.tbl_map(function(f)
    return vim.fs.normalize(vim.fs.joinpath(self.base_dir, f))
  end, expected_failures)
  dirs = type(dirs) == 'table' and dirs or { dirs }
  dirs = vim.tbl_map(function(dir)
    dir = vim.fs.normalize(vim.fs.joinpath(self.base_dir, dir))
    assert.is.same(1, vim.fn.isdirectory(dir))
    return dir
  end, dirs)
  local scandir = function(dir)
    return vim.fs.find(function()
      return true
    end, { path = dir, limit = math.huge })
  end
  local files = vim.iter(dirs):map(scandir):flatten()
  for _, file in files:enumerate() do
    local case = self:file_case(file)
    case.tasks[#case.tasks + 1] = function()
      M.indent_whole_file(file, self.buf_opts, vim.tbl_contains(expected_failures, file))
    end
  end
end

function Runner:new_line(file, spec, _title, xfail)
  local path = vim.fs.normalize(vim.fs.joinpath(self.base_dir, file))
  xfail = xfail or self.xfail_new_line_files[path]
  local case = self:file_case(file)
  case.tasks[#case.tasks + 1] = function()
    M.indent_new_line(path, spec, self.buf_opts, xfail)
  end
end

M.Runner = Runner

return M
