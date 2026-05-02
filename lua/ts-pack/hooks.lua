local M = {}

function M.apply_filetype(parser)
  local data = parser.data
  if not data or data.filetype == nil then
    return
  end

  vim.validate('spec.data.filetype', data.filetype, { 'string', 'table' })
  if type(data.filetype) == 'table' then
    for index, filetype in ipairs(data.filetype) do
      vim.validate(('spec.data.filetype[%d]'):format(index), filetype, 'string')
    end
  end
  vim.treesitter.language.register(parser.name, data.filetype)
end

function M.apply(parser)
  M.apply_filetype(parser)
end

return M
