vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.opt.swapfile = false

vim.filetype.add({
  extension = {
    conf = 'hocon',
    w = 'wing',
  },
})

local base = vim.env.TS_PACK_TEST_HOME or vim.fs.joinpath(vim.fn.getcwd(), '.test-home')
vim.env.XDG_CONFIG_HOME = vim.fs.joinpath(base, 'config')
vim.env.XDG_DATA_HOME = vim.fs.joinpath(base, 'data')
vim.env.XDG_CACHE_HOME = vim.fs.joinpath(base, 'cache')
vim.env.XDG_STATE_HOME = vim.fs.joinpath(base, 'state')

for _, dir in ipairs({
  vim.env.XDG_CONFIG_HOME,
  vim.env.XDG_DATA_HOME,
  vim.env.XDG_CACHE_HOME,
  vim.env.XDG_STATE_HOME,
}) do
  vim.fn.mkdir(dir, 'p')
end
