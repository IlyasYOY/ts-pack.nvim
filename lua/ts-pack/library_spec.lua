describe('ts-pack.library', function()
  local current_names = {
    'bash',
    'c',
    'clojure',
    'fennel',
    'go',
    'gomod',
    'gosum',
    'groovy',
    'java',
    'javadoc',
    'javascript',
    'kotlin',
    'lua',
    'luadoc',
    'make',
    'proto',
    'python',
    'ruby',
    'rust',
    'scheme',
    'sql',
    'tsx',
    'typescript',
    'vim',
    'vimdoc',
    'css',
    'html',
    'markdown',
    'markdown_inline',
    'xml',
    'asm',
    'typst',
    'dot',
    'toml',
    'yaml',
    'csv',
    'json',
    'json5',
    'diff',
    'disassembly',
    'dockerfile',
    'git_config',
    'git_rebase',
    'gitcommit',
    'gitignore',
    'http',
    'mermaid',
    'printf',
    'query',
    'ssh_config',
  }

  it('exposes the full upstream registry', function()
    local library = require('ts-pack.library')
    local count = 0

    for _ in pairs(library.registry) do
      count = count + 1
    end

    assert.equals(329, count)
  end)

  it('selects deep-copied install specs', function()
    local library = require('ts-pack.library')
    local selected = library.select({ 'bash' })

    assert.equals(1, #selected)
    assert.same({
      name = 'bash',
      src = 'https://github.com/tree-sitter/tree-sitter-bash',
      version = 'a06c2e4415e9bc0346c6b86d401879ffb44058f7',
      data = {
        filetype = {
          'sh',
        },
      },
      bundled_queries = true,
    }, selected[1])

    selected[1].version = 'changed'
    selected[1].data.filetype[1] = 'changed'
    assert.equals('a06c2e4415e9bc0346c6b86d401879ffb44058f7', library.select({ 'bash' })[1].version)
    assert.equals('sh', library.select({ 'bash' })[1].data.filetype[1])
  end)

  it('rejects unknown parser names', function()
    local library = require('ts-pack.library')

    local ok, err = pcall(function()
      library.select({ 'missing' })
    end)

    assert.falsy(ok)
    assert.truthy(err:match('unknown parser `missing`'))
  end)

  it('expands installable dependencies before dependents', function()
    local library = require('ts-pack.library')
    local selected = library.select({ 'tsx' })

    assert.equals('typescript', selected[1].name)
    assert.equals('tsx', selected[2].name)
    assert.same({ 'typescriptreact', 'typescript.tsx' }, selected[2].data.filetype)
    assert.equals(2, #selected)
    assert.falsy(selected[2].requires)
  end)

  it('preserves branch metadata for sql', function()
    local library = require('ts-pack.library')
    local selected = library.select({ 'sql' })

    assert.equals('gh-pages', selected[1].branch)
    assert.equals('851e9cb257ba7c66cc8c14214a31c44d2f1e954e', selected[1].version)
  end)

  it('marks every parser with copied bundled queries', function()
    local library = require('ts-pack.library')
    local selected = library.select({ 'c', 'go', 'lua', 'markdown', 'bash' })
    local marked = {}

    for _, parser in ipairs(selected) do
      marked[parser.name] = parser.bundled_queries
    end

    assert.equals(true, marked.c)
    assert.equals(true, marked.go)
    assert.equals(true, marked.lua)
    assert.equals(true, marked.markdown)
    assert.equals(true, marked.markdown_inline)
    assert.equals(true, marked.bash)
    assert.falsy(selected[1].queries)
  end)

  it('selects the current dotfiles parser set', function()
    local library = require('ts-pack.library')
    local selected = library.select(current_names)
    local seen = {}

    for _, parser in ipairs(selected) do
      assert.truthy(parser.src)
      assert.falsy(parser.requires)
      seen[parser.name] = true
    end

    for _, name in ipairs(current_names) do
      assert.truthy(seen[name])
    end
  end)
end)
