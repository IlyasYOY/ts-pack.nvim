std = 'luajit'

ignore = {
  '212',
}

globals = {
  'vim',
  'describe',
  'it',
  'before_all',
  'after_all',
  'before_each',
  'after_each',
}

read_globals = {
  assert = {
    fields = {
      'equals',
      'same',
      'truthy',
      'falsy',
      'matches',
      'error_matches',
    },
  },
}

exclude_files = {
  'doc/tags',
}
