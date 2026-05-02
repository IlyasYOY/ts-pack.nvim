describe('ts-pack.report', function()
  it('formats install summaries for one or many parsers', function()
    local report = require('ts-pack.report')

    assert.equals('ts-pack installed parser: `lua`', report.install_summary_message({ 'lua' }))
    assert.equals(
      'ts-pack installed parsers: `lua`, `vim`',
      report.install_summary_message({ 'lua', 'vim' })
    )
  end)

  it('notifies exactly once when finishing a report with installed parsers', function()
    local report = require('ts-pack.report')
    local original_notify = vim.notify
    local messages = {}

    vim.notify = function(message, level)
      messages[#messages + 1] = { message = message, level = level }
    end

    local item = { installed = {} }
    report.record_installed_parser(item, 'lua')
    report.record_installed_parser(item, 'vim')
    report.finish_install_report(item)
    vim.notify = original_notify

    assert.equals(1, #messages)
    assert.equals('ts-pack installed parsers: `lua`, `vim`', messages[1].message)
    assert.equals(vim.log.levels.INFO, messages[1].level)
  end)

  it('keeps installed names but suppresses summary notifications in quiet reports', function()
    local report = require('ts-pack.report')
    local original_notify = vim.notify
    local messages = {}

    vim.notify = function(message, level)
      messages[#messages + 1] = { message = message, level = level }
    end

    local item = report.start_install_report(2, { quiet = true })
    report.record_installed_parser(item, 'lua')
    report.record_installed_parser(item, 'vim')
    report.finish_install_report(item)
    vim.notify = original_notify

    assert.equals(2, #item.installed)
    assert.equals(0, #messages)
  end)

  it('does not start native progress for quiet reports', function()
    local report = require('ts-pack.report')
    local original_echo = vim.api.nvim_echo
    local echoes = 0

    vim.api.nvim_echo = function()
      echoes = echoes + 1
      return 42
    end

    local item = report.start_install_report(1, { quiet = true })
    report.record_installed_parser(item, 'lua')
    report.finish_install_report(item)
    vim.api.nvim_echo = original_echo

    assert.equals(0, echoes)
    assert.falsy(item.progress)
  end)

  it('drops progress state if progress echo fails', function()
    local report = require('ts-pack.report')
    local original_echo = vim.api.nvim_echo

    vim.api.nvim_echo = function()
      error('echo failed')
    end

    local item = { installed = {}, progress = { id = 42 } }
    report.record_installed_parser(item, 'lua')
    vim.api.nvim_echo = original_echo

    assert.falsy(item.progress)
  end)
end)
