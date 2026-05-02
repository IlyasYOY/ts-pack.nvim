local M = {}

function M.install_summary_message(names)
  local quoted = {}
  for _, name in ipairs(names) do
    quoted[#quoted + 1] = ('`%s`'):format(name)
  end

  if #quoted == 1 then
    return ('ts-pack installed parser: %s'):format(quoted[1])
  end
  return ('ts-pack installed parsers: %s'):format(table.concat(quoted, ', '))
end

local function echo_install_progress(report, message, status, percent)
  if not report.progress then
    return
  end

  local opts = {
    id = report.progress.id,
    kind = 'progress',
    source = 'ts-pack',
    title = 'Installing parsers',
    status = status,
    percent = percent,
  }
  local ok = pcall(vim.api.nvim_echo, { { message } }, true, opts)
  if not ok then
    report.progress = nil
  end
end

function M.start_install_report(total, opts)
  opts = opts or {}
  local item = {
    installed = {},
    quiet = opts.quiet,
    total = total,
  }

  if opts.quiet then
    return item
  end
  if vim.fn.has('nvim-0.12') ~= 1 then
    return item
  end
  if not vim.api or type(vim.api.nvim_echo) ~= 'function' then
    return item
  end

  local ok, id = pcall(vim.api.nvim_echo, { { 'Installing parsers' } }, true, {
    kind = 'progress',
    source = 'ts-pack',
    title = 'Installing parsers',
    status = 'running',
    percent = total and 0 or nil,
  })
  if ok then
    item.progress = { id = id }
  end

  return item
end

function M.record_installed_parser(item, name)
  item.installed[#item.installed + 1] = name

  if not item.progress then
    return
  end

  local percent
  if item.total and item.total > 0 then
    percent = math.floor((#item.installed / item.total) * 100)
  end
  echo_install_progress(item, ('Installed parser `%s`'):format(name), 'running', percent)
end

function M.finish_install_report(item, failed)
  if not item or #item.installed == 0 then
    if item and item.progress then
      echo_install_progress(item, 'No parsers installed', failed and 'failure' or 'success', 100)
    end
    return
  end

  local message = M.install_summary_message(item.installed)
  echo_install_progress(item, message, failed and 'failure' or 'success', failed and nil or 100)
  if item.quiet then
    return
  end
  vim.notify(message, vim.log.levels.INFO)
end

return M
