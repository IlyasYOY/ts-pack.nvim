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

local function highlight_assertions_bin()
  local bin = vim.env.HLASSERT
  if bin and bin ~= '' then
    return bin
  end
  return vim.fs.joinpath(vim.fn.getcwd(), '.test-deps', 'highlight-assertions')
end

local function run_highlight_assertions(args)
  local result = vim.system(args, { text = true }):wait()
  if result.code ~= 0 then
    error(
      ('%s failed\n%s'):format(table.concat(args, ' '), result.stderr or result.stdout or ''),
      0
    )
  end

  local ok, decoded = pcall(vim.json.decode, result.stdout)
  if not ok then
    error(('failed to decode highlight assertions output: %s'):format(result.stdout), 0)
  end
  return decoded
end

function M.highlight_assertions(ctx, file, comment_node)
  return run_highlight_assertions({
    highlight_assertions_bin(),
    '-p',
    ctx.parser,
    '-s',
    file,
    '-c',
    comment_node,
  })
end

function M.injection_assertions(ctx, file)
  return run_highlight_assertions({
    highlight_assertions_bin(),
    '-p',
    ctx.parser,
    '-s',
    file,
  })
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
