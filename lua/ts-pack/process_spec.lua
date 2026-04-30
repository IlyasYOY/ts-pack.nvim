describe('ts-pack.process', function()
  it('formats command failures with cwd and stderr before stdout', function()
    local process = require('ts-pack.process')

    assert.equals(
      'command failed in /tmp/work: git fetch: denied',
      process.shell_error({ 'git', 'fetch' }, '/tmp/work', {
        stderr = 'denied\n',
        stdout = 'ignored\n',
      })
    )

    assert.equals(
      'command failed: git fetch: fallback',
      process.shell_error({ 'git', 'fetch' }, nil, {
        stdout = 'fallback\n',
      })
    )
  end)

  it('raises formatted errors for nonzero system results', function()
    local process = require('ts-pack.process')
    local original_system = vim.system

    vim.system = function()
      return {
        wait = function()
          return { code = 1, stderr = 'failed' }
        end,
      }
    end

    local ok, err = pcall(function()
      process.system({ 'tool', 'run' }, { cwd = '/tmp/project' })
    end)
    vim.system = original_system

    assert.falsy(ok)
    assert.truthy(err:match('command failed in /tmp/project: tool run: failed'))
  end)
end)
