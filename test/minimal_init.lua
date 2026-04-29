local root = vim.fn.getcwd()

vim.g.ts_pack_test_root = root

vim.opt.loadplugins = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.shadafile = 'NONE'

vim.opt.runtimepath:prepend(root)

package.path = table.concat({
  root .. '/lua/?.lua',
  root .. '/lua/?/init.lua',
  root .. '/test/?.lua',
  root .. '/test/?/init.lua',
  package.path,
}, ';')
