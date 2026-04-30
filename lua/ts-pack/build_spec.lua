describe('ts-pack.build', function()
  it('generates from grammar json by default and grammar js when requested', function()
    local build = require('ts-pack.build')
    local process = require('ts-pack.process')
    local original_system = process.system
    local calls = {}

    process.system = function(cmd, opts)
      calls[#calls + 1] = { cmd = cmd, opts = opts }
      return { code = 0 }
    end

    build.generate({ generate = true }, '/tmp/parser')
    build.generate({ generate = true, generate_from_json = false }, '/tmp/parser')
    build.generate({ generate = false }, '/tmp/parser')
    process.system = original_system

    assert.equals(2, #calls)
    assert.equals('src/grammar.json', calls[1].cmd[#calls[1].cmd])
    assert.equals('src/grammar.js', calls[2].cmd[#calls[2].cmd])
    assert.equals('/tmp/parser', calls[1].opts.cwd)
    assert.equals('native', calls[1].opts.env.TREE_SITTER_JS_RUNTIME)
  end)
end)
