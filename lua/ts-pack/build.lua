local M = {}

local fs = require('ts-pack.fs')
local path = require('ts-pack.path')
local process = require('ts-pack.process')

local function grammar_source(spec)
  return spec.generate_from_json == false and 'src/grammar.js' or 'src/grammar.json'
end

function M.generate(spec, root)
  if not spec.generate then
    return
  end

  process.system({
    'tree-sitter',
    'generate',
    '--abi',
    tostring(vim.treesitter.language_version),
    grammar_source(spec),
  }, { cwd = root, env = { TREE_SITTER_JS_RUNTIME = 'native' } })
end

function M.generate_async(spec, root)
  if not spec.generate then
    return
  end

  process.async_system({
    'tree-sitter',
    'generate',
    '--abi',
    tostring(vim.treesitter.language_version),
    grammar_source(spec),
  }, { cwd = root, env = { TREE_SITTER_JS_RUNTIME = 'native' } })
end

local function compile_command(root)
  local cmd = { 'cc', '-fPIC', '-I', 'src', '-o', 'parser.so' }
  if vim.fn.has('mac') == 1 then
    cmd[#cmd + 1] = '-dynamiclib'
  else
    cmd[#cmd + 1] = '-shared'
  end

  cmd[#cmd + 1] = 'src/parser.c'
  if fs.exists(path.join(root, 'src', 'scanner.c')) then
    cmd[#cmd + 1] = 'src/scanner.c'
  end
  if fs.exists(path.join(root, 'src', 'scanner.cc')) then
    cmd[#cmd + 1] = 'src/scanner.cc'
  end

  return cmd
end

function M.compile(root)
  local build_cmd = { 'tree-sitter', 'build', '-o', 'parser.so' }
  local result = process.system_result(build_cmd, { cwd = root })
  if result.code == 0 then
    return
  end

  if not fs.exists(path.join(root, 'src', 'parser.c')) then
    error(process.shell_error(build_cmd, root, result), 0)
  end

  process.system(compile_command(root), { cwd = root })
end

function M.compile_async(root)
  local build_cmd = { 'tree-sitter', 'build', '-o', 'parser.so' }
  local result = process.async_system_result(build_cmd, { cwd = root })
  if result.code == 0 then
    return
  end

  if not fs.exists(path.join(root, 'src', 'parser.c')) then
    error(process.shell_error(build_cmd, root, result), 0)
  end

  process.async_system(compile_command(root), { cwd = root })
end

return M
