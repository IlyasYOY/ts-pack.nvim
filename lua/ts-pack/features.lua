local M = {}

local augroup_name = 'ts-pack-features'
local autocmds_created = false
local registry = {}

local supported = {
  folds = true,
  highlights = true,
  indent = true,
}

local all_features = {
  folds = true,
  highlights = true,
  indent = true,
}

local indentexpr = "v:lua.require'ts-pack.indent'.expr()"
local foldexpr = 'v:lua.vim.treesitter.foldexpr()'

local function normalize_features(parser)
  local data = parser.data
  local value = data and data.features
  if value == nil or value == false then
    return nil
  end

  if value == true then
    return vim.deepcopy(all_features)
  end

  if type(value) ~= 'table' then
    error('`spec.data.features` must be a boolean or a table<string, boolean>', 3)
  end

  local result = {}
  local has_enabled = false
  for key, enabled in pairs(value) do
    if type(key) ~= 'string' or not supported[key] then
      error('`spec.data.features` keys must be one of: folds, highlights, indent', 3)
    end
    if type(enabled) ~= 'boolean' then
      error(('`spec.data.features.%s` must be a boolean'):format(key), 3)
    end
    result[key] = enabled
    has_enabled = has_enabled or enabled
  end

  if not has_enabled then
    return nil
  end
  return result
end

local function buffer_lang(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
    return nil
  end

  local filetype = vim.bo[bufnr].filetype
  if filetype == '' then
    return nil
  end

  local ok, lang = pcall(vim.treesitter.language.get_lang, filetype)
  if not ok or lang == '' then
    return nil
  end
  return lang
end

local function windows_for_buffer(bufnr)
  local ok, windows = pcall(vim.fn.win_findbuf, bufnr)
  if ok then
    return windows
  end

  windows = {}
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == bufnr then
      windows[#windows + 1] = winid
    end
  end
  return windows
end

function M.apply_window(winid, bufnr)
  if not winid or not vim.api.nvim_win_is_valid(winid) then
    return
  end

  bufnr = bufnr or vim.api.nvim_win_get_buf(winid)
  local lang = buffer_lang(bufnr)
  local features = lang and registry[lang]
  if not features or not features.folds then
    return
  end

  vim.wo[winid].foldmethod = 'expr'
  vim.wo[winid].foldexpr = foldexpr
end

local function apply_buffer_windows(bufnr)
  for _, winid in ipairs(windows_for_buffer(bufnr)) do
    M.apply_window(winid, bufnr)
  end
end

function M.apply_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lang = buffer_lang(bufnr)
  local features = lang and registry[lang]
  if not features then
    return
  end

  if features.highlights then
    pcall(vim.treesitter.start, bufnr, lang)
  end

  if features.indent then
    vim.bo[bufnr].indentexpr = indentexpr
  end

  if features.folds then
    apply_buffer_windows(bufnr)
  end
end

function M.apply_loaded_buffers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    M.apply_buffer(bufnr)
  end
end

local function ensure_autocmds()
  if autocmds_created then
    return
  end

  local group = vim.api.nvim_create_augroup(augroup_name, { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    callback = function(ev)
      M.apply_buffer(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = group,
    callback = function(ev)
      M.apply_window(vim.api.nvim_get_current_win(), ev.buf)
    end,
  })
  autocmds_created = true
end

function M.register(parser)
  local features = normalize_features(parser)
  registry[parser.name] = features

  if features then
    ensure_autocmds()
    M.apply_loaded_buffers()
  end
end

function M.unregister(name)
  registry[name] = nil
end

function M._reset()
  registry = {}
  autocmds_created = false
  pcall(vim.api.nvim_del_augroup_by_name, augroup_name)
end

return M
