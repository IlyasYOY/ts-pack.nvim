local M = {}

local fs = require('ts-pack.fs')
local path = require('ts-pack.path')
local process = require('ts-pack.process')

local function grammar_source(spec)
  return spec.generate_from_json == false and 'src/grammar.js' or 'src/grammar.json'
end

local function env_or(name, fallback)
  local value = vim.env[name]
  if value and value ~= '' then
    return value
  end
  return fallback
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

local function shared_flag()
  if vim.fn.has('mac') == 1 then
    return '-dynamiclib'
  end
  return '-shared'
end

local function compile_commands(root)
  local cc = env_or('CC', 'cc')
  local cxx = env_or('CXX', 'c++')
  local has_scanner_c = fs.exists(path.join(root, 'src', 'scanner.c'))
  local has_scanner_cc = fs.exists(path.join(root, 'src', 'scanner.cc'))
  local commands = {}
  local objects = {}

  local function add_compile(compiler, source, object)
    commands[#commands + 1] = { compiler, '-fPIC', '-I', 'src', '-c', source, '-o', object }
    objects[#objects + 1] = object
  end

  add_compile(cc, 'src/parser.c', 'parser.o')
  if has_scanner_c then
    add_compile(cc, 'src/scanner.c', 'scanner.o')
  end
  if has_scanner_cc then
    add_compile(cxx, 'src/scanner.cc', 'scanner.cc.o')
  end

  local link = { has_scanner_cc and cxx or cc, '-o', 'parser.so', shared_flag() }
  for _, object in ipairs(objects) do
    link[#link + 1] = object
  end
  commands[#commands + 1] = link

  return commands
end

local function compile_fallback(root, runner)
  for _, command in ipairs(compile_commands(root)) do
    runner(command, { cwd = root })
  end
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

  compile_fallback(root, process.system)
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

  compile_fallback(root, process.async_system)
end

return M
