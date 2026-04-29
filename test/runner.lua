local root = vim.g.ts_pack_test_root or vim.fn.getcwd()
local pattern = root .. '/lua/**/*_spec.lua'
local specs = vim.fn.glob(pattern, false, true)

table.sort(specs)

local ok = require('test.helpers.runner').run(specs)

if ok then
  vim.cmd('quitall')
else
  vim.cmd('cquit')
end
